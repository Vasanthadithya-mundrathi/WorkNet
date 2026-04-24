import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

// ════════════════════════════════════════════════════════════════════
// LiveBadge — pulsing LIVE indicator shown in the feed app bar
// ════════════════════════════════════════════════════════════════════

class LiveBadge extends StatelessWidget {
  final bool isActive;

  const LiveBadge({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    if (!isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'PAUSED',
              style: AppTypography.mono.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cyanDim,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyan.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(),
          const SizedBox(width: 5),
          Text(
            'LIVE',
            style: AppTypography.monoBold.copyWith(color: AppColors.cyan),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 8,
      height: 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.cyanDim,
              shape: BoxShape.circle,
            ),
          )
          .animate(onPlay: (c) => c.repeat())
          .scaleXY(begin: 1, end: 2, duration: 900.ms, curve: Curves.easeOut)
          .fadeOut(begin: 0.8, duration: 900.ms),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.cyan,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
