import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

// ════════════════════════════════════════════════════════════════════
// OnboardingSlidesScreen — 3 swipeable intro cards + skip
// ════════════════════════════════════════════════════════════════════

class OnboardingSlidesScreen extends StatefulWidget {
  const OnboardingSlidesScreen({super.key});

  @override
  State<OnboardingSlidesScreen> createState() => _OnboardingSlidesScreenState();
}

class _OnboardingSlidesScreenState extends State<OnboardingSlidesScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _SlideData(
      icon: Icons.wifi_tethering_rounded,
      title: 'Be Discoverable',
      subtitle:
          'WorkNet silently broadcasts your profile to every nearby professional at this event. No awkward intros needed.',
      iconColor: AppColors.cyan,
    ),
    _SlideData(
      icon: Icons.people_alt_outlined,
      title: 'See Who\'s Around',
      subtitle:
          'Your live feed shows every WorkNet user in range — sorted by proximity. Scan roles, skills, and hiring signals in seconds.',
      iconColor: AppColors.spotlightBuilding,
    ),
    _SlideData(
      icon: Icons.link_rounded,
      title: 'Connect on LinkedIn',
      subtitle:
          'Found someone interesting? Tap their profile and open LinkedIn. WorkNet gets you to the right person — the rest is human.',
      iconColor: AppColors.spotlightOpenToWork,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _goToSetup,
                child: Text(
                  'Skip',
                  style: AppTypography.labelLarge
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (ctx, i) => _SlideView(slide: _slides[i]),
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _page == i ? AppColors.cyan : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Next / Get Started button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: ElevatedButton(
                onPressed: () {
                  if (_page < _slides.length - 1) {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _goToSetup();
                  }
                },
                child: Text(
                  _page < _slides.length - 1 ? 'Next' : 'Get Started',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToSetup() => context.go(AppRoutes.profileSetup);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ── Slide View ─────────────────────────────────────────────────────

class _SlideView extends StatelessWidget {
  final _SlideData slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: slide.iconColor.withOpacity(0.12),
              border: Border.all(color: slide.iconColor.withOpacity(0.3)),
            ),
            child: Icon(slide.icon, size: 46, color: slide.iconColor),
          )
          .animate()
          .scale(duration: 400.ms, curve: Curves.easeOut)
          .fadeIn(duration: 400.ms),

          const SizedBox(height: 36),

          Text(
            slide.title,
            style: AppTypography.displayMedium
                .copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          )
          .animate()
          .fadeIn(delay: 100.ms, duration: 350.ms)
          .slideY(begin: 0.12, end: 0, delay: 100.ms, duration: 350.ms),

          const SizedBox(height: 16),

          Text(
            slide.subtitle,
            style: AppTypography.bodyLarge
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          )
          .animate()
          .fadeIn(delay: 180.ms, duration: 350.ms)
          .slideY(begin: 0.1, end: 0, delay: 180.ms, duration: 350.ms),
        ],
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  const _SlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  });
}
