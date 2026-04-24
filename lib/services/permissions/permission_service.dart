import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

// ════════════════════════════════════════════════════════════════════
// PermissionStatus summary
// ════════════════════════════════════════════════════════════════════

enum WorkNetPermissionStatus {
  granted,      // All required permissions OK → ready to scan
  denied,       // At least one denied (can retry)
  permanentlyDenied, // User said "Never Ask Again" → open settings
  restricted,   // System-level restriction (parental controls, MDM)
}

// ════════════════════════════════════════════════════════════════════
// PermissionService
// ════════════════════════════════════════════════════════════════════

class PermissionService {
  // Returns the set of permissions required for the current platform/SDK
  Future<List<Permission>> _getRequired() async {
    if (Platform.isIOS) {
      return [
        Permission.bluetooth,
        Permission.bluetoothAdvertise,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ];
    }

    // Android — version-adaptive
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      // Android 13+ — all modern permissions
      return [
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.nearbyWifiDevices,
        Permission.locationWhenInUse, // still needed for BLE scan result filtering
        Permission.notification,      // foreground service notification
      ];
    } else if (sdkInt >= 31) {
      // Android 12
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
    final requiredPerms = await _getRequired();
    final results = await requiredPerms.request();
    return _aggregate(results);
  }

  /// Check current status without prompting.
  Future<WorkNetPermissionStatus> checkAll() async {
    final requiredPerms = await _getRequired();
    final Map<Permission, PermissionStatus> results = {};
    for (final p in requiredPerms) {
      results[p] = await p.status;
    }
    return _aggregate(results);
  }

  /// Open the app settings page so the user can grant denied permissions.
  Future<bool> openSettings() => openAppSettings();

  // ── Private ────────────────────────────────────────────────────

  WorkNetPermissionStatus _aggregate(
      Map<Permission, PermissionStatus> results) {
    if (results.values
        .any((s) => s == PermissionStatus.permanentlyDenied)) {
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
