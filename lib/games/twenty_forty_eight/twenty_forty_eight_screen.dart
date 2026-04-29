import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/game_state.dart';
import '../2048/game_2048_provider.dart';

class TwentyFortyEightScreen extends ConsumerStatefulWidget {
  const TwentyFortyEightScreen({
    super.key,
    required this.difficulty,
    this.pathId,
    this.puzzleIndex,
    this.puzzleId,
  });

  final String difficulty;
  final String? pathId;
  final String? puzzleIndex;
  final String? puzzleId;

  @override
  ConsumerState<TwentyFortyEightScreen> createState() => _TwentyFortyEightScreenState();
}

class _TwentyFortyEightScreenState extends ConsumerState<TwentyFortyEightScreen> {
  @override
  void initState() {
    super.initState();
    final difficultyEnum = GameDifficulty.values.firstWhere(
      (d) => d.name == widget.difficulty,
      orElse: () => GameDifficulty.easy,
    );
    Future.microtask(() {
      ref.read(game2048Provider.notifier).startGame(difficultyEnum);
    });
  }

  void _showWinDialog() {
    final gameState = ref.read(game2048Provider);

    String getTargetTile(GameDifficulty difficulty) {
      switch (difficulty) {
        case GameDifficulty.easy:
          return '2048';
        case GameDifficulty.medium:
          return '4096';
        case GameDifficulty.hard:
          return '8192';
      }
    }

    final targetTile = getTargetTile(gameState.difficulty);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('🎉 Vous avez atteint $targetTile!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score: ${gameState.score}'),
            const SizedBox(height: 8),
            Text('Temps: ${gameState.formattedTime}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/');
            },
            child: const Text('Retour à l\'accueil'),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    final gameState = ref.read(game2048Provider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('💔 Partie perdue!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score final: ${gameState.score}'),
            const SizedBox(height: 8),
            Text('Temps: ${gameState.formattedTime}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/');
            },
            child: const Text('Retour à l\'accueil'),
          ),
        ],
      ),
    );
  }

  String _getTargetTileString(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return '2048';
      case GameDifficulty.medium:
        return '4096';
      case GameDifficulty.hard:
        return '8192';
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(game2048Provider);
    final theme = Theme.of(context);

    ref.listen(game2048Provider, (previous, next) {
      if (previous != null && !previous.isSolved && next.isSolved) {
        Future.microtask(() => _showWinDialog());
      }
    });

    ref.listen(game2048Provider, (previous, next) {
      if (previous != null && !previous.isGameOver && next.isGameOver) {
        Future.microtask(() => _showGameOverDialog());
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('2048'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                gameState.formattedTime,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.difficulty.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Target: ${_getTargetTileString(gameState.difficulty)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Score: ${gameState.score}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Game2048Grid(
                board: gameState.board,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Arrow controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: () {
                        ref.read(game2048Provider.notifier).move(MoveDirection.up);
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        ref.read(game2048Provider.notifier).move(MoveDirection.left);
                      },
                    ),
                    const SizedBox(width: 32),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        ref.read(game2048Provider.notifier).move(MoveDirection.right);
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_downward),
                      onPressed: () {
                        ref.read(game2048Provider.notifier).move(MoveDirection.down);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Game2048Grid extends StatelessWidget {
  const Game2048Grid({super.key, required this.board});

  final List<List<int>> board;

  Color _getTileColor(int value) {
    return switch (value) {
      0 => Colors.grey[300]!,
      2 => Colors.amber[100]!,
      4 => Colors.amber[200]!,
      8 => Colors.orange[300]!,
      16 => Colors.orange[400]!,
      32 => Colors.deepOrange[300]!,
      64 => Colors.deepOrange[400]!,
      128 => Colors.red[300]!,
      256 => Colors.red[400]!,
      512 => Colors.red[600]!,
      1024 => Colors.purple[300]!,
      2048 => Colors.purple[600]!,
      _ => Colors.indigo[800]!,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width - 60;
    final tileSize = (screenWidth - 12) / 4;

    return Column(
      children: List.generate(4, (row) {
        return Row(
          children: List.generate(4, (col) {
            final value = board[row][col];
            return Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                width: tileSize,
                height: tileSize,
                decoration: BoxDecoration(
                  color: _getTileColor(value),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: value == 0
                    ? null
                    : Center(
                        child: Text(
                          '$value',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: value <= 4 ? Colors.black87 : Colors.white,
                          ),
                        ),
                      ),
              ),
            );
          }),
        );
      }),
    );
  }
}
