import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worknet/core/router/app_router.dart';
import 'package:worknet/core/theme/app_colors.dart';
import 'package:worknet/core/theme/app_typography.dart';
import 'package:worknet/data/models/user_profile.dart';
import 'package:worknet/data/repositories/profile_repository.dart';
import 'package:worknet/features/profile/screens/peer_profile_view_screen.dart' show launchLinkedIn;
import 'package:worknet/shared/widgets/worknet_avatar.dart';

// ════════════════════════════════════════════════════════════════════
// MyProfileScreen — read-only view of own broadcast profile
// ════════════════════════════════════════════════════════════════════

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Profile',
            style: AppTypography.headingMedium
                .copyWith(color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            color: AppColors.textSecondary,
            tooltip: 'Edit Profile',
            onPressed: () => context.push(AppRoutes.profileEditor),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.cyan)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text('Error loading profile',
                    style: AppTypography.headingSmall
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(e.toString(),
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text('No profile found.',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                WorkNetAvatar(
                  name: profile.name,
                  spotlightType: profile.spotlightType,
                  size: 72,
                  ringThickness: 3,
                ),

                const SizedBox(height: 16),

                Text(profile.name,
                    style: AppTypography.headingLarge
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  '${profile.currentRole} · ${profile.companyOrCollege}',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                Text(
                  profile.experienceLabel,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),

                const SizedBox(height: 24),

                // Spotlight
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cyanDim,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(profile.spotlightType.emoji,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(profile.spotlightType.displayLabel,
                            style: AppTypography.labelLarge
                                .copyWith(color: AppColors.cyan)),
                      ]),
                      if (profile.spotlightNote.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(profile.spotlightNote,
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // LinkedIn — tappable, launches the LinkedIn app/browser
                GestureDetector(
                  onTap: () => launchLinkedIn(context, profile.linkedInHandle),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link,
                            size: 16, color: AppColors.cyan),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            profile.linkedInHandle.isNotEmpty
                                ? 'linkedin.com/in/${profile.linkedInHandle}'
                                : 'No LinkedIn handle set',
                            style: AppTypography.bodySmall.copyWith(
                              color: profile.linkedInHandle.isNotEmpty
                                  ? AppColors.cyan
                                  : AppColors.textMuted,
                              decoration: profile.linkedInHandle.isNotEmpty
                                  ? TextDecoration.underline
                                  : null,
                              decorationColor: AppColors.cyan,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (profile.linkedInHandle.isNotEmpty)
                          const Icon(Icons.open_in_new,
                              size: 14, color: AppColors.cyan),
                      ],
                    ),
                  ),
                ),

                if (profile.showBio &&
                    profile.bio != null &&
                    profile.bio!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'About',
                    child: Text(profile.bio!,
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                ],

                if (profile.showSkills && profile.skills.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Skills',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: profile.skills
                          .map((s) => _SkillChip(label: s))
                          .toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Stealth toggle shortcut
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: profile.stealthMode
                        ? AppColors.error.withOpacity(0.08)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: profile.stealthMode
                          ? AppColors.error.withOpacity(0.3)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        profile.stealthMode
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: profile.stealthMode
                            ? AppColors.error
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          profile.stealthMode
                              ? 'Stealth mode is ON — you are invisible'
                              : 'Stealth mode is off — you are broadcasting',
                          style: AppTypography.bodyMedium.copyWith(
                            color: profile.stealthMode
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: AppTypography.headingSmall
                    .copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );
}

class _SkillChip extends StatelessWidget {
  final String label;
  const _SkillChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label,
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.textSecondary)),
      );
}
