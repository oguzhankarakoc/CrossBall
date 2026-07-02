import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/game_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/rarity.dart';
import '../../../search/domain/search.dart';
import '../../../../shared/providers/app_providers.dart';

class PlayerSearchModal extends ConsumerStatefulWidget {
  const PlayerSearchModal({super.key});

  @override
  ConsumerState<PlayerSearchModal> createState() => _PlayerSearchModalState();
}

class _PlayerSearchModalState extends ConsumerState<PlayerSearchModal> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<Player> _results = [];
  List<Player> _recent = [];
  List<Player> _popular = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _focusNode.requestFocus();
    _controller.addListener(_onQueryChanged);
  }

  Future<void> _loadInitial() async {
    final repo = ref.read(searchRepositoryProvider);
    final recent = await repo.getRecentPicks();
    final popular = await repo.getPopularPicks();
    if (mounted) {
      setState(() {
        _recent = recent;
        _popular = popular;
        _results = recent.isNotEmpty ? recent : popular;
      });
    }
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: GameConstants.searchDebounceMs),
      () => _search(_controller.text),
    );
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    final start = DateTime.now();
    final response = await ref.read(searchRepositoryProvider).search(query);
    final latency = DateTime.now().difference(start).inMilliseconds;
    ref.read(analyticsProvider).track('search_query', properties: {
      'query_length': query.length,
      'result_count': response.results.length,
      'latency_ms': latency,
    });
    if (mounted) {
      setState(() {
        _results = response.results;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final query = _controller.text;
    final showSections = query.isEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: colors.cardBorder)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search player...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _controller.clear();
                                  _loadInitial();
                                },
                              )
                            : null,
                    filled: true,
                    fillColor: colors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    if (showSections && _recent.isNotEmpty) ...[
                      _SectionHeader(title: 'Recent picks'),
                      ..._recent.map((p) => _PlayerTile(
                            player: p,
                            onTap: () => Navigator.pop(context, p),
                          )),
                    ],
                    if (showSections && _popular.isNotEmpty) ...[
                      _SectionHeader(title: 'Popular picks'),
                      ..._popular.map((p) => _PlayerTile(
                            player: p,
                            onTap: () => Navigator.pop(context, p),
                          )),
                    ],
                    if (!showSections)
                      ..._results.map((p) => _PlayerTile(
                            player: p,
                            onTap: () => Navigator.pop(context, p),
                          )),
                    if (_results.isEmpty && !_loading && query.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No players found')),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.accent,
            ),
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player, required this.onTap});

  final Player player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: colors.primary,
        child: Text(
          player.nationalityCode ?? '?',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(player.name),
      subtitle: player.primaryPosition != null
          ? Text(player.primaryPosition!, style: const TextStyle(fontSize: 12))
          : null,
      trailing: Icon(Icons.chevron_right, size: 18, color: colors.textSecondary),
    );
  }
}

class AnswerResultSheet extends StatelessWidget {
  const AnswerResultSheet({super.key, required this.result});

  final dynamic result;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final correct = result.correct as bool;
    final tier = RarityTier.fromUsagePercentage(
      (result.usagePercentage as num?)?.toDouble() ?? 50,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: colors.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            result.playerName as String,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                correct ? Icons.check_circle : Icons.cancel,
                color: correct ? colors.primary : AppColors.error,
              ),
              const SizedBox(width: 8),
              Text(correct ? 'Correct' : 'Incorrect'),
            ],
          ),
          if (correct) ...[
            const SizedBox(height: 12),
            Text(
              'Used by ${(result.usagePercentage as num).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: tier.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tier.color),
              ),
              child: Text(
                'Tier: ${tier.label}',
                style: TextStyle(
                  color: tier.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
