import 'dart:async';
import 'dart:convert';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:worknet/services/proximity/proximity_service.dart';
import 'package:worknet/services/broadcast/broadcast_packet.dart';

// ════════════════════════════════════════════════════════════════════
// NearbyConnectionsService — primary proximity impl
// Wraps flutter_nearby_connections for Android/iOS P2P mesh
// ════════════════════════════════════════════════════════════════════

class NearbyConnectionsService implements ProximityServiceInterface {
  static const String _serviceId = 'worknet';
  
  final NearbyService _nearbyService = NearbyService();

  final _incomingController = StreamController<BroadcastPacket>.broadcast();
  StreamSubscription<dynamic>? _stateSubscription;
  StreamSubscription<dynamic>? _dataSubscription;

  final Map<String, Device> _connectedDevices = {};

  bool _active = false;

  @override
  Stream<BroadcastPacket> get incomingPackets => _incomingController.stream;

  @override
  bool get isActive => _active;

  @override
  Future<void> startEventMode(BroadcastPacket ownPacket) async {
    _active = true;
    final userName = ownPacket.profile.name;
    
    await _nearbyService.init(
      serviceType: _serviceId,
      strategy: Strategy.P2P_CLUSTER,
      deviceName: userName,
      callback: (dynamic isRunningArg) async {
        final isRunning = isRunningArg as bool? ?? false;
        if (isRunning && _active) {
          await _nearbyService.startAdvertisingPeer();
          await _nearbyService.startBrowsingForPeers();
        }
      },
    );

    _stateSubscription = _nearbyService.stateChangedSubscription(
      callback: (devices) {
        for (final device in devices) {
          if (device.state == SessionState.notConnected) {
            // Unconnected peers -> invite them
            _nearbyService.invitePeer(
              deviceID: device.deviceId,
              deviceName: device.deviceName,
            );
          } else if (device.state == SessionState.connected) {
            _connectedDevices[device.deviceId] = device;
          } else {
            // Disconnected
            _connectedDevices.remove(device.deviceId);
          }
        }
      },
    );

    _dataSubscription = _nearbyService.dataReceivedSubscription(
      callback: (data) {
        try {
          // data is dynamic, typically a map with 'deviceId' and 'message' (a JSON string)
          final mapData = data as Map<dynamic, dynamic>;
          final message = mapData['message'] as String;
          final json = jsonDecode(message) as Map<String, dynamic>;
          final packet = BroadcastPacket.fromJson(json);
          _incomingController.add(packet);
        } catch (_) {
          // Malformed packet
        }
      },
    );
  }

  @override
  Future<void> stopEventMode() async {
    _active = false;
    await _stateSubscription?.cancel();
    await _dataSubscription?.cancel();
    _stateSubscription = null;
    _dataSubscription = null;

    // Copy keys first to avoid concurrent modification
    final deviceIds = List<String>.from(_connectedDevices.keys);
    for (final deviceId in deviceIds) {
      try {
        await _nearbyService.disconnectPeer(deviceID: deviceId);
      } catch (_) {}
    }
    _connectedDevices.clear();

    try { await _nearbyService.stopAdvertisingPeer(); } catch (_) {}
    try { await _nearbyService.stopBrowsingForPeers(); } catch (_) {}
  }

  @override
  Future<void> relayPacket(BroadcastPacket packet) async {
    final message = jsonEncode(packet.toJson());
    for (final deviceId in _connectedDevices.keys) {
      try {
        await _nearbyService.sendMessage(deviceId, message);
      } catch (_) {
        // Device may have disconnected
      }
    }
  }

  @override
  Future<void> dispose() async {
    await stopEventMode();
    await _incomingController.close();
  }
}
