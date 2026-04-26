import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

// ════════════════════════════════════════════════════════════════════
// PermissionStatus summary
// ════════════════════════════════════════════════════════════════════

enum WorkNetPermissionStatus {
  granted, // All required permissions OK → ready to scan
  denied, // At least one denied (can retry)
  permanentlyDenied, // User said "Never Ask Again" → open settings
  restricted, // System-level restriction (parental controls, MDM)
}

// ════════════════════════════════════════════════════════════════════
// PermissionService
// ════════════════════════════════════════════════════════════════════

class PermissionService {
  // Returns the set of permissions required for discovery on this platform/SDK.
  Future<List<Permission>> _getDiscoveryRequired() async {
    if (Platform.isIOS) {
      return [
        Permission.bluetooth,
      ];
    }

    // Android — version-adaptive
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      // Android 13+ — ask every runtime bucket that can affect discovery.
      // Gallery picking uses the system photo picker and does not need media
      // or storage permission.
      return [
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.nearbyWifiDevices,
        Permission.locationWhenInUse,
      ];
    } else if (sdkInt >= 31) {
      // Android 12 / 12L. Location remains here for plugin compatibility.
      return [
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ];
    } else {
      // Android 11 and below
      return [
        Permission.bluetooth,
        Permission.locationWhenInUse,
      ];
    }
  }

  /// Request all required permissions and return the aggregate status.
  Future<WorkNetPermissionStatus> requestAll() async {
    return requestDiscovery();
  }

  /// Request permissions needed to discover nearby peers.
  Future<WorkNetPermissionStatus> requestDiscovery() async {
    final requiredPerms = await _getDiscoveryRequired();
    final Map<Permission, PermissionStatus> results = {};
    for (final permission in requiredPerms) {
      results[permission] = await permission.request();
    }
    return _aggregate(results);
  }

  /// Check current status without prompting.
  Future<WorkNetPermissionStatus> checkAll() async {
    return checkDiscovery();
  }

  /// Check discovery permissions without prompting.
  Future<WorkNetPermissionStatus> checkDiscovery() async {
    final requiredPerms = await _getDiscoveryRequired();
    final Map<Permission, PermissionStatus> results = {};
    for (final p in requiredPerms) {
      results[p] = await p.status;
    }
    return _aggregate(results);
  }

  Future<WorkNetPermissionStatus> requestCamera() async {
    return _aggregate({Permission.camera: await Permission.camera.request()});
  }

  Future<WorkNetPermissionStatus> requestNotification() async {
    if (!Platform.isAndroid) return WorkNetPermissionStatus.granted;
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt < 33) return WorkNetPermissionStatus.granted;
    return _aggregate({
      Permission.notification: await Permission.notification.request(),
    });
  }

  Future<WorkNetPermissionStatus> checkNotification() async {
    if (!Platform.isAndroid) return WorkNetPermissionStatus.granted;
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt < 33) return WorkNetPermissionStatus.granted;
    return _aggregate({
      Permission.notification: await Permission.notification.status,
    });
  }

  /// Open the app settings page so the user can grant denied permissions.
  Future<bool> openSettings() => openAppSettings();

  // ── Private ────────────────────────────────────────────────────

  WorkNetPermissionStatus _aggregate(
      Map<Permission, PermissionStatus> results) {
    if (results.values.any((s) => s == PermissionStatus.permanentlyDenied)) {
      return WorkNetPermissionStatus.permanentlyDenied;
    }
    if (results.values.any((s) => s == PermissionStatus.restricted)) {
      return WorkNetPermissionStatus.restricted;
    }
    // Treat limited as OK for scanning purposes
    if (results.values.every((s) =>
        s == PermissionStatus.granted || s == PermissionStatus.limited)) {
      return WorkNetPermissionStatus.granted;
    }
    return WorkNetPermissionStatus.denied;
  }
}

// ════════════════════════════════════════════════════════════════════
// Riverpod Provider
// ════════════════════════════════════════════════════════════════════

final permissionServiceProvider = Provider<PermissionService>(
  (_) => PermissionService(),
);

final permissionStatusProvider =
    FutureProvider<WorkNetPermissionStatus>((ref) async {
  final svc = ref.read(permissionServiceProvider);
  return svc.checkAll();
});
