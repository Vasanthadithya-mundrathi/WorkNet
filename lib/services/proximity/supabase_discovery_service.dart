import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worknet/core/config/supabase_config.dart';
import 'package:worknet/services/broadcast/broadcast_packet.dart';
import 'package:worknet/services/proximity/proximity_service.dart';

class SupabaseDiscoveryService implements ProximityServiceInterface {
  static const _eventName = 'profile';
  static const _heartbeatInterval = Duration(seconds: 4);
  static const _subscribeTimeout = Duration(seconds: 6);

  final _controller = StreamController<BroadcastPacket>.broadcast();
  RealtimeChannel? _channel;
  Timer? _heartbeat;
  BroadcastPacket? _ownPacket;
  bool _active = false;
  bool _subscribed = false;

  @override
  Stream<BroadcastPacket> get incomingPackets => _controller.stream;

  @override
  bool get isActive => _active && _subscribed;

  @override
  Future<void> startEventMode(BroadcastPacket ownPacket) async {
    if (!WorkNetSupabaseConfig.isConfigured) {
      throw StateError('Supabase discovery is not configured');
    }
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase client is not initialized');
    }
    if (_active) return;

    _active = true;
    _ownPacket = ownPacket;

    final client = Supabase.instance.client;
    final completer = Completer<void>();
    final channelName = 'worknet:${WorkNetSupabaseConfig.channel}';
    final channel = client.channel(
      channelName,
      opts: const RealtimeChannelConfig(ack: true, self: false),
    );
    _channel = channel;

    channel
        .onBroadcast(event: _eventName, callback: _handleBroadcast)
        .subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        _subscribed = true;
        if (!completer.isCompleted) completer.complete();
      } else if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut ||
          status == RealtimeSubscribeStatus.closed) {
        if (!completer.isCompleted) {
          completer.completeError(
            StateError(error?.toString() ?? 'Supabase realtime unavailable'),
          );
        }
      }
    });

    await completer.future.timeout(_subscribeTimeout);
    await _publishOwnPacket();
    _heartbeat = Timer.periodic(
      _heartbeatInterval,
      (_) => _publishOwnPacket(),
    );
  }

  @override
  Future<void> stopEventMode() async {
    _active = false;
    _subscribed = false;
    _ownPacket = null;
    _heartbeat?.cancel();
    _heartbeat = null;

    final channel = _channel;
    _channel = null;
    if (channel != null && Supabase.instance.isInitialized) {
      await Supabase.instance.client.removeChannel(channel);
    }
  }

  @override
  Future<void> relayPacket(BroadcastPacket packet) async {
    if (!_active || !_subscribed) return;
    await _send(packet.withIncrementedHop().refreshedForBroadcast(hopCount: 1));
  }

  @override
  Future<void> dispose() async {
    await stopEventMode();
    await _controller.close();
  }

  void _handleBroadcast(Map<String, dynamic> payload) {
    if (!_active) return;
    final raw = payload['packet'] ?? payload['payload'];
    final packetJson = raw is Map && raw['packet'] is Map
        ? raw['packet'] as Map
        : raw is Map
            ? raw
            : null;
    if (packetJson == null) return;

    try {
      final packet = BroadcastPacket.fromJson(
        Map<String, dynamic>.from(packetJson),
      );
      if (packet.userId == _ownPacket?.userId) return;
      _controller.add(packet);
    } catch (_) {
      // Invalid cloud packets are ignored just like malformed local packets.
    }
  }

  Future<void> _publishOwnPacket() async {
    final packet = _ownPacket;
    if (packet == null || !_active || !_subscribed) return;
    await _send(packet.refreshedForBroadcast());
  }

  Future<void> _send(BroadcastPacket packet) async {
    final channel = _channel;
    if (channel == null) return;
    try {
      await channel.sendBroadcastMessage(
        event: _eventName,
        payload: {
          'packet': packet.toJson(),
          'sentAt': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (_) {
      // Cloud is a fallback transport; local discovery should continue.
    }
  }
}
