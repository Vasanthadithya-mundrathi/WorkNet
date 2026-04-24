import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worknet/core/router/app_router.dart';
import 'package:worknet/core/theme/app_colors.dart';
import 'package:worknet/core/theme/app_typography.dart';
import 'package:worknet/data/repositories/profile_repository.dart';
import 'package:worknet/features/feed/providers/feed_provider.dart';

// ════════════════════════════════════════════════════════════════════
// SettingsScreen — stealth mode, privacy controls, app info
// ════════════════════════════════════════════════════════════════════

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final feedAsync    = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Settings',
            style: AppTypography.headingMedium
                .copyWith(color: AppColors.textPrimary)),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('$e')),
        data:    (profile) {
          if (profile == null) return const SizedBox.shrink();
          final isStealthActive =
              feedAsync.valueOrNull?.isStealthMode ?? profile.stealthMode;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Privacy Section ─────────────────────────────────────
              _SectionHeader('Privacy & Broadcasting'),

              _SettingCard(
                icon: isStealthActive
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                iconColor:
                    isStealthActive ? AppColors.error : AppColors.cyan,
                title: 'Stealth Mode',
                subtitle: isStealthActive
                    ? 'You are invisible. Tap to resume broadcasting.'
                    : 'You are broadcasting. Tap to go invisible instantly.',
                trailing: Switch(
                  value: isStealthActive,
                  onChanged: (_) =>
                      ref.read(feedProvider.notifier).toggleStealth(),
                  activeColor: AppColors.cyan,
                ),
              ),

              const SizedBox(height: 8),

              _SettingCard(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.textMuted,
                title: 'What is broadcast?',
                subtitle:
                    'Name, Role, Company, Experience, Spotlight, LinkedIn handle always broadcast.\n'
                    'Age, Gender, Bio, Skills are toggleable in your profile editor.',
                trailing: const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // ── Discovery Section ───────────────────────────────────
              _SectionHeader('Discovery'),

              _SettingCard(
                icon: Icons.signal_cellular_alt,
                iconColor: AppColors.textSecondary,
                title: 'Discovery Range',
                subtitle: '10–200m depending on venue density and relay depth',
                trailing: const SizedBox.shrink(),
              ),

              _SettingCard(
                icon: Icons.wifi_tethering_rounded,
                iconColor: AppColors.textSecondary,
                title: 'Mesh Relay Hops',
                subtitle: 'Max 2 hops. Direct → Nearby → In Venue',
                trailing: const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // ── About Section ───────────────────────────────────────
              _SectionHeader('About'),

              _SettingCard(
                icon: Icons.storage_outlined,
                iconColor: AppColors.textMuted,
                title: 'Data Storage',
                subtitle:
                    'V1: All data stays on your device. No server, no cloud.',
                trailing: const SizedBox.shrink(),
              ),

              _SettingCard(
                icon: Icons.privacy_tip_outlined,
                iconColor: AppColors.textSecondary,
                title: 'Privacy & Data',
                subtitle: 'Control what you broadcast and view your data usage.',
                trailing: const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                onTap: () => context.push(AppRoutes.privacySettings),
              ),

              _SettingCard(
                icon: Icons.lock_outline_rounded,
                iconColor: AppColors.textMuted,
                title: 'Privacy Policy',
                subtitle: 'worknetapp.com/privacy',
                trailing: const Icon(Icons.open_in_new,
                    size: 16, color: AppColors.textMuted),
                onTap: () {},
              ),

              const SizedBox(height: 8),
              Center(
                child: Text(
                  'WorkNet v1.0.0 · Built for events, not social media.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: AppTypography.headingSmall
                .copyWith(color: AppColors.textSecondary)),
      );
}

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
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
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      );
}
