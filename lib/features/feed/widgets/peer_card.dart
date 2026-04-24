import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:worknet/core/theme/app_colors.dart';
import 'package:worknet/core/theme/app_typography.dart';
import 'package:worknet/data/models/nearby_peer.dart';
import 'package:worknet/data/models/user_profile.dart';
import 'package:worknet/shared/widgets/worknet_avatar.dart';

// ════════════════════════════════════════════════════════════════════
// PeerCard — the primary card in the Nearby Feed
// ════════════════════════════════════════════════════════════════════

class PeerCard extends StatelessWidget {
  final NearbyPeer peer;
  final VoidCallback onTap;
  final int animationIndex;

  const PeerCard({
    super.key,
    required this.peer,
    required this.onTap,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final p = peer.profile;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card Header ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WorkNetAvatar(
                    name: p.name,
                    spotlightType: p.spotlightType,
                    size: 48,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                p.name,
                                style: AppTypography.headingSmall
                                    .copyWith(color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _HopBadge(hopCount: peer.hopCount),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.currentRole,
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${p.companyOrCollege} · ${p.experienceLabel}',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Spotlight Banner ─────────────────────────────────────
            if (p.spotlightNote.isNotEmpty)
              _SpotlightBanner(
                type: p.spotlightType,
                note: p.spotlightNote,
              ),

            // ── Skills ───────────────────────────────────────────────
            if (p.skills != null && p.skills!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: p.skills!
                      .take(3)
                      .map((s) => _SkillChip(label: s))
                      .toList(),
                ),
              ),

            const SizedBox(height: 14),
          ],
        ),
      )
      .animate()
      .fadeIn(
        delay: Duration(milliseconds: animationIndex * 40),
        duration: 300.ms,
      )
      .slideY(
        begin: 0.08,
        end: 0,
        delay: Duration(milliseconds: animationIndex * 40),
        duration: 300.ms,
        curve: Curves.easeOut,
      ),
    );
  }
}

// ── Hop Badge ──────────────────────────────────────────────────────

class _HopBadge extends StatelessWidget {
  final int hopCount;
  const _HopBadge({required this.hopCount});

  Color get _color => switch (hopCount) {
        0 => AppColors.hopDirect,
        1 => AppColors.hopNearby,
        _ => AppColors.hopInVenue,
      };

  String get _label => switch (hopCount) {
        0 => 'Direct',
        1 => 'Nearby',
        _ => 'In Venue',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(
        _label,
        style: AppTypography.mono.copyWith(color: _color),
      ),
    );
  }
}

// ── Spotlight Banner ───────────────────────────────────────────────

class _SpotlightBanner extends StatelessWidget {
  final SpotlightType type;
  final String note;
  const _SpotlightBanner({required this.type, required this.note});

  Color get _color => switch (type) {
        SpotlightType.hiring     => AppColors.spotlightHiring,
        SpotlightType.openToWork => AppColors.spotlightOpenToWork,
        SpotlightType.building   => AppColors.spotlightBuilding,
        SpotlightType.learning   => AppColors.spotlightLearning,
        SpotlightType.exploring  => AppColors.spotlightExploring,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(type.emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              note,
              style: AppTypography.bodySmall.copyWith(color: _color),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skill Chip ─────────────────────────────────────────────────────

class _SkillChip extends StatelessWidget {
  final String label;
  const _SkillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
