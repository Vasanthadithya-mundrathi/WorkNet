import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worknet/core/theme/app_colors.dart';
import 'package:worknet/core/theme/app_typography.dart';
import 'package:worknet/data/models/user_profile.dart';
import 'package:worknet/data/repositories/profile_repository.dart';

// ════════════════════════════════════════════════════════════════════
// ProfileEditorScreen — edit fields + custom sections + custom links
// ════════════════════════════════════════════════════════════════════

class ProfileEditorScreen extends ConsumerStatefulWidget {
  const ProfileEditorScreen({super.key});

  @override
  ConsumerState<ProfileEditorScreen> createState() =>
      _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends ConsumerState<ProfileEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loaded = false;
  bool _saving = false;

  // Core controllers
  final _nameCtrl     = TextEditingController();
  final _roleCtrl     = TextEditingController();
  final _companyCtrl  = TextEditingController();
  final _linkedInCtrl = TextEditingController();
  final _bioCtrl      = TextEditingController();
  final _skillsCtrl   = TextEditingController();

  ExperienceLevel _experience = ExperienceLevel.student;
  bool _showAge    = false;
  bool _showGender = false;
  bool _showBio    = true;
  bool _showSkills = true;
  bool _showLinks  = true;

  // Custom sections & links (local mutable lists)
  final List<_SectionEntry> _sections = [];
  final List<_LinkEntry>    _links    = [];

  late UserProfile _profile;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _roleCtrl, _companyCtrl,
        _linkedInCtrl, _bioCtrl, _skillsCtrl]) {
      c.dispose();
    }
    for (final s in _sections) { s.headingCtrl.dispose(); s.contentCtrl.dispose(); }
    for (final l in _links)    { l.labelCtrl.dispose();   l.urlCtrl.dispose(); }
    super.dispose();
  }

  void _populateFrom(UserProfile profile) {
    _nameCtrl.text     = profile.name;
    _roleCtrl.text     = profile.currentRole;
    _companyCtrl.text  = profile.companyOrCollege;
    _linkedInCtrl.text = profile.linkedInHandle;
    _bioCtrl.text      = profile.bio ?? '';
    _skillsCtrl.text   = profile.skills.join(', ');
    _experience = ExperienceLevel.values.firstWhere(
      (e) => e.label == profile.experienceLabel,
      orElse: () => ExperienceLevel.student,
    );
    _showAge    = profile.showAge;
    _showGender = profile.showGender;
    _showBio    = profile.showBio;
    _showSkills = profile.showSkills;
    _showLinks  = profile.showLinks;
    _profile    = profile;

    _sections
      ..clear()
      ..addAll(profile.customSections.map((s) => _SectionEntry(
            headingCtrl: TextEditingController(text: s.heading),
            contentCtrl: TextEditingController(text: s.content),
            isVisible:   s.isVisible,
          )));
    _links
      ..clear()
      ..addAll(profile.links.map((l) => _LinkEntry(
            labelCtrl: TextEditingController(text: l.label),
            urlCtrl:   TextEditingController(text: l.url),
          )));
    _loaded = true;
  }

  void _addSection() {
    setState(() => _sections.add(_SectionEntry(
          headingCtrl: TextEditingController(),
          contentCtrl: TextEditingController(),
          isVisible:   true,
        )));
  }

  void _removeSection(int index) {
    final s = _sections.removeAt(index);
    s.headingCtrl.dispose();
    s.contentCtrl.dispose();
    setState(() {});
  }

  void _addLink() {
    setState(() => _links.add(_LinkEntry(
          labelCtrl: TextEditingController(),
          urlCtrl:   TextEditingController(),
        )));
  }

  void _removeLink(int index) {
    final l = _links.removeAt(index);
    l.labelCtrl.dispose();
    l.urlCtrl.dispose();
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = await ref.read(profileRepositoryProvider.future);
      _profile
        ..name             = _nameCtrl.text.trim()
        ..currentRole      = _roleCtrl.text.trim()
        ..companyOrCollege = _companyCtrl.text.trim()
        ..linkedInHandle   = _linkedInCtrl.text.trim()
        ..bio              = _bioCtrl.text.trim()
        ..skills           = _skillsCtrl.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList()
        ..experienceLabel  = _experience.label
        ..showAge          = _showAge
        ..showGender       = _showGender
        ..showBio          = _showBio
        ..showSkills       = _showSkills
        ..showLinks        = _showLinks
        ..customSections   = _sections
            .where((s) => s.headingCtrl.text.trim().isNotEmpty)
            .map((s) {
              final sec = ProfileSection();
              sec.heading   = s.headingCtrl.text.trim();
              sec.content   = s.contentCtrl.text.trim();
              sec.isVisible = s.isVisible;
              return sec;
            })
            .toList()
        ..links = _links
            .where((l) => l.urlCtrl.text.trim().isNotEmpty)
            .map((l) {
              final link = ProfileLink();
              link.label = l.labelCtrl.text.trim().isEmpty
                  ? l.urlCtrl.text.trim()
                  : l.labelCtrl.text.trim();
              link.url = l.urlCtrl.text.trim();
              return link;
            })
            .toList();
      await repo.createOrUpdateProfile(_profile);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.cyan)),
      ),
      error: (e, _) => Scaffold(
        body: Center(
          child: Text('$e', style: const TextStyle(color: AppColors.error)),
        ),
      ),
      data: (profile) {
        if (profile != null && !_loaded) _populateFrom(profile);
        if (!_loaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.cyan)),
          );
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            title: Text('Edit Profile',
                style: AppTypography.headingMedium
                    .copyWith(color: AppColors.textPrimary)),
            actions: [
              TextButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.cyan),
                      )
                    : Text('Save',
                        style: AppTypography.labelLarge
                            .copyWith(color: AppColors.cyan)),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Basic Info ──────────────────────────────────────
                  _SectionHeader('Basic Info'),
                  _Field('Name', _nameCtrl, required: true),
                  _Field('Current Role', _roleCtrl, required: true),
                  _Field('Company / College', _companyCtrl, required: true),
                  _Field('LinkedIn Handle', _linkedInCtrl,
                      required: true,
                      prefix: 'linkedin.com/in/',
                      hint: 'your-handle'),
                  _ExperienceRow(
                    value: _experience,
                    onChanged: (v) => setState(() => _experience = v),
                  ),

                  const SizedBox(height: 20),

                  // ── Optional broadcast ──────────────────────────────
                  _SectionHeader('Optional — Broadcast Controls'),
                  _VisibilityField(
                    label: 'Bio',
                    hint: 'Tell people who you are (500 chars max)',
                    controller: _bioCtrl,
                    isVisible: _showBio,
                    onVisibilityChanged: (v) => setState(() => _showBio = v),
                    maxLines: 4,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 12),
                  _VisibilityField(
                    label: 'Skills',
                    hint: 'Comma-separated, e.g. Flutter, PyTorch, Figma',
                    controller: _skillsCtrl,
                    isVisible: _showSkills,
                    onVisibilityChanged: (v) => setState(() => _showSkills = v),
                  ),

                  const SizedBox(height: 24),

                  // ── Custom Sections ─────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionHeader('Sections'),
                      TextButton.icon(
                        onPressed: _addSection,
                        icon: const Icon(Icons.add, size: 16,
                            color: AppColors.cyan),
                        label: Text('Add Section',
                            style: AppTypography.labelSmall
                                .copyWith(color: AppColors.cyan)),
                      ),
                    ],
                  ),
                  if (_sections.isEmpty)
                    _EmptyHint(
                        'Tap "Add Section" to share a custom highlight like\n'
                        '"What I\'m building", "Looking for", etc.'),
                  ..._sections.asMap().entries.map((e) =>
                      _SectionCard(
                        index:     e.key,
                        entry:     e.value,
                        onRemove:  () => _removeSection(e.key),
                        onChanged: () => setState(() {}),
                      )),

                  const SizedBox(height: 24),

                  // ── Custom Links ────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionHeader('Links'),
                      Row(
                        children: [
                          Text('Broadcast',
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textMuted)),
                          const SizedBox(width: 4),
                          Switch(
                            value: _showLinks,
                            onChanged: (v) => setState(() => _showLinks = v),
                            activeColor: AppColors.cyan,
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _addLink,
                    icon: const Icon(Icons.add_link,
                        size: 16, color: AppColors.cyan),
                    label: Text('Add Link',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.cyan)),
                  ),
                  if (_links.isEmpty)
                    _EmptyHint(
                        'Add GitHub, Portfolio, Twitter, Devpost, or any URL.'),
                  ..._links.asMap().entries.map((e) =>
                      _LinkCard(
                        index:    e.key,
                        entry:    e.value,
                        onRemove: () => _removeLink(e.key),
                      )),

                  const SizedBox(height: 24),

                  // ── Privacy toggles ─────────────────────────────────
                  _SectionHeader('Privacy'),
                  _ToggleRow(
                    label: 'Broadcast my age',
                    value: _showAge,
                    onChanged: (v) => setState(() => _showAge = v),
                  ),
                  _ToggleRow(
                    label: 'Broadcast my gender',
                    value: _showGender,
                    onChanged: (v) => setState(() => _showGender = v),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Section / Link entry holders ──────────────────────────────────

class _SectionEntry {
  final TextEditingController headingCtrl;
  final TextEditingController contentCtrl;
  bool isVisible;
  _SectionEntry({
    required this.headingCtrl,
    required this.contentCtrl,
    required this.isVisible,
  });
}

class _LinkEntry {
  final TextEditingController labelCtrl;
  final TextEditingController urlCtrl;
  _LinkEntry({required this.labelCtrl, required this.urlCtrl});
}

// ── Custom Section Card ────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final int index;
  final _SectionEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  const _SectionCard({
    required this.index,
    required this.entry,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Section ${index + 1}',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.textMuted)),
              const Spacer(),
              Row(
                children: [
                  Text('Broadcast',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.textMuted)),
                  Switch(
                    value: entry.isVisible,
                    onChanged: (v) {
                      entry.isVisible = v;
                      onChanged();
                    },
                    activeColor: AppColors.cyan,
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.error),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: entry.headingCtrl,
            style: AppTypography.labelLarge
                .copyWith(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Section heading (e.g. "What I\'m building")',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: entry.contentCtrl,
            maxLines: 3,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Write something...',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom Link Card ───────────────────────────────────────────────

class _LinkCard extends StatelessWidget {
  final int index;
  final _LinkEntry entry;
  final VoidCallback onRemove;
  const _LinkCard(
      {required this.index, required this.entry, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, size: 14, color: AppColors.cyan),
              const SizedBox(width: 6),
              Text('Link ${index + 1}',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.textMuted)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.error),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: entry.labelCtrl,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Label (e.g. GitHub, Portfolio, Twitter)',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: entry.urlCtrl,
            keyboardType: TextInputType.url,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'https://',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              prefixIcon:
                  Icon(Icons.open_in_new, size: 14, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title,
            style: AppTypography.headingSmall
                .copyWith(color: AppColors.textPrimary)),
      );
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool required;
  final String? prefix;
  final String? hint;
  final int maxLines;
  final int? maxLength;

  const _Field(this.label, this.controller,
      {this.required = false, this.prefix, this.hint,
       this.maxLines = 1, this.maxLength});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          style: AppTypography.bodyLarge
              .copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: label,
            prefixText: prefix,
            hintText: hint,
            prefixStyle: AppTypography.bodyMedium
                .copyWith(color: AppColors.textMuted),
          ),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty)
                  ? '$label is required'
                  : null
              : null,
        ),
      );
}

class _VisibilityField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isVisible;
  final ValueChanged<bool> onVisibilityChanged;
  final int maxLines;
  final int? maxLength;

  const _VisibilityField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.isVisible,
    required this.onVisibilityChanged,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(label,
                  style: AppTypography.labelLarge
                      .copyWith(color: AppColors.textSecondary)),
            ),
            Row(children: [
              Text('Broadcast',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted)),
              const SizedBox(width: 4),
              Switch(
                value: isVisible,
                onChanged: onVisibilityChanged,
                activeColor: AppColors.cyan,
              ),
            ]),
          ]),
          TextField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      );
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Switch(
              value: value, onChanged: onChanged, activeColor: AppColors.cyan),
        ]),
      );
}

class _ExperienceRow extends StatelessWidget {
  final ExperienceLevel value;
  final ValueChanged<ExperienceLevel> onChanged;
  const _ExperienceRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<ExperienceLevel>(
          value: value,
          dropdownColor: AppColors.surfaceElevated,
          style: AppTypography.bodyLarge
              .copyWith(color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Experience'),
          items: ExperienceLevel.values
              .map((l) =>
                  DropdownMenuItem(value: l, child: Text(l.label)))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      );
}
