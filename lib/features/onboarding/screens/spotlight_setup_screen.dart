import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/profile_repository.dart';

// ════════════════════════════════════════════════════════════════════
// SpotlightSetupScreen — choose spotlight type + write 140-char note
// ════════════════════════════════════════════════════════════════════

class SpotlightSetupScreen extends ConsumerStatefulWidget {
  const SpotlightSetupScreen({super.key});

  @override
  ConsumerState<SpotlightSetupScreen> createState() =>
      _SpotlightSetupScreenState();
}

class _SpotlightSetupScreenState
    extends ConsumerState<SpotlightSetupScreen> {
  SpotlightType _selected = SpotlightType.exploring;
  final _noteController = TextEditingController();
  bool _loading = false;

  static const int _maxChars = 140;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Color _colorFor(SpotlightType t) => switch (t) {
        SpotlightType.hiring     => AppColors.spotlightHiring,
        SpotlightType.openToWork => AppColors.spotlightOpenToWork,
        SpotlightType.building   => AppColors.spotlightBuilding,
        SpotlightType.learning   => AppColors.spotlightLearning,
        SpotlightType.exploring  => AppColors.spotlightExploring,
      };

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final repo = await ref.read(profileRepositoryProvider.future);
      final profile = await repo.getMyProfile();
      if (profile == null) return;
      profile.spotlightType = _selected;
      profile.spotlightNote = _noteController.text.trim();
      await repo.createOrUpdateProfile(profile);
      await repo.completeOnboarding();
      if (mounted) context.go(AppRoutes.permissions);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = _colorFor(_selected);
    final charsLeft = _maxChars - _noteController.text.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Set Your Spotlight',
            style: AppTypography.headingMedium
                .copyWith(color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your spotlight tells people what you\'re here for.',
                style: AppTypography.bodyLarge
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),

              // Type grid
              ...SpotlightType.values.map((t) {
                final color = _colorFor(t);
                final isSelected = _selected == t;
                return GestureDetector(
                  onTap: () => setState(() => _selected = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.1)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? color.withOpacity(0.6)
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.15),
                                blurRadius: 12,
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        // Spotlight ring preview
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 2.5),
                            color: color.withOpacity(0.08),
                          ),
                          child: Center(
                            child: Text(t.emoji,
                                style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            t.displayLabel,
                            style: AppTypography.labelLarge.copyWith(
                              color: isSelected ? color : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: color, size: 18),
                      ],
                    ),
                  ),
                ).animate().fadeIn(
                    delay:
                        Duration(milliseconds: SpotlightType.values.indexOf(t) * 40),
                    duration: 250.ms);
              }),

              const SizedBox(height: 24),

              // Spotlight note
              Text(
                'Add a note  (optional)',
                style: AppTypography.labelLarge
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  TextField(
                    controller: _noteController,
                    maxLength: _maxChars,
                    maxLines: 3,
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                        null, // hide default counter
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText:
                          'e.g. "Hiring ML interns, stipend ₹12k–15k. DM on LinkedIn"',
                      hintStyle: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textMuted),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: Text(
                      '$charsLeft',
                      style: AppTypography.mono.copyWith(
                        color: charsLeft < 20
                            ? AppColors.warning
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Preview
              _SpotlightPreview(
                type: _selected,
                note: _noteController.text,
                color: selectedColor,
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.background,
                        ),
                      )
                    : const Text('Start Broadcasting'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightPreview extends StatelessWidget {
  final SpotlightType type;
  final String note;
  final Color color;

  const _SpotlightPreview(
      {required this.type, required this.note, required this.color});

  @override
  Widget build(BuildContext context) {
    if (note.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(type.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              note,
              style: AppTypography.bodySmall.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
