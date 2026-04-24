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
// ProfileSetupScreen — sequential one-field-at-a-time onboarding
// Steps: Name → Role → Company → Experience → LinkedIn
// ════════════════════════════════════════════════════════════════════

enum _SetupStep { name, role, company, experience, linkedin }

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  _SetupStep _step = _SetupStep.name;
  final _controllers = {
    _SetupStep.name:     TextEditingController(),
    _SetupStep.role:     TextEditingController(),
    _SetupStep.company:  TextEditingController(),
    _SetupStep.linkedin: TextEditingController(),
  };
  ExperienceLevel _selectedExperience = ExperienceLevel.student;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  String get _stepValueText => switch (_step) {
        _SetupStep.name     => 'What\'s your name?',
        _SetupStep.role     => 'What\'s your current role?',
        _SetupStep.company  => 'Company or college?',
        _SetupStep.experience => 'Years of experience?',
        _SetupStep.linkedin => 'Your LinkedIn handle?',
      };

  String get _stepHint => switch (_step) {
        _SetupStep.name     => 'e.g. Keanu Reyes',
        _SetupStep.role     => 'e.g. ML Engineer, Student, PM',
        _SetupStep.company  => 'e.g. Google, IIT Bombay',
        _SetupStep.experience => '',
        _SetupStep.linkedin => 'e.g. keanu-reyes (handle only)',
      };

  int get _stepIndex => _SetupStep.values.indexOf(_step);
  int get _totalSteps => _SetupStep.values.length;

  Future<void> _next() async {
    if (_step == _SetupStep.linkedin) {
      await _saveAndContinue();
      return;
    }
    setState(() {
      _step = _SetupStep.values[_stepIndex + 1];
    });
  }

  Future<void> _saveAndContinue() async {
    setState(() => _loading = true);
    try {
      final repo = await ref.read(profileRepositoryProvider.future);
      final profile = UserProfile()
        ..name             = _controllers[_SetupStep.name]!.text.trim()
        ..currentRole      = _controllers[_SetupStep.role]!.text.trim()
        ..companyOrCollege = _controllers[_SetupStep.company]!.text.trim()
        ..experienceLabel  = _selectedExperience.label
        ..linkedInHandle   = _controllers[_SetupStep.linkedin]!.text.trim()
        ..userId           = '';
      await repo.createOrUpdateProfile(profile);
      if (mounted) context.go(AppRoutes.spotlightSetup);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _canAdvance => switch (_step) {
        _SetupStep.experience => true,
        _ => (_controllers[_step]?.text.trim().isNotEmpty ?? false),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: _stepIndex > 0
            ? BackButton(
                color: AppColors.textSecondary,
                onPressed: () =>
                    setState(() => _step = _SetupStep.values[_stepIndex - 1]),
              )
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_stepIndex + 1) / _totalSteps,
            backgroundColor: AppColors.border,
            color: AppColors.cyan,
            minHeight: 3,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step ${_stepIndex + 1} of $_totalSteps',
                style:
                    AppTypography.mono.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              Text(
                _stepValueText,
                style: AppTypography.displayMedium
                    .copyWith(color: AppColors.textPrimary),
              )
              .animate(key: ValueKey(_step))
              .fadeIn(duration: 250.ms)
              .slideY(begin: 0.08, end: 0, duration: 250.ms),

              const SizedBox(height: 32),

              // Input area
              _step == _SetupStep.experience
                  ? _ExperiencePicker(
                      value: _selectedExperience,
                      onChanged: (v) =>
                          setState(() => _selectedExperience = v),
                    )
                  : TextField(
                      controller: _controllers[_step],
                      autofocus: true,
                      style: AppTypography.bodyLarge
                          .copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: _stepHint,
                        prefixText: _step == _SetupStep.linkedin
                            ? 'linkedin.com/in/'
                            : null,
                        prefixStyle: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textMuted),
                      ),
                      onChanged: (_) => setState(() {}),
                      textInputAction: _step == _SetupStep.linkedin
                          ? TextInputAction.done
                          : TextInputAction.next,
                      onSubmitted: (_) =>
                          _canAdvance ? _next() : null,
                    ),

              const Spacer(),

              ElevatedButton(
                onPressed: _canAdvance && !_loading ? _next : null,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.background,
                        ),
                      )
                    : Text(_step == _SetupStep.linkedin
                        ? 'Continue to Spotlight'
                        : 'Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Experience Picker ──────────────────────────────────────────────

class _ExperiencePicker extends StatelessWidget {
  final ExperienceLevel value;
  final ValueChanged<ExperienceLevel> onChanged;

  const _ExperiencePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ExperienceLevel.values
          .map((level) => GestureDetector(
                onTap: () => onChanged(level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: value == level
                        ? AppColors.cyanDim
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: value == level
                          ? AppColors.cyan.withOpacity(0.5)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          level.label,
                          style: AppTypography.bodyLarge.copyWith(
                            color: value == level
                                ? AppColors.cyan
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (value == level)
                        const Icon(Icons.check_circle,
                            color: AppColors.cyan, size: 18),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}
