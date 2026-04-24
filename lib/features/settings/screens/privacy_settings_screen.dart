import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worknet/core/router/app_router.dart';
import 'package:worknet/core/theme/app_colors.dart';
import 'package:worknet/core/theme/app_typography.dart';
import 'package:worknet/data/models/user_profile.dart';
import 'package:worknet/data/repositories/profile_repository.dart';
import 'package:worknet/services/permissions/permission_service.dart';

// ════════════════════════════════════════════════════════════════════
// PrivacySettingsScreen — granular data-sharing controls
// ════════════════════════════════════════════════════════════════════

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final permStatus   = ref.watch(permissionStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Privacy & Data',
            style: AppTypography.headingMedium
                .copyWith(color: AppColors.textPrimary)),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('$e')),
        data:    (profile) {
          if (profile == null) return const SizedBox.shrink();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Broadcast Scope ─────────────────────────────────────
              _Section(title: 'What You Broadcast'),

              _InfoCard(
                title: 'Always broadcast (locked)',
                items: const [
                  'Name',
                  'Current Role',
                  'Company / College',
                  'Experience Level',
                  'Spotlight type + note',
                  'LinkedIn handle',
                ],
                iconColor: AppColors.cyan,
                icon: Icons.lock_outline_rounded,
              ),

              const SizedBox(height: 8),

              _InfoCard(
                title: 'Optional — controlled in Profile Editor',
                items: const [
                  'Age',
                  'Gender',
                  'Bio',
                  'Skills',
                ],
                iconColor: AppColors.textSecondary,
                icon: Icons.tune_rounded,
                isOptional: true,
                onTap: () => context.push(AppRoutes.profileEditor),
              ),

              const SizedBox(height: 20),

              // ── Data Residency ──────────────────────────────────────
              _Section(title: 'Data Storage & Residency'),

              _RichInfoCard(
                icon: Icons.storage_outlined,
                iconColor: AppColors.textSecondary,
                title: 'V1 — 100% On-Device',
                body: 'All profile data, discovered peers, and activity logs are '
                    'stored locally on this device only. No server receives '
                    'any data in this version.',
              ),

              const SizedBox(height: 8),

              _RichInfoCard(
                icon: Icons.wifi_off_rounded,
                iconColor: AppColors.textSecondary,
                title: 'Offline-First',
                body: 'WorkNet works without an internet connection. Discovery '
                    'uses Bluetooth and local Wi-Fi P2P only.',
              ),

              const SizedBox(height: 20),

              // ── Bluetooth / Permissions ──────────────────────────────
              _Section(title: 'System Permissions'),

              permStatus.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
                data: (status) {
                  final isOK = status == WorkNetPermissionStatus.granted;
                  return _RichInfoCard(
                    icon: isOK
                        ? Icons.check_circle_outline_rounded
                        : Icons.warning_amber_rounded,
                    iconColor: isOK ? AppColors.success : AppColors.warning,
                    title: isOK
                        ? 'All permissions granted'
                        : 'Some permissions missing',
                    body: isOK
                        ? 'WorkNet has all the access it needs to discover '
                            'nearby professionals.'
                        : 'WorkNet may not be able to discover all nearby users. '
                            'Tap to review permissions.',
                    actionLabel: isOK ? null : 'Open Settings',
                    onAction: isOK
                        ? null
                        : () => ref
                            .read(permissionServiceProvider)
                            .openSettings(),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ── Data Deletion ───────────────────────────────────────
              _Section(title: 'Your Data'),

              _DangerCard(
                title: 'Delete My Profile',
                subtitle:
                    'Removes your profile from this device. You will need to set up WorkNet again.',
                buttonLabel: 'Delete Profile',
                onTap: () => _confirmDelete(context, ref),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Delete Profile?',
            style: AppTypography.headingSmall
                .copyWith(color: AppColors.textPrimary)),
        content: Text(
          'This will permanently remove your WorkNet profile from this device.',
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final repo =
          await ref.read(profileRepositoryProvider.future);
      final profile = await repo.getMyProfile();
      if (profile != null) {
        // Reset the profile — Isar delete
        final isar = await ref.read(isarProvider.future);
        await isar.writeTxn(
            () async => isar.collection<UserProfile>().delete(profile.id));
      }
      if (context.mounted) context.go(AppRoutes.onboarding);
    }
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: AppTypography.headingSmall
                .copyWith(color: AppColors.textSecondary)),
      );
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color iconColor;
  final IconData icon;
  final bool isOptional;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.title,
    required this.items,
    required this.iconColor,
    required this.icon,
    this.isOptional = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(title,
                  style: AppTypography.labelLarge
                      .copyWith(color: AppColors.textPrimary)),
              const Spacer(),
              if (onTap != null)
                const Icon(Icons.chevron_right,
                    size: 16, color: AppColors.textMuted),
            ]),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: items
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOptional
                              ? AppColors.surfaceElevated
                              : AppColors.cyanDim,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: isOptional
                                  ? AppColors.border
                                  : AppColors.cyan.withAlpha(77)),
                        ),
                        child: Text(s,
                            style: AppTypography.labelSmall.copyWith(
                              color: isOptional
                                  ? AppColors.textSecondary
                                  : AppColors.cyan,
                            )),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RichInfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _RichInfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(body,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted)),
                if (actionLabel != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  const _DangerCard({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withAlpha(77)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.error)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: AppColors.error),
            onPressed: onTap,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
