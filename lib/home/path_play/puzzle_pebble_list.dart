import 'package:flutter/material.dart';
import '../../providers/path_play_provider.dart';
import 'puzzle_pebble.dart';

class PuzzlePebbleList extends StatelessWidget {
  final List<PuzzleInfo> puzzles;
  final int currentPuzzleIndex;
  final Function(int) onPuzzleTap;

  const PuzzlePebbleList({
    super.key,
    required this.puzzles,
    required this.currentPuzzleIndex,
    required this.onPuzzleTap,
  });

  @override
  Widget build(BuildContext context) {
    if (puzzles.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 32 - 12) / 2;
        final rowCount = (puzzles.length + 1) ~/ 2;
        final height = rowCount * itemWidth + (rowCount - 1) * 12 + 32;

        return SizedBox(
          height: height,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: puzzles.length,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final puzzle = puzzles[index];
              final isCurrent = index == currentPuzzleIndex;
              final canPlay = puzzle.isCompleted || isCurrent;

              return PuzzlePebble(
                puzzle: puzzle,
                isCurrent: isCurrent,
                canPlay: canPlay,
                onTap: () => onPuzzleTap(index),
              );
            },
          ),
        );
      },
    );
  }
}
