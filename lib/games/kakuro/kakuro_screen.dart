import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/game_state.dart';
import '../models/kakuro_state.dart';
import 'kakuro_provider.dart';
import '../../services/completion_service.dart';
import '../../providers/path_play_provider.dart';

class KakuroScreen extends ConsumerStatefulWidget {
  const KakuroScreen({
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
  ConsumerState<KakuroScreen> createState() => _KakuroScreenState();
}

class _KakuroScreenState extends ConsumerState<KakuroScreen> {
  int? _selectedRow;
  int? _selectedCol;

  @override
  void initState() {
    super.initState();
    final difficultyEnum = GameDifficulty.values.firstWhere(
      (d) => d.name == widget.difficulty,
      orElse: () => GameDifficulty.easy,
    );
    Future.microtask(() {
      ref.read(kakuroGameProvider.notifier).startGame(difficultyEnum);
    });
  }

  void _showSolvedDialog() async {
    final gameState = ref.read(kakuroGameProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Puzzle résolu!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Temps: ${gameState.formattedTime}'),
            const SizedBox(height: 8),
            Text('Coups: ${gameState.moves.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              if (widget.pathId != null &&
                  widget.puzzleIndex != null &&
                  widget.puzzleId != null) {
                try {
                  await CompletionService.recordCompletion(
                    pathId: int.parse(widget.pathId!),
                    puzzleId: int.parse(widget.puzzleId!),
                    timeTaken: gameState.elapsedSeconds,
                  );

                  if (mounted) {
                    ref.read(pathPlayProvider.notifier).markPuzzleComplete(
                      int.parse(widget.puzzleIndex!),
                      gameState.elapsedSeconds,
                    );

                    context.go('/paths/${widget.pathId}');
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error saving completion: $e')),
                    );
                  }
                }
              } else if (mounted) {
                context.go('/');
              }
            },
            child: const Text('Retour à l\'accueil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(kakuroGameProvider);
    final theme = Theme.of(context);

    ref.listen(kakuroGameProvider, (previous, next) {
      if (!previous!.isSolved && next.isSolved) {
        Future.microtask(() => _showSolvedDialog());
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Kakuro'),
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
                Row(
                  children: [
                    Text(
                      '${gameState.moves.length} moves',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 12),
                    Tooltip(
                      message: gameState.showValidation ? 'Validation activée' : 'Validation désactivée',
                      child: IconButton(
                        icon: Icon(
                          gameState.showValidation ? Icons.visibility : Icons.visibility_off,
                          size: 20,
                        ),
                        onPressed: () {
                          ref.read(kakuroGameProvider.notifier).toggleValidation();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _KakuroGrid(
                board: gameState.board,
                clues: gameState.clues,
                validationState: gameState.cellValidationState,
                showValidation: gameState.showValidation,
                selectedRow: _selectedRow,
                selectedCol: _selectedCol,
                onCellTap: (row, col) {
                  setState(() {
                    _selectedRow = row;
                    _selectedCol = col;
                  });
                },
                onValueSet: (row, col, value) {
                  ref.read(kakuroGameProvider.notifier).setCell(row, col, value);
                },
              ),
            ),
          ),
          if (_selectedRow != null && _selectedCol != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: List.generate(9, (i) {
                    final number = i + 1;
                    return SizedBox(
                      width: 40,
                      height: 40,
                      child: FilledButton(
                        onPressed: () {
                          ref
                              .read(kakuroGameProvider.notifier)
                              .setCell(_selectedRow!, _selectedCol!, number);
                        },
                        child: Text('$number'),
                      ),
                    );
                  }),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_selectedRow != null && _selectedCol != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ref
                                  .read(kakuroGameProvider.notifier)
                                  .setCell(_selectedRow!, _selectedCol!, 0);
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Clear'),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: gameState.moves.isEmpty
                            ? null
                            : () {
                                ref.read(kakuroGameProvider.notifier).undo();
                                setState(() {
                                  _selectedRow = null;
                                  _selectedCol = null;
                                });
                              },
                        icon: const Icon(Icons.undo),
                        label: const Text('Undo'),
                      ),
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

class _KakuroGrid extends StatelessWidget {
  const _KakuroGrid({
    required this.board,
    required this.clues,
    required this.validationState,
    required this.showValidation,
    required this.selectedRow,
    required this.selectedCol,
    required this.onCellTap,
    required this.onValueSet,
  });

  final List<List<int>> board;
  final List<List<KakuroClue?>> clues;
  final Map<(int, int), CellValidationState> validationState;
  final bool showValidation;
  final int? selectedRow;
  final int? selectedCol;
  final Function(int, int) onCellTap;
  final Function(int, int, int) onValueSet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cellSize = (MediaQuery.of(context).size.width - 32) / board[0].length;

    return Column(
      children: List.generate(board.length, (row) {
        return Row(
          children: List.generate(board[row].length, (col) {
            final value = board[row][col];
            final clue = clues[row][col];
            final isSelected = selectedRow == row && selectedCol == col;

            if (value < 0 && clue == null) {
              // Black cell
              return Expanded(
                child: Container(
                  height: cellSize,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                ),
              );
            } else if (clue != null) {
              // Clue cell - check if adjacent cells exist for vertical/horizontal
              final hasVertical = row + 1 < board.length && board[row + 1][col] >= 0;
              final hasHorizontal = col + 1 < board[row].length && board[row][col + 1] >= 0;

              return Expanded(
                child: Container(
                  height: cellSize,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Stack(
                    children: [
                      // Diagonal line from top-left to bottom-right
                      CustomPaint(
                        painter: _DiagonalPainter(theme.colorScheme.outline),
                        size: Size(cellSize, cellSize),
                      ),
                      // Horizontal total (top-right) - only if cells to the right exist
                      if (hasHorizontal && clue.horizontal != null)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Text(
                            '${clue.horizontal}',
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      // Vertical total (bottom-left) - only if cells below exist
                      if (hasVertical && clue.vertical != null)
                        Positioned(
                          bottom: 2,
                          left: 2,
                          child: Text(
                            '${clue.vertical}',
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            } else {
              // Answer cell
              Color backgroundColor = Colors.transparent;

              if (isSelected) {
                backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.3);
              } else if (showValidation) {
                final cellState = validationState[(row, col)] ?? CellValidationState.empty;
                switch (cellState) {
                  case CellValidationState.valid:
                    backgroundColor = Colors.green.withValues(alpha: 0.2);
                  case CellValidationState.invalid:
                    backgroundColor = Colors.red.withValues(alpha: 0.2);
                  case CellValidationState.incomplete:
                    backgroundColor = Colors.amber.withValues(alpha: 0.1);
                  case CellValidationState.empty:
                    backgroundColor = Colors.transparent;
                }
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => onCellTap(row, col),
                  child: Container(
                    height: cellSize,
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      color: backgroundColor,
                    ),
                    child: Center(
                      child: value == 0
                          ? null
                          : Text(
                              '$value',
                              style: theme.textTheme.titleLarge,
                            ),
                    ),
                  ),
                ),
              );
            }
          }),
        );
      }),
    );
  }
}

class _DiagonalPainter extends CustomPainter {
  _DiagonalPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, 0),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_DiagonalPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
