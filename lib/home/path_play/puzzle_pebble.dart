import 'package:flutter/material.dart';
import '../../models/game_type.dart';
import '../../providers/path_play_provider.dart';

class PuzzlePebble extends StatelessWidget {
  final PuzzleInfo puzzle;
  final bool isCurrent;
  final bool canPlay;
  final VoidCallback onTap;

  const PuzzlePebble({
    super.key,
    required this.puzzle,
    required this.isCurrent,
    required this.canPlay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gameType = GameTypes.all.firstWhere(
      (g) => g.id == puzzle.type,
      orElse: () => GameTypes.sudoku,
    );
    final theme = Theme.of(context);

    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (puzzle.isCompleted) {
      backgroundColor = theme.colorScheme.primaryContainer;
      borderColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimaryContainer;
    } else if (isCurrent) {
      backgroundColor = theme.colorScheme.secondaryContainer;
      borderColor = theme.colorScheme.secondary;
      textColor = theme.colorScheme.onSecondaryContainer;
    } else {
      backgroundColor = theme.colorScheme.surfaceContainerHighest;
      borderColor = theme.colorScheme.outline;
      textColor = theme.colorScheme.onSurface;
    }

    return GestureDetector(
      onTap: canPlay ? onTap : null,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 2),
        ),
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status indicator
              _buildStatusIndicator(theme),
              const SizedBox(height: 12),

              // Game icon
              Icon(
                gameType.icon,
                size: 36,
                color: gameType.color,
              ),
              const SizedBox(height: 8),

              // Game name
              Text(
                gameType.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),

              // Difficulty
              const SizedBox(height: 4),
              Text(
                _capitalize(puzzle.difficulty),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor,
                ),
              ),

              // Order number
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: gameType.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: Text(
                  '#${puzzle.order}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: gameType.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(ThemeData theme) {
    if (puzzle.isCompleted) {
      return Icon(
        Icons.check_circle,
        color: theme.colorScheme.primary,
        size: 24,
      );
    } else if (isCurrent) {
      return Icon(
        Icons.play_circle,
        color: theme.colorScheme.secondary,
        size: 24,
      );
    } else {
      return Icon(
        Icons.lock_outline,
        color: theme.colorScheme.outline,
        size: 24,
      );
    }
  }

  String _capitalize(String s) =>
      s[0].toUpperCase() + s.substring(1);
}
