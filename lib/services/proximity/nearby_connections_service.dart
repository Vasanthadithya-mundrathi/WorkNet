import 'dart:async';
import 'dart:convert';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:worknet/core/constants/worknet_constants.dart';
import 'package:worknet/services/proximity/proximity_service.dart';
import 'package:worknet/services/broadcast/broadcast_packet.dart';

// ════════════════════════════════════════════════════════════════════
// NearbyConnectionsService — primary proximity impl
// Wraps flutter_nearby_connections for Android/iOS P2P mesh
// ════════════════════════════════════════════════════════════════════

class NearbyConnectionsService implements ProximityServiceInterface {
  static const String _serviceId = 'worknet';
  static const Duration _inviteThrottle = Duration(seconds: 8);

  final NearbyService _nearbyService = NearbyService();

  final _incomingController = StreamController<BroadcastPacket>.broadcast();
  StreamSubscription<dynamic>? _stateSubscription;
  StreamSubscription<dynamic>? _dataSubscription;
  Timer? _broadcastTimer;

  final Map<String, Device> _connectedDevices = {};
  final Map<String, DateTime> _lastInviteAt = {};
  BroadcastPacket? _ownPacket;

  bool _active = false;

  @override
  Stream<BroadcastPacket> get incomingPackets => _incomingController.stream;

  @override
  bool get isActive => _active;

  @override
  Future<void> startEventMode(BroadcastPacket ownPacket) async {
    if (_active) return;
    _active = true;
    _ownPacket = ownPacket;
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
          if (!_active) return;
          if (device.state == SessionState.notConnected) {
            _inviteIfDue(device);
          } else if (device.state == SessionState.connected) {
            final wasConnected = _connectedDevices.containsKey(device.deviceId);
            _connectedDevices[device.deviceId] = device;
            if (!wasConnected) {
              _sendPacketToDevice(device.deviceId, ownPacket);
            }
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

    _broadcastTimer = Timer.periodic(
      const Duration(milliseconds: WorkNetConstants.broadcastIntervalMs),
      (_) => _sendOwnPacketToConnectedPeers(),
    );
  }

  void _inviteIfDue(Device device) {
    final now = DateTime.now();
    final lastInvite = _lastInviteAt[device.deviceId];
    if (lastInvite != null && now.difference(lastInvite) < _inviteThrottle) {
      return;
    }
    _lastInviteAt[device.deviceId] = now;
    _nearbyService.invitePeer(
      deviceID: device.deviceId,
      deviceName: device.deviceName,
    );
  }

  @override
  Future<void> stopEventMode() async {
    _active = false;
    await _stateSubscription?.cancel();
    await _dataSubscription?.cancel();
    _broadcastTimer?.cancel();
    _stateSubscription = null;
    _dataSubscription = null;
    _broadcastTimer = null;

    // Copy keys first to avoid concurrent modification
    final deviceIds = List<String>.from(_connectedDevices.keys);
    for (final deviceId in deviceIds) {
      try {
        await _nearbyService.disconnectPeer(deviceID: deviceId);
      } catch (_) {}
    }
    _connectedDevices.clear();
    _lastInviteAt.clear();
    _ownPacket = null;

    try {
      await _nearbyService.stopAdvertisingPeer();
    } catch (_) {}
    try {
      await _nearbyService.stopBrowsingForPeers();
    } catch (_) {}
  }

  @override
  Future<void> relayPacket(BroadcastPacket packet) async {
    if (!_active) return;
    for (final deviceId in List<String>.from(_connectedDevices.keys)) {
      await _sendPacketToDevice(deviceId, packet);
    }
  }

  void _sendOwnPacketToConnectedPeers() {
    final packet = _ownPacket;
    if (!_active || packet == null || _connectedDevices.isEmpty) return;
    for (final deviceId in List<String>.from(_connectedDevices.keys)) {
      _sendPacketToDevice(deviceId, packet);
    }
  }

  Future<void> _sendPacketToDevice(
    String deviceId,
    BroadcastPacket packet,
  ) async {
    try {
      final message = utf8.decode(packet.toBytes());
      await _nearbyService.sendMessage(deviceId, message);
    } catch (_) {
      // Device may have disconnected or packet may have exceeded limits.
      _connectedDevices.remove(deviceId);
    }
  }

  @override
  Future<void> dispose() async {
    await stopEventMode();
    await _incomingController.close();
  }
}
