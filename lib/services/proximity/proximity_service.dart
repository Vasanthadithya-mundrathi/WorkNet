import 'dart:async';
import '../broadcast/broadcast_packet.dart';

// ════════════════════════════════════════════════════════════════════
// ProximityServiceInterface — abstraction over the BLE/WiFi transport
// Concrete impls: NearbyConnectionsService, BleDirectService
// ════════════════════════════════════════════════════════════════════

abstract class ProximityServiceInterface {
  /// All incoming raw BroadcastPackets (before gossip relay processing)
  Stream<BroadcastPacket> get incomingPackets;

  /// Start advertising local profile + scanning for peers
  Future<void> startEventMode(BroadcastPacket ownPacket);

  /// Stop all advertising and scanning (Stealth Mode)
  Future<void> stopEventMode();

  /// Relay a packet to all connected peers (for gossip relay)
  Future<void> relayPacket(BroadcastPacket packet);

  /// Whether the service is currently in event mode
  bool get isActive;

  /// Dispose resources
  Future<void> dispose();
}
