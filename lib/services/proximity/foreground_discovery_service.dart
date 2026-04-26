import 'dart:io';

import 'package:flutter/services.dart';

class ForegroundDiscoveryService {
  static const MethodChannel _channel =
      MethodChannel('worknet.discovery/service');

  Future<void> start({int peerCount = 0}) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('start', {'peerCount': peerCount});
    } on PlatformException {
      // Discovery still works in foreground if the native service is unavailable.
    }
  }

  Future<void> stop() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException {
      // Best effort.
    }
  }

  Future<void> updatePeerCount(int peerCount) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('updateNotification', {
        'peerCount': peerCount,
      });
    } on PlatformException {
      // Best effort.
    }
  }
}
