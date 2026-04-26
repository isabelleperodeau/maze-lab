import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_type.dart';

class CurrentPath {
  const CurrentPath({
    required this.name,
    required this.solved,
    required this.games,
  });

  final String name;
  final int solved;
  final List<GameType> games;

  int get total => games.length;
}

final currentPathProvider = Provider<CurrentPath?>((ref) {
  return const CurrentPath(
    name: 'Current Challenge',
    solved: 3,
    games: [
      GameTypes.sudoku,
      GameTypes.kakuro,
      GameTypes.nonogram,
      GameTypes.sudoku,
      GameTypes.twentyFortyEight,
      GameTypes.kakuro,
      GameTypes.nonogram,
      GameTypes.sudoku,
    ],
  );
});

class ContinueCard extends ConsumerWidget {
  const ContinueCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(currentPathProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: path == null ? const _EmptyState() : _ActiveState(path: path),
      ),
    );
  }
}

class _ActiveState extends StatelessWidget {
  const _ActiveState({required this.path});

  final CurrentPath path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Continue your journey', style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(path.name, style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        _PebblePath(games: path.games, solved: path.solved),
        const SizedBox(height: 12),
        Text(
          '${path.solved} of ${path.total} solved',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(onPressed: () {}, child: const Text('Continue')),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('No path in progress', style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        Text('Start your first path', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () {},
            child: const Text('Browse paths'),
          ),
        ),
      ],
    );
  }
}

enum _PebbleState { completed, current, upcoming }

class _PebblePath extends StatelessWidget {
  const _PebblePath({required this.games, required this.solved});

  final List<GameType> games;
  final int solved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final outline = theme.colorScheme.outlineVariant;

    final children = <Widget>[];
    for (var i = 0; i < games.length; i++) {
      final state = i < solved
          ? _PebbleState.completed
          : (i == solved ? _PebbleState.current : _PebbleState.upcoming);
      children.add(_Pebble(game: games[i], state: state));
      if (i < games.length - 1) {
        final reached = i < solved;
        children.add(
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: reached ? primary : outline,
            ),
          ),
        );
      }
    }

    return SizedBox(height: 36, child: Row(children: children));
  }
}

class _Pebble extends StatelessWidget {
  const _Pebble({required this.game, required this.state});

  final GameType game;
  final _PebbleState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final outline = theme.colorScheme.outlineVariant;
    final muted = theme.colorScheme.onSurfaceVariant;

    if (state == _PebbleState.current) {
      final tertiary = theme.colorScheme.tertiary;
      return Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: tertiary.withValues(alpha: 0.2),
        ),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: tertiary),
          child: Icon(game.icon, size: 16, color: theme.colorScheme.onTertiary),
        ),
      );
    }

    final completed = state == _PebbleState.completed;
    final pebble = Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed ? primary : Colors.transparent,
        border: completed ? null : Border.all(color: outline, width: 2),
      ),
      child: Icon(game.icon, size: 16, color: completed ? onPrimary : muted),
    );

    if (!completed) return pebble;

    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          pebble,
          Container(
            width: 14,
            height: 14,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green,
              border: Border.all(color: theme.colorScheme.surface, width: 2),
            ),
            child: const Icon(Icons.check, size: 8, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
