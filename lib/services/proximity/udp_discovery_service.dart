import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:worknet/core/constants/worknet_constants.dart';
import 'package:worknet/services/broadcast/broadcast_packet.dart';
import 'package:worknet/services/proximity/proximity_service.dart';

// ════════════════════════════════════════════════════════════════════
// UdpDiscoveryService — same-WiFi-network peer discovery
//
// Mechanism:
//   • Binds a UDP socket to port 41234 (any network interface)
//   • Broadcasts its own BroadcastPacket as JSON every 2 seconds
//     to 255.255.255.255 (limited broadcast) so all LAN peers receive it
//   • Simultaneously receives packets from other WorkNet instances
//     on the same network
//
// Latency: ~50–200 ms (LAN round-trip)
// Range  : entire WiFi venue / hotspot network
// ════════════════════════════════════════════════════════════════════

class UdpDiscoveryService implements ProximityServiceInterface {
  static const int _port = WorkNetConstants.udpPort;

  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  BroadcastPacket? _ownPacket;
  bool _active = false;
  List<InternetAddress> _broadcastAddresses = const [];

  final _controller = StreamController<BroadcastPacket>.broadcast();

  @override
  Stream<BroadcastPacket> get incomingPackets => _controller.stream;

  @override
  bool get isActive => _active;

  @override
  Future<void> startEventMode(BroadcastPacket ownPacket) async {
    if (_active) return;
    _ownPacket = ownPacket;
    _active = true;

    try {
      // Bind on all interfaces so we can receive from any subnet
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _port,
        reuseAddress: true,
        reusePort: false,
      );
      _socket!.broadcastEnabled = true;
      _broadcastAddresses = await _resolveBroadcastAddresses();

      // Listen for incoming packets
      _socket!.listen(_onRawData);

      // Advertise ourselves every broadcastIntervalMs
      _broadcastTimer = Timer.periodic(
        Duration(milliseconds: WorkNetConstants.broadcastIntervalMs),
        (_) => _sendOwnPacket(),
      );

      // Send immediately on start
      _sendOwnPacket();
    } catch (e) {
      // UDP may fail in emulators or restricted networks — fail silently
      _active = false;
    }
  }

  void _sendOwnPacket() {
    final pkt = _ownPacket;
    if (pkt == null || _socket == null || !_active) return;
    try {
      final bytes = pkt.toBytes();
      for (final address in _broadcastAddresses) {
        _socket!.send(bytes, address, _port);
      }
    } catch (_) {}
  }

  void _onRawData(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    try {
      final dg = _socket?.receive();
      if (dg == null) return;

      // Skip our own broadcasts by checking packet's userId
      final jsonStr = utf8.decode(dg.data);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final packet = BroadcastPacket.fromJson(map);

      // Drop our own re-echoed packets
      if (packet.userId == _ownPacket?.userId) return;

      _controller.add(packet);
    } catch (_) {
      // Malformed or non-WorkNet UDP traffic — ignore
    }
  }

  @override
  Future<void> relayPacket(BroadcastPacket packet) async {
    if (!_active || _socket == null) return;
    try {
      final bytes = packet.toBytes();
      for (final address in _broadcastAddresses) {
        _socket!.send(bytes, address, _port);
      }
    } catch (_) {}
  }

  Future<List<InternetAddress>> _resolveBroadcastAddresses() async {
    final addresses = <String>{'255.255.255.255'};
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          final broadcast = _ipv4SubnetBroadcast(address.address);
          if (broadcast != null) addresses.add(broadcast);
        }
      }
    } catch (_) {
      // Keep the universal limited broadcast fallback.
    }
    return addresses.map(InternetAddress.new).toList(growable: false);
  }

  String? _ipv4SubnetBroadcast(String address) {
    final parts = address.split('.');
    if (parts.length != 4) return null;
    final octets = parts.map(int.tryParse).toList();
    if (octets.any((part) => part == null || part < 0 || part > 255)) {
      return null;
    }
    final first = octets[0]!;
    if (first == 10) return '${octets[0]}.${octets[1]}.${octets[2]}.255';
    if (first == 192 && octets[1] == 168) {
      return '${octets[0]}.${octets[1]}.${octets[2]}.255';
    }
    if (first == 172 && octets[1]! >= 16 && octets[1]! <= 31) {
      return '${octets[0]}.${octets[1]}.${octets[2]}.255';
    }
    return null;
  }

  @override
  Future<void> stopEventMode() async {
    _active = false;
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _socket?.close();
    _socket = null;
    _ownPacket = null;
    _broadcastAddresses = const [];
  }

  @override
  Future<void> dispose() async {
    await stopEventMode();
    await _controller.close();
  }
}
