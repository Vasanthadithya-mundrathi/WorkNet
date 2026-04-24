import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:worknet/core/theme/app_colors.dart';
import 'package:worknet/core/theme/app_typography.dart';

// ════════════════════════════════════════════════════════════════════
// Empty state widgets — used across the app
// ════════════════════════════════════════════════════════════════════

// ── Feed empty states ──────────────────────────────────────────────

/// Shown when no peers have been discovered yet (scanning in progress)
class FeedScanningEmptyState extends StatelessWidget {
  const FeedScanningEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return _EmptyState(
      iconWidget: _PulsingRadar(),
      title: 'Scanning for professionals…',
      subtitle:
          'Broadcasting on WiFi, Bluetooth & P2P mesh simultaneously.',
      footerNote: 'First peer typically appears within 2–5 seconds.',
      action: _TransportStatusRow(),
    );
  }
}

class _TransportStatusRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: const [
        _TransportBadge(label: '📡 WiFi LAN', active: true),
        _TransportBadge(label: '🔵 Bluetooth', active: true),
        _TransportBadge(label: '🔗 P2P Mesh', active: true),
      ],
    );
  }
}

class _TransportBadge extends StatelessWidget {
  final String label;
  final bool active;
  const _TransportBadge({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? AppColors.cyan.withAlpha(25)
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? AppColors.cyan.withAlpha(80)
              : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: active ? AppColors.cyan : AppColors.textMuted,
        ),
      ),
    );
  }
}


/// Shown when event mode is off (stealth)
class FeedStealthEmptyState extends StatelessWidget {
  const FeedStealthEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return _EmptyState(
      icon: Icons.visibility_off_outlined,
      iconColor: AppColors.error,
      title: 'Stealth mode is ON',
      subtitle: 'You are invisible. Toggle stealth off in the top bar to start broadcasting and discovering.',
    );
  }
}

/// Shown when filter returns zero results
class FeedFilterEmptyState extends StatelessWidget {
  final String filterLabel;
  const FeedFilterEmptyState({super.key, required this.filterLabel});

  @override
  Widget build(BuildContext context) {
    return _EmptyState(
      icon: Icons.filter_list_off_rounded,
      iconColor: AppColors.textMuted,
      title: 'No "$filterLabel" nearby',
      subtitle: 'There are no users with this spotlight type in range right now.',
      footerNote: 'Try the "All" filter to see everyone.',
    );
  }
}

// ── Search empty state ─────────────────────────────────────────────

class SearchEmptyState extends StatelessWidget {
  final String query;
  const SearchEmptyState({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return _EmptyState(
      icon: Icons.search_off_outlined,
      iconColor: AppColors.textMuted,
      title: query.isEmpty
          ? 'No one nearby yet'
          : 'No match for "$query"',
      subtitle: query.isEmpty
          ? 'Nearby profiles will appear here once discovered.'
          : 'Search is limited to currently discovered users.',
    );
  }
}

// ── Generic error state ────────────────────────────────────────────

class ErrorEmptyState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorEmptyState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _EmptyState(
      icon: Icons.error_outline_rounded,
      iconColor: AppColors.error,
      title: 'Something went wrong',
      subtitle: message,
      action: onRetry != null
          ? ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            )
          : null,
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Private base empty state widget
// ════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final Widget? iconWidget;
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final String? footerNote;
  final Widget? action;

  const _EmptyState({
    this.iconWidget,
    this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    this.footerNote,
    this.action,
  }) : assert(iconWidget != null || icon != null);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon / custom widget
            iconWidget ??
                Icon(icon, size: 56, color: iconColor ?? AppColors.textMuted),

            const SizedBox(height: 24),

            Text(
              title,
              style: AppTypography.headingMedium
                  .copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            )
            .animate()
            .fadeIn(duration: 280.ms)
            .slideY(begin: 0.06, end: 0),

            const SizedBox(height: 10),

            Text(
              subtitle,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            )
            .animate()
            .fadeIn(delay: 60.ms, duration: 280.ms),

            if (footerNote != null) ...[
              const SizedBox(height: 12),
              Text(
                footerNote!,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 120.ms, duration: 280.ms),
            ],

            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ── Pulsing radar animation for scanning state ─────────────────────

class _PulsingRadar extends StatefulWidget {
  @override
  State<_PulsingRadar> createState() => _PulsingRadarState();
}

class _PulsingRadarState extends State<_PulsingRadar>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2400),
      );
      Future.delayed(Duration(milliseconds: i * 600), () {
        if (mounted) ctrl.repeat();
      });
      return ctrl;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Expanding rings
          ..._controllers.map((ctrl) {
            return AnimatedBuilder(
              animation: ctrl,
              builder: (_, __) {
                return Opacity(
                  opacity: (1 - ctrl.value).clamp(0.0, 0.6),
                  child: Container(
                    width: 40 + (ctrl.value * 80),
                    height: 40 + (ctrl.value * 80),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.cyan
                            .withAlpha(((1 - ctrl.value) * 150).toInt()),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          // Centre dot
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cyan.withAlpha(30),
              border: Border.all(color: AppColors.cyan, width: 2),
            ),
            child: const Icon(Icons.wifi_tethering_rounded,
                color: AppColors.cyan, size: 18),
          ),
        ],
      ),
    );
  }
}
