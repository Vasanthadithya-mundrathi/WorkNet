import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worknet/core/router/app_router.dart';
import 'package:worknet/core/theme/app_colors.dart';
import 'package:worknet/core/theme/app_typography.dart';
import 'package:worknet/data/models/user_profile.dart';
import 'package:worknet/shared/widgets/live_badge.dart';
import 'package:worknet/shared/widgets/empty_states.dart';
import 'package:worknet/features/feed/providers/feed_provider.dart';
import 'package:worknet/features/feed/widgets/peer_card.dart';
import 'package:worknet/features/feed/widgets/stats_bar.dart';

// ════════════════════════════════════════════════════════════════════
// NearbyFeedScreen — the home screen / core WorkNet experience
// ════════════════════════════════════════════════════════════════════

class NearbyFeedScreen extends ConsumerStatefulWidget {
  const NearbyFeedScreen({super.key});

  @override
  ConsumerState<NearbyFeedScreen> createState() => _NearbyFeedScreenState();
}

class _NearbyFeedScreenState extends ConsumerState<NearbyFeedScreen> {
  SpotlightType? _activeFilter; // null = All

  @override
  void initState() {
    super.initState();
    // Auto-start event mode when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedProvider.notifier).startEventMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(feedAsync),
      body: feedAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.cyan),
        ),
        error: (e, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Discovery Error',
                  style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(feedProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (feed) => _buildBody(feed),
      ),
    );
  }

  AppBar _buildAppBar(AsyncValue<FeedState> feedAsync) {
    final isActive = feedAsync.valueOrNull?.isEventModeActive ?? false;
    final isStealth = feedAsync.valueOrNull?.isStealthMode ?? false;

    return AppBar(
      backgroundColor: AppColors.background,
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'WorkNet',
            style: AppTypography.headingMedium
                .copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(width: 8),
          LiveBadge(isActive: isActive && !isStealth),
        ],
      ),
      actions: [
        // Stealth toggle
        IconButton(
          tooltip: isStealth ? 'Resume broadcasting' : 'Stealth mode',
          icon: Icon(
            isStealth ? Icons.visibility_off : Icons.visibility,
            size: 20,
            color: isStealth ? AppColors.error : AppColors.textSecondary,
          ),
          onPressed: () => ref.read(feedProvider.notifier).toggleStealth(),
        ),
        // My Profile
        IconButton(
          tooltip: 'My Profile',
          icon: const Icon(Icons.person_outline, size: 20,
              color: AppColors.textSecondary),
          onPressed: () => context.push(AppRoutes.myProfile),
        ),
        // Search
        IconButton(
          tooltip: 'Search',
          icon: const Icon(Icons.search, size: 20,
              color: AppColors.textSecondary),
          onPressed: () => context.push(AppRoutes.search),
        ),
      ],
    );
  }

  Widget _buildBody(FeedState feed) {
    final allPeers = feed.sortedPeers;
    final filtered = _activeFilter == null
        ? allPeers
        : allPeers
            .where((p) => p.profile.spotlightType == _activeFilter)
            .toList();

    return Column(
      children: [
        // Stats bar
        StatsBar(
          total:      allPeers.length,
          hiring:     feed.hiringCount,
          openToWork: feed.openToWorkCount,
        ),

        // Filter chips
        _FilterChipsRow(
          active: _activeFilter,
          onChanged: (f) => setState(() => _activeFilter = f),
        ),

        // Feed list
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState(feed)
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final peer = filtered[i];
                    return PeerCard(
                      key: ValueKey(peer.userId),
                      peer: peer,
                      animationIndex: i,
                      onTap: () => context.push('/profile/${peer.userId}'),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(FeedState feed) {
    if (feed.isStealthMode) {
      return const FeedStealthEmptyState();
    }
    if (_activeFilter != null && feed.sortedPeers.isNotEmpty) {
      // Meaning there ARE peers, but none match the filter
      return FeedFilterEmptyState(filterLabel: _activeFilter!.name);
    }
    return const FeedScanningEmptyState();
  }
}

// ── Filter Chips ───────────────────────────────────────────────────

class _FilterChipsRow extends StatelessWidget {
  final SpotlightType? active;
  final ValueChanged<SpotlightType?> onChanged;

  const _FilterChipsRow({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        children: [
          _Chip(label: 'All', selected: active == null, onTap: () => onChanged(null)),
          const SizedBox(width: 6),
          _Chip(
            label: '🟦 Hiring',
            selected: active == SpotlightType.hiring,
            onTap: () => onChanged(SpotlightType.hiring),
            activeColor: AppColors.spotlightHiring,
          ),
          const SizedBox(width: 6),
          _Chip(
            label: '🟩 Open to Work',
            selected: active == SpotlightType.openToWork,
            onTap: () => onChanged(SpotlightType.openToWork),
            activeColor: AppColors.spotlightOpenToWork,
          ),
          const SizedBox(width: 6),
          _Chip(
            label: '🟣 Building',
            selected: active == SpotlightType.building,
            onTap: () => onChanged(SpotlightType.building),
            activeColor: AppColors.spotlightBuilding,
          ),
          const SizedBox(width: 6),
          _Chip(
            label: '🟠 Learning',
            selected: active == SpotlightType.learning,
            onTap: () => onChanged(SpotlightType.learning),
            activeColor: AppColors.spotlightLearning,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color activeColor;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.activeColor = AppColors.cyan,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withOpacity(0.15)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor.withOpacity(0.5) : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: selected ? activeColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

