import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:worknet/core/theme/app_colors.dart';
import 'package:worknet/core/theme/app_typography.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _cards = [
    _AboutCard(
      icon: Icons.wifi_tethering_rounded,
      title: 'What WorkNet Does',
      body:
          'WorkNet helps people at events discover nearby professionals without needing internet or a central server. Your phone locally broadcasts the profile details you choose to share and listens for nearby WorkNet broadcasts.',
    ),
    _AboutCard(
      icon: Icons.hub_outlined,
      title: 'How Discovery Works',
      body:
          'Discovery uses Bluetooth, local Wi-Fi, and peer-to-peer transport where available. Profiles can relay through nearby devices for a maximum of two hops so a venue can feel connected without cloud sync.',
    ),
    _AboutCard(
      icon: Icons.badge_outlined,
      title: 'What You Broadcast',
      body:
          'Your name, role, company or college, experience, spotlight, and LinkedIn handle are part of the core broadcast. Bio, skills, links, sections, and profile photo thumbnail are controlled from your profile editor.',
    ),
    _AboutCard(
      icon: Icons.storage_outlined,
      title: 'What Stays On Device',
      body:
          'Your profile, saved avatar, discovered peers, and app state are stored locally on this device. V1 has no WorkNet account, backend upload, cloud profile hosting, or remote image storage.',
    ),
    _AboutCard(
      icon: Icons.visibility_off_outlined,
      title: 'Stealth Mode',
      body:
          'Stealth Mode stops broadcasting and clears the visible nearby feed. You can resume discovery any time from the feed or settings.',
    ),
    _AboutCard(
      icon: Icons.photo_outlined,
      title: 'Profile Photos',
      body:
          'Profile photos are stored locally. Nearby people only receive a small compressed thumbnail if you explicitly enable photo sharing; otherwise they see your initials.',
    ),
    _AboutCard(
      icon: Icons.shield_outlined,
      title: 'Security',
      body:
          'WorkNet validates packet size, schema version, timestamps, relay hops, text lengths, and URLs before showing nearby profiles. Stale packets and malformed traffic are ignored. Nearby profiles are locally broadcast and are not verified identities.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'About WorkNet',
          style: AppTypography.headingMedium
              .copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final entry in _cards.asMap().entries)
            entry.value
                .animate()
                .fadeIn(
                  delay: (entry.key * 45).ms,
                  duration: 240.ms,
                )
                .slideY(
                  begin: 0.04,
                  end: 0,
                  delay: (entry.key * 45).ms,
                  duration: 240.ms,
                ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'WorkNet v1.0.0\nDeveloped by Vasanthadithya (160123749049) & Sai Geethika (160123749302)',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _AboutCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.cyan.withAlpha(28),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.cyan, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    body,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
