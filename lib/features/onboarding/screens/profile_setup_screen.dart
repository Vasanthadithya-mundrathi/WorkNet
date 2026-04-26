import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../services/permissions/permission_service.dart';
import '../../../services/profile/avatar_service.dart';
import '../../../shared/widgets/worknet_avatar.dart';

// ════════════════════════════════════════════════════════════════════
// ProfileSetupScreen — sequential one-field-at-a-time onboarding
// Steps: Name → Role → Company → Experience → LinkedIn
// ════════════════════════════════════════════════════════════════════

enum _SetupStep { name, role, company, experience, linkedin, avatar }

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  _SetupStep _step = _SetupStep.name;
  final _controllers = {
    _SetupStep.name: TextEditingController(),
    _SetupStep.role: TextEditingController(),
    _SetupStep.company: TextEditingController(),
    _SetupStep.linkedin: TextEditingController(),
  };
  ExperienceLevel _selectedExperience = ExperienceLevel.student;
  AvatarResult? _avatar;
  bool _shareAvatar = false;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  String get _stepValueText => switch (_step) {
        _SetupStep.name => 'What\'s your name?',
        _SetupStep.role => 'What\'s your current role?',
        _SetupStep.company => 'Company or college?',
        _SetupStep.experience => 'Years of experience?',
        _SetupStep.linkedin => 'Your LinkedIn handle?',
        _SetupStep.avatar => 'Add a profile photo?',
      };

  String get _stepHint => switch (_step) {
        _SetupStep.name => 'e.g. Keanu Reyes',
        _SetupStep.role => 'e.g. ML Engineer, Student, PM',
        _SetupStep.company => 'e.g. Google, IIT Bombay',
        _SetupStep.experience => '',
        _SetupStep.linkedin => 'e.g. keanu-reyes (handle only)',
        _SetupStep.avatar => '',
      };

  int get _stepIndex => _SetupStep.values.indexOf(_step);
  int get _totalSteps => _SetupStep.values.length;

  Future<void> _next() async {
    if (_step == _SetupStep.avatar) {
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
        ..name = _controllers[_SetupStep.name]!.text.trim()
        ..currentRole = _controllers[_SetupStep.role]!.text.trim()
        ..companyOrCollege = _controllers[_SetupStep.company]!.text.trim()
        ..experienceLabel = _selectedExperience.label
        ..linkedInHandle = _controllers[_SetupStep.linkedin]!.text.trim()
        ..avatarLocalPath = _avatar?.localPath
        ..avatarThumbBase64 = _avatar?.thumbBase64
        ..avatarHash = _avatar?.hash
        ..avatarUpdatedAt = _avatar == null ? null : DateTime.now()
        ..shareAvatar = _avatar != null && _shareAvatar
        ..userId = '';
      await repo.createOrUpdateProfile(profile);
      if (mounted) context.go(AppRoutes.spotlightSetup);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _canAdvance => switch (_step) {
        _SetupStep.experience => true,
        _SetupStep.avatar => true,
        _ => (_controllers[_step]?.text.trim().isNotEmpty ?? false),
      };

  Future<void> _pickAvatar() async {
    final result = await ref.read(avatarServiceProvider).pickFromGallery();
    if (result == null || !mounted) return;
    setState(() => _avatar = result);
  }

  Future<void> _captureAvatar() async {
    final status = await ref.read(permissionServiceProvider).requestCamera();
    if (status != WorkNetPermissionStatus.granted) return;
    final result = await ref.read(avatarServiceProvider).captureWithCamera();
    if (result == null || !mounted) return;
    setState(() => _avatar = result);
  }

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
                style: AppTypography.mono.copyWith(color: AppColors.textMuted),
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
              if (_step == _SetupStep.experience)
                _ExperiencePicker(
                  value: _selectedExperience,
                  onChanged: (v) => setState(() => _selectedExperience = v),
                )
              else if (_step == _SetupStep.avatar)
                _AvatarSetup(
                  name: _controllers[_SetupStep.name]!.text.trim(),
                  avatarPath: _avatar?.localPath,
                  shareAvatar: _shareAvatar,
                  onPick: _pickAvatar,
                  onCamera: _captureAvatar,
                  onRemove: () => setState(() {
                    _avatar = null;
                    _shareAvatar = false;
                  }),
                  onShareChanged: _avatar == null
                      ? null
                      : (value) => setState(() => _shareAvatar = value),
                )
              else
                TextField(
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
                  onSubmitted: (_) => _canAdvance ? _next() : null,
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
                    : Text(_step == _SetupStep.avatar
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color:
                        value == level ? AppColors.cyanDim : AppColors.surface,
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

class _AvatarSetup extends StatelessWidget {
  final String name;
  final String? avatarPath;
  final bool shareAvatar;
  final VoidCallback onPick;
  final VoidCallback onCamera;
  final VoidCallback onRemove;
  final ValueChanged<bool>? onShareChanged;

  const _AvatarSetup({
    required this.name,
    required this.avatarPath,
    required this.shareAvatar,
    required this.onPick,
    required this.onCamera,
    required this.onRemove,
    required this.onShareChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = avatarPath != null && avatarPath!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: WorkNetAvatar(
            name: name.isEmpty ? 'WorkNet User' : name,
            spotlightType: SpotlightType.exploring,
            imagePath: avatarPath,
            size: 96,
            ringThickness: 3,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Camera'),
              ),
            ),
          ],
        ),
        if (hasPhoto) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            label: const Text('Remove photo'),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.privacy_tip_outlined,
                  color: AppColors.cyan, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Share this photo with nearby people',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
              Switch(
                value: shareAvatar,
                onChanged: onShareChanged,
                activeColor: AppColors.cyan,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sharing is optional. If it is off, nearby people see your initials.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
