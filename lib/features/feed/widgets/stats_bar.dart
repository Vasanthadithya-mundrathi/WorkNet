import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

// ════════════════════════════════════════════════════════════════════
// StatsBar — top of Nearby Feed showing live counts
// ════════════════════════════════════════════════════════════════════

class StatsBar extends StatelessWidget {
  final int total;
  final int hiring;
  final int openToWork;

  const StatsBar({
    super.key,
    required this.total,
    required this.hiring,
    required this.openToWork,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _StatItem(
            value: total.toString(),
            label: 'Nearby',
            color: AppColors.textPrimary,
          ),
          _Divider(),
          _StatItem(
            value: hiring.toString(),
            label: 'Hiring',
            color: AppColors.spotlightHiring,
          ),
          _Divider(),
          _StatItem(
            value: openToWork.toString(),
            label: 'Open to Work',
            color: AppColors.spotlightOpenToWork,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatItem({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.headingMedium.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.border,
    );
  }
}
