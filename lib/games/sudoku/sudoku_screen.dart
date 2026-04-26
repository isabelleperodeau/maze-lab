import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/game_state.dart';
import 'sudoku_provider.dart';

class SudokuScreen extends ConsumerStatefulWidget {
  const SudokuScreen({super.key, required this.difficulty});

  final String difficulty;

  @override
  ConsumerState<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends ConsumerState<SudokuScreen> {
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
      ref.read(sudokuGameProvider.notifier).startGame(difficultyEnum);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(sudokuGameProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Sudoku'),
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
                Text(
                  '${gameState.moves.length} moves',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _SudokuGrid(
                board: gameState.board,
                selectedRow: _selectedRow,
                selectedCol: _selectedCol,
                onCellTap: (row, col) {
                  setState(() {
                    _selectedRow = row;
                    _selectedCol = col;
                  });
                },
                onValueSet: (row, col, value) {
                  ref.read(sudokuGameProvider.notifier).setCell(row, col, value);
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
                              .read(sudokuGameProvider.notifier)
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
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: gameState.moves.isEmpty
                        ? null
                        : () {
                            ref.read(sudokuGameProvider.notifier).undo();
                            setState(() {
                              _selectedRow = null;
                              _selectedCol = null;
                            });
                          },
                    icon: const Icon(Icons.undo),
                    label: const Text('Undo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectedRow == null || _selectedCol == null
                        ? null
                        : () {
                            ref
                                .read(sudokuGameProvider.notifier)
                                .setCell(_selectedRow!, _selectedCol!, 0);
                          },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SudokuGrid extends StatelessWidget {
  const _SudokuGrid({
    required this.board,
    required this.selectedRow,
    required this.selectedCol,
    required this.onCellTap,
    required this.onValueSet,
  });

  final List<List<int>> board;
  final int? selectedRow;
  final int? selectedCol;
  final Function(int, int) onCellTap;
  final Function(int, int, int) onValueSet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cellSize = (MediaQuery.of(context).size.width - 32) / 9;

    return Column(
      children: List.generate(9, (row) {
        return Row(
          children: List.generate(9, (col) {
            final value = board[row][col];
            final isSelected = selectedRow == row && selectedCol == col;
            final isInSameBox = (selectedRow != null && selectedCol != null) &&
                (row ~/ 3 == selectedRow! ~/ 3) &&
                (col ~/ 3 == selectedCol! ~/ 3);
            final isInSameRow = selectedRow == row;
            final isInSameCol = selectedCol == col;

            return Expanded(
              child: GestureDetector(
                onTap: () => onCellTap(row, col),
                child: Container(
                  height: cellSize,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        width: row % 3 == 0 ? 2 : 1,
                        color: theme.colorScheme.outline,
                      ),
                      left: BorderSide(
                        width: col % 3 == 0 ? 2 : 1,
                        color: theme.colorScheme.outline,
                      ),
                      right: BorderSide(
                        width: col == 8 ? 2 : 1,
                        color: theme.colorScheme.outline,
                      ),
                      bottom: BorderSide(
                        width: row == 8 ? 2 : 1,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.3)
                        : (isInSameBox || isInSameRow || isInSameCol)
                            ? theme.colorScheme.secondary.withValues(alpha: 0.1)
                            : Colors.transparent,
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
          }),
        );
      }),
    );
  }
}
