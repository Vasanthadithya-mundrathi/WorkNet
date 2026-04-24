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
      final bytes = utf8.encode(jsonEncode(pkt.toJson()));
      if (bytes.length > WorkNetConstants.maxPayloadBytes) return;
      _socket!.send(
        bytes,
        InternetAddress('255.255.255.255'),
        _port,
      );
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
      final bytes = utf8.encode(jsonEncode(packet.toJson()));
      if (bytes.length <= WorkNetConstants.maxPayloadBytes) {
        _socket!.send(bytes, InternetAddress('255.255.255.255'), _port);
      }
    } catch (_) {}
  }

  @override
  Future<void> stopEventMode() async {
    _active = false;
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _socket?.close();
    _socket = null;
    _ownPacket = null;
  }

  @override
  Future<void> dispose() async {
    await stopEventMode();
    await _controller.close();
  }
}
