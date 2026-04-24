import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:worknet/core/theme/app_colors.dart';
import 'package:worknet/core/theme/app_typography.dart';
import 'package:worknet/data/models/nearby_peer.dart';
import 'package:worknet/data/models/user_profile.dart';
import 'package:worknet/features/feed/providers/feed_provider.dart';
import 'package:worknet/shared/widgets/worknet_avatar.dart';

// ════════════════════════════════════════════════════════════════════
// PeerProfileViewScreen — full detail view of a discovered peer
// Reads directly from feedProvider so it's always fresh.
// ════════════════════════════════════════════════════════════════════

class PeerProfileViewScreen extends ConsumerWidget {
  final String userId;
  const PeerProfileViewScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider);

    return feedAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.cyan),
        ),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background),
        body: const Center(
          child: Text(
            'Could not load profile.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
      data: (feed) {
        final peer = feed.peers[userId];
        if (peer == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(backgroundColor: AppColors.background),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        color: AppColors.textMuted, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Profile no longer in range',
                      style: AppTypography.headingSmall
                          .copyWith(color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This person may have left the venue or enabled Stealth Mode.',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return _PeerProfileView(peer: peer);
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// URL Launcher Utility — shared by both profile screens
// ════════════════════════════════════════════════════════════════════

Future<void> launchLinkedIn(BuildContext context, String handle) async {
  final trimmed = handle.trim();
  if (trimmed.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('LinkedIn handle not set.'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    }
    return;
  }

  final url = Uri.parse('https://www.linkedin.com/in/$trimmed');
  try {
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      // Fallback: in-app browser
      await launchUrl(url, mode: LaunchMode.inAppBrowserView);
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open LinkedIn: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

Future<void> launchGenericUrl(BuildContext context, String rawUrl) async {
  final url = Uri.tryParse(rawUrl);
  if (url == null || !url.hasScheme) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid URL.')),
      );
    }
    return;
  }
  try {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link: $e')),
      );
    }
  }
}

// ════════════════════════════════════════════════════════════════════
// _PeerProfileView — the actual content
// ════════════════════════════════════════════════════════════════════

class _PeerProfileView extends StatelessWidget {
  final NearbyPeer peer;
  const _PeerProfileView({required this.peer});

  Color _spotlightColor(SpotlightType t) => switch (t) {
        SpotlightType.hiring     => AppColors.spotlightHiring,
        SpotlightType.openToWork => AppColors.spotlightOpenToWork,
        SpotlightType.building   => AppColors.spotlightBuilding,
        SpotlightType.learning   => AppColors.spotlightLearning,
        SpotlightType.exploring  => AppColors.spotlightExploring,
      };

  @override
  Widget build(BuildContext context) {
    final p = peer.profile;
    final spotColor = _spotlightColor(p.spotlightType);
    final hasLinkedIn = p.linkedInHandle.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ───────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Gradient backdrop
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          spotColor.withOpacity(0.18),
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                  // Avatar centred
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 56),
                        WorkNetAvatar(
                          name:          p.name,
                          spotlightType: p.spotlightType,
                          size:          80,
                          ringThickness: 3,
                        ),
                        const SizedBox(height: 12),
                        Text(p.name,
                            style: AppTypography.headingLarge
                                .copyWith(color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(
                          '${p.currentRole} · ${p.companyOrCollege}',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // ── Spotlight Banner ───────────────────────────────
                  _SpotlightHero(
                    type: p.spotlightType,
                    note: p.spotlightNote,
                    color: spotColor,
                  ),

                  const SizedBox(height: 16),

                  // ── Hop + Experience chips ─────────────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _InfoChip(
                        label: peer.hopLabel,
                        icon: Icons.signal_cellular_alt,
                      ),
                      _InfoChip(
                        label: p.experienceLabel,
                        icon: Icons.work_outline,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Bio ────────────────────────────────────────────
                  if (p.bio != null && p.bio!.isNotEmpty) ...[
                    _SectionHeading('About'),
                    const SizedBox(height: 8),
                    Text(
                      p.bio!,
                      style: AppTypography.bodyLarge
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Skills ─────────────────────────────────────────
                  if (p.skills != null && p.skills!.isNotEmpty) ...[
                    _SectionHeading('Skills'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: p.skills!
                          .map((s) => _SkillPill(label: s))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 8),

                  // ── Custom Sections ────────────────────────────────
                  if (p.sections != null && p.sections!.isNotEmpty) ...[
                    ...p.sections!.map((sec) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeading(sec['h'] ?? ''),
                          const SizedBox(height: 6),
                          Text(
                            sec['c'] ?? '',
                            style: AppTypography.bodyLarge
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )),
                  ],

                  // ── Links ──────────────────────────────────────────
                  if (p.links != null && p.links!.isNotEmpty) ...[
                    _SectionHeading('Links'),
                    const SizedBox(height: 10),
                    ...p.links!.map((link) => _LinkRow(
                          label: link['l'] ?? link['u'] ?? '',
                          url:   link['u'] ?? '',
                          onTap: () => launchGenericUrl(
                              context, link['u'] ?? ''),
                        )),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 8),

                  // ── LinkedIn CTA ──────────────────────────────────

                  if (hasLinkedIn) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => launchLinkedIn(context, p.linkedInHandle),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Open LinkedIn Profile'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tappable URL text — also copies to clipboard on long-press
                    GestureDetector(
                      onTap: () => launchLinkedIn(context, p.linkedInHandle),
                      onLongPress: () {
                        Clipboard.setData(ClipboardData(
                          text: 'https://www.linkedin.com/in/${p.linkedInHandle}',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('LinkedIn URL copied!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Center(
                        child: Text(
                          'linkedin.com/in/${p.linkedInHandle}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.cyan,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.cyan,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Center(
                      child: Text(
                        'LinkedIn not provided',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Safety note ───────────────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Discovered via local mesh — no data sent to the internet.',
                          style: AppTypography.labelSmall
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────

class _SpotlightHero extends StatelessWidget {
  final SpotlightType type;
  final String note;
  final Color color;
  const _SpotlightHero(
      {required this.type, required this.note, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(type.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(type.displayLabel,
                style: AppTypography.labelLarge.copyWith(color: color)),
          ]),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(note,
                style: AppTypography.bodyMedium
                    .copyWith(color: color.withOpacity(0.85))),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(label,
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  const _SectionHeading(this.title);

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary),
      );
}

class _SkillPill extends StatelessWidget {
  final String label;
  const _SkillPill({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary)),
      );
}

class _LinkRow extends StatelessWidget {
  final String label;
  final String url;
  final VoidCallback onTap;
  const _LinkRow({required this.label, required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.link, size: 15, color: AppColors.cyan),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTypography.labelLarge
                          .copyWith(color: AppColors.textPrimary)),
                  if (url.isNotEmpty)
                    Text(url,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.cyan,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.cyan,
                        ),
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
