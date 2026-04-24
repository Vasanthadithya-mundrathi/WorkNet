import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worknet/core/router/app_router.dart';
import 'package:worknet/core/theme/app_colors.dart';
import 'package:worknet/core/theme/app_typography.dart';
import 'package:worknet/services/permissions/permission_service.dart';

// ════════════════════════════════════════════════════════════════════
// PermissionScreen — Shown when permissions not yet granted
// Fixed: SingleChildScrollView prevents overflow on small screens
// ════════════════════════════════════════════════════════════════════

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  bool _requesting = false;
  bool _agreedToPolicy = false;

  Future<void> _request() async {
    setState(() => _requesting = true);
    final svc = ref.read(permissionServiceProvider);
    final status = await svc.requestAll();
    if (!mounted) return;
    setState(() => _requesting = false);

    if (status == WorkNetPermissionStatus.granted) {
      context.go(AppRoutes.feed);
    } else if (status == WorkNetPermissionStatus.permanentlyDenied ||
        status == WorkNetPermissionStatus.restricted) {
      _showSettingsDialog();
    }
  }

  void _showSettingsDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Permissions Required',
            style: AppTypography.headingSmall
                .copyWith(color: AppColors.textPrimary)),
        content: Text(
          'WorkNet needs Bluetooth and Local Network access to discover '
          'nearby professionals. Please enable them in Settings.',
          style:
              AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final svc = ref.read(permissionServiceProvider);
              await svc.openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder so spacing is proportional to screen height
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            // Scale spacing based on available height
            final topGap    = h * 0.04;
            final midGap    = h * 0.03;
            final smallGap  = h * 0.02;

            return SingleChildScrollView(
              // Allow scrolling if content still overflows on tiny screens
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: h),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: topGap),

                      // ── Icon ──────────────────────────────────────
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.cyan.withAlpha(25),
                          border: Border.all(
                              color: AppColors.cyan.withAlpha(77), width: 2),
                        ),
                        child: const Icon(
                          Icons.wifi_tethering_rounded,
                          color: AppColors.cyan,
                          size: 44,
                        ),
                      )
                          .animate(
                            onPlay: (ctrl) => ctrl.repeat(reverse: true),
                          )
                          .scaleXY(
                            begin: 1.0,
                            end: 1.07,
                            duration: 1800.ms,
                            curve: Curves.easeInOut,
                          ),

                      SizedBox(height: midGap),

                      // ── Heading ──────────────────────────────────
                      Text(
                        'One-time Setup',
                        style: AppTypography.displayMedium
                            .copyWith(color: AppColors.textPrimary),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.1, end: 0),

                      SizedBox(height: smallGap),

                      Text(
                        'WorkNet needs Bluetooth, WiFi and Location '
                        'access to broadcast your profile and discover '
                        'nearby professionals.',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                      SizedBox(height: smallGap * 0.6),

                      Text(
                        'Your data never leaves the venue — no internet required.',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

                      SizedBox(height: midGap),

                      // ── Permission rows ───────────────────────────
                      ..._permItems
                          .map((item) => _PermRow(item: item))
                          .toList()
                          .animate(interval: 80.ms)
                          .fadeIn(duration: 250.ms)
                          .slideX(begin: -0.06, end: 0),

                      SizedBox(height: midGap),

                      // ── Policy Agreement ──────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _agreedToPolicy,
                              onChanged: (val) =>
                                  setState(() => _agreedToPolicy = val ?? false),
                              activeColor: AppColors.cyan,
                              side:
                                  const BorderSide(color: AppColors.textSecondary),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => _agreedToPolicy = !_agreedToPolicy),
                              child: Text(
                                'I agree to the WorkNet Privacy Policy and '
                                'Terms of Service. I understand that my '
                                'profile data is broadcast locally to nearby '
                                'devices only.',
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 300.ms),

                      SizedBox(height: midGap),

                      // ── Grant Access button ───────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              (_requesting || !_agreedToPolicy) ? null : _request,
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _requesting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.background,
                                  ),
                                )
                              : const Text('Grant Access'),
                        ),
                      ),

                      SizedBox(height: smallGap),

                      Text(
                        'You can revoke access at any time in Settings.',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: smallGap),

                      // ── Developer Credits ─────────────────────────
                      Text(
                        'Developed by\n'
                        'Vasanthadithya (160123749049) & '
                        'Sai Geethika (160123749302)',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.textMuted.withAlpha(150)),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 500.ms),

                      SizedBox(height: topGap),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Permission item model ──────────────────────────────────────────

class _PermItem {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  const _PermItem({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });
}

const _permItems = [
  _PermItem(
    icon: Icons.bluetooth_rounded,
    title: 'Bluetooth',
    desc: 'Discover nearby devices',
    color: AppColors.cyan,
  ),
  _PermItem(
    icon: Icons.wifi_rounded,
    title: 'WiFi Network',
    desc: 'Same-network LAN discovery',
    color: AppColors.spotlightBuilding,
  ),
  _PermItem(
    icon: Icons.location_on_outlined,
    title: 'Location',
    desc: 'Required by Android BLE API',
    color: AppColors.spotlightOpenToWork,
  ),
  _PermItem(
    icon: Icons.wifi_tethering_rounded,
    title: 'Nearby Devices',
    desc: 'WiFi Direct P2P mesh',
    color: AppColors.spotlightHiring,
  ),
];

// ── Permission row widget ──────────────────────────────────────────

class _PermRow extends StatelessWidget {
  final _PermItem item;
  const _PermRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.color.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.textPrimary)),
                Text(item.desc,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_outline,
              color: AppColors.textMuted, size: 16),
        ],
      ),
    );
  }
}
