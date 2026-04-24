import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_profile.dart';

// ════════════════════════════════════════════════════════════════════
// WorkNetAvatar — circular avatar with Spotlight colour ring
// ════════════════════════════════════════════════════════════════════

class WorkNetAvatar extends StatelessWidget {
  final String name;
  final SpotlightType spotlightType;
  final String? imageUrl;
  final double size;
  final double ringThickness;

  const WorkNetAvatar({
    super.key,
    required this.name,
    required this.spotlightType,
    this.imageUrl,
    this.size = 52,
    this.ringThickness = 2.5,
  });

  Color get _ringColor => switch (spotlightType) {
        SpotlightType.hiring     => AppColors.spotlightHiring,
        SpotlightType.openToWork => AppColors.spotlightOpenToWork,
        SpotlightType.building   => AppColors.spotlightBuilding,
        SpotlightType.learning   => AppColors.spotlightLearning,
        SpotlightType.exploring  => AppColors.spotlightExploring,
      };

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + ringThickness * 2 + 4,
      height: size + ringThickness * 2 + 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _ringColor,
          width: ringThickness,
        ),
        boxShadow: [
          BoxShadow(
            color: _ringColor.withOpacity(0.35),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: CircleAvatar(
          radius: size / 2,
          backgroundColor: AppColors.surfaceElevated,
          backgroundImage:
              imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? Text(
                  _initials,
                  style: TextStyle(
                    fontSize: size * 0.32,
                    fontWeight: FontWeight.w700,
                    color: _ringColor,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
