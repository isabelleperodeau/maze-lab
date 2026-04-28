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
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: puzzles.length,
      shrinkWrap: true,
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
    );
  }
}
