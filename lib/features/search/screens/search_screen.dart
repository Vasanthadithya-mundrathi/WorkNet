import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/nearby_peer.dart';
import '../../../data/models/user_profile.dart';
import '../../../features/feed/providers/feed_provider.dart';
import '../../../shared/widgets/empty_states.dart';
import '../../../shared/widgets/worknet_avatar.dart';

// ════════════════════════════════════════════════════════════════════
// SearchScreen — full-text + structured filters on discovered peers
// ════════════════════════════════════════════════════════════════════

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _queryController = TextEditingController();
  SpotlightType? _spotlightFilter;
  ExperienceLevel? _experienceFilter;
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  List<NearbyPeer> _filter(List<NearbyPeer> peers) {
    return peers.where((p) {
      final profile = p.profile;

      // Text search
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final matches = profile.name.toLowerCase().contains(q) ||
            profile.currentRole.toLowerCase().contains(q) ||
            profile.companyOrCollege.toLowerCase().contains(q) ||
            (profile.skills?.any((s) => s.toLowerCase().contains(q)) ?? false);
        if (!matches) return false;
      }

      // Spotlight filter
      if (_spotlightFilter != null &&
          profile.spotlightType != _spotlightFilter) {
        return false;
      }

      // Experience filter
      if (_experienceFilter != null &&
          profile.experienceLabel != _experienceFilter!.label) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedProvider);
    final allPeers = feedAsync.valueOrNull?.sortedPeers ?? [];
    final results = _filter(allPeers);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Search',
            style: AppTypography.headingMedium
                .copyWith(color: AppColors.textPrimary)),
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _queryController,
              autofocus: true,
              style: AppTypography.bodyLarge
                  .copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Name, role, company, skill…',
                prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          const SizedBox(height: 12),

          // Filter row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _SpotlightFilter(
                  value: _spotlightFilter,
                  onChanged: (v) => setState(() => _spotlightFilter = v),
                ),
                const SizedBox(width: 8),
                _ExperienceFilter(
                  value: _experienceFilter,
                  onChanged: (v) => setState(() => _experienceFilter = v),
                ),
                if (_spotlightFilter != null || _experienceFilter != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => setState(() {
                      _spotlightFilter = null;
                      _experienceFilter = null;
                    }),
                    child: const Text('Clear'),
                  ),
                ],
              ],
            ),
          ),

          // Results count
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${results.length} result${results.length == 1 ? '' : 's'} · nearby only',
                style: AppTypography.mono
                    .copyWith(color: AppColors.textMuted),
              ),
            ),
          ),

          // Results list
          Expanded(
            child: results.isEmpty
                ? SearchEmptyState(query: _query)
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: results.length,
                    itemBuilder: (ctx, i) =>
                        _SearchResultTile(peer: results[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Search Result Tile ─────────────────────────────────────────────

class _SearchResultTile extends StatelessWidget {
  final NearbyPeer peer;
  const _SearchResultTile({required this.peer});

  Color _spotColor(SpotlightType t) => switch (t) {
        SpotlightType.hiring     => AppColors.spotlightHiring,
        SpotlightType.openToWork => AppColors.spotlightOpenToWork,
        SpotlightType.building   => AppColors.spotlightBuilding,
        SpotlightType.learning   => AppColors.spotlightLearning,
        SpotlightType.exploring  => AppColors.spotlightExploring,
      };

  @override
  Widget build(BuildContext context) {
    final p = peer.profile;
    final color = _spotColor(p.spotlightType);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: WorkNetAvatar(
        name: p.name,
        spotlightType: p.spotlightType,
        size: 40,
        ringThickness: 2,
      ),
      title: Text(p.name,
          style: AppTypography.labelLarge
              .copyWith(color: AppColors.textPrimary)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${p.currentRole} · ${p.companyOrCollege}',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Row(children: [
            Text(p.spotlightType.emoji,
                style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Text(p.spotlightType.displayLabel,
                style: AppTypography.mono.copyWith(color: color)),
          ]),
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => Container(), // replaced by router in W5
      )),
    );
  }
}

// ── Spotlight Filter Dropdown ──────────────────────────────────────

class _SpotlightFilter extends StatelessWidget {
  final SpotlightType? value;
  final ValueChanged<SpotlightType?> onChanged;
  const _SpotlightFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: value != null ? AppColors.cyanDim : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value != null
              ? AppColors.cyan.withOpacity(0.4)
              : AppColors.border,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<SpotlightType?>(
        value: value,
        underline: const SizedBox(),
        dropdownColor: AppColors.surfaceElevated,
        style: AppTypography.labelSmall
            .copyWith(color: AppColors.textSecondary),
        hint: Text('Spotlight',
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.textSecondary)),
        items: [
          const DropdownMenuItem(value: null, child: Text('All Spotlights')),
          ...SpotlightType.values.map((t) => DropdownMenuItem(
                value: t,
                child: Text('${t.emoji} ${t.displayLabel}'),
              )),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

// ── Experience Filter Dropdown ─────────────────────────────────────

class _ExperienceFilter extends StatelessWidget {
  final ExperienceLevel? value;
  final ValueChanged<ExperienceLevel?> onChanged;
  const _ExperienceFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: value != null ? AppColors.cyanDim : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value != null
              ? AppColors.cyan.withOpacity(0.4)
              : AppColors.border,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<ExperienceLevel?>(
        value: value,
        underline: const SizedBox(),
        dropdownColor: AppColors.surfaceElevated,
        style: AppTypography.labelSmall
            .copyWith(color: AppColors.textSecondary),
        hint: Text('Experience',
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.textSecondary)),
        items: [
          const DropdownMenuItem(value: null, child: Text('Any Experience')),
          ...ExperienceLevel.values.map((l) => DropdownMenuItem(
                value: l,
                child: Text(l.label),
              )),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

