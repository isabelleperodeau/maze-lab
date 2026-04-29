import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/game_state.dart';
import '../models/nonogram_state.dart';
import 'nonogram_provider.dart';

class NonogramScreen extends ConsumerStatefulWidget {
  const NonogramScreen({
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
  ConsumerState<NonogramScreen> createState() => _NonogramScreenState();
}

class _NonogramScreenState extends ConsumerState<NonogramScreen> {
  late CellState _selectedMode;
  (int, int)? _lastClickedCell;
  DateTime? _lastClickTime;

  @override
  void initState() {
    super.initState();
    _selectedMode = CellState.filled;
    final difficultyEnum = GameDifficulty.values.firstWhere(
      (d) => d.name == widget.difficulty,
      orElse: () => GameDifficulty.easy,
    );
    Future.microtask(() async {
      await ref.read(nonogramGameProvider.notifier).startGame(difficultyEnum);
    });
  }

  CellState _getNextCycleState(CellState currentState, CellState startMode) {
    if (startMode == CellState.filled) {
      // Cycle: filled -> marked -> empty -> filled
      if (currentState == CellState.filled) {
        return CellState.marked;
      } else if (currentState == CellState.marked) {
        return CellState.empty;
      } else {
        return CellState.filled;
      }
    } else {
      // Cycle: marked -> empty -> filled -> marked
      if (currentState == CellState.marked) {
        return CellState.empty;
      } else if (currentState == CellState.empty) {
        return CellState.filled;
      } else {
        return CellState.marked;
      }
    }
  }

  void _showSolvedDialog() {
    final gameState = ref.read(nonogramGameProvider);
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

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(nonogramGameProvider);
    final theme = Theme.of(context);

    ref.listen(nonogramGameProvider, (previous, next) {
      if (previous != null && !previous.isSolved && next.isSolved) {
        Future.microtask(() => _showSolvedDialog());
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Nonogram'),
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
                          ref.read(nonogramGameProvider.notifier).toggleValidation();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _selectedMode == CellState.filled
                      ? FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedMode = CellState.marked;
                            });
                          },
                          icon: const Icon(Icons.square),
                          label: const Text('Noir'),
                        )
                      : OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedMode = CellState.filled;
                            });
                          },
                          icon: const Icon(Icons.square),
                          label: const Text('Noir'),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _selectedMode == CellState.marked
                      ? FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedMode = CellState.filled;
                            });
                          },
                          icon: const Text('✕', style: TextStyle(fontSize: 18)),
                          label: const Text('Marquer'),
                        )
                      : OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedMode = CellState.marked;
                            });
                          },
                          icon: const Text('✕', style: TextStyle(fontSize: 18, color: Colors.red)),
                          label: const Text('Marquer'),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _NonogramGrid(
                board: gameState.board,
                rowHints: gameState.rowHints,
                colHints: gameState.colHints,
                showValidation: gameState.showValidation,
                selectedMode: _selectedMode,
                onCellTap: (row, col) {
                  final now = DateTime.now();
                  final currentCellState = gameState.board[row][col];
                  final cellKey = (row, col);

                  bool shouldCycle = false;

                  // Check if it's a rapid click on the same cell (within 1 second)
                  if (_lastClickedCell == cellKey && _lastClickTime != null) {
                    final timeDiff = now.difference(_lastClickTime!).inMilliseconds;
                    if (timeDiff < 1000) {
                      shouldCycle = true;
                    }
                  }

                  // Also cycle if the cell already has the selected mode value
                  if (currentCellState == _selectedMode) {
                    shouldCycle = true;
                  }

                  final newState = shouldCycle
                      ? _getNextCycleState(currentCellState, _selectedMode)
                      : _selectedMode;

                  ref.read(nonogramGameProvider.notifier).setCellState(row, col, newState);

                  // Update tracking
                  setState(() {
                    _lastClickedCell = cellKey;
                    _lastClickTime = now;
                  });
                },
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
                            ref.read(nonogramGameProvider.notifier).undo();
                          },
                    icon: const Icon(Icons.undo),
                    label: const Text('Undo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(nonogramGameProvider.notifier).clearBoard();
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

class _NonogramGrid extends ConsumerStatefulWidget {
  const _NonogramGrid({
    required this.board,
    required this.rowHints,
    required this.colHints,
    required this.showValidation,
    required this.selectedMode,
    required this.onCellTap,
  });

  final List<List<CellState>> board;
  final List<List<int>> rowHints;
  final List<List<int>> colHints;
  final bool showValidation;
  final CellState selectedMode;
  final Function(int, int) onCellTap;

  @override
  ConsumerState<_NonogramGrid> createState() => _NonogramGridState();
}

class _NonogramGridState extends ConsumerState<_NonogramGrid> {
  final Set<(int, int)> _draggedCells = {};
  late GlobalKey _gridKey;

  @override
  void initState() {
    super.initState();
    _gridKey = GlobalKey();
  }

  void _applyCellAction(int row, int col) {
    widget.onCellTap(row, col);
  }

  void _applyDragAction(int row, int col, CellState mode) {
    ref.read(nonogramGameProvider.notifier).setCellState(row, col, mode);
  }

  void _handleDrag(PointerEvent event, double cellSize, CellState selectedMode) {
    final RenderBox? gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null) return;

    final localPosition = gridBox.globalToLocal(event.position);
    final maxHintWidth = 50.0;
    final hintRowHeight = cellSize * 2;

    final adjustedX = localPosition.dx - maxHintWidth;
    final adjustedY = localPosition.dy - hintRowHeight;

    if (adjustedX < 0 || adjustedY < 0) return;

    final col = (adjustedX / cellSize).toInt();
    final row = (adjustedY / cellSize).toInt();

    if (row >= 0 && row < widget.board.length && col >= 0 && col < widget.board[0].length) {
      final cellKey = (row, col);
      if (!_draggedCells.contains(cellKey)) {
        _draggedCells.add(cellKey);
        _applyDragAction(row, col, selectedMode);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cellSize = (MediaQuery.of(context).size.width - 100) / widget.board[0].length;
    final maxHintWidth = 50.0;

    return Listener(
      onPointerDown: (event) {
        _draggedCells.clear();
      },
      onPointerMove: (event) {
        _handleDrag(event, cellSize, widget.selectedMode);
      },
      onPointerUp: (_) {
        _draggedCells.clear();
      },
      child: SingleChildScrollView(
        child: Row(
          key: _gridKey,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: maxHintWidth,
              child: Column(
                children: [
                  SizedBox(height: cellSize * 2),
                  ...List.generate(widget.board.length, (row) {
                    return SizedBox(
                      height: cellSize,
                      child: Center(
                        child: Text(
                          widget.rowHints[row].join(','),
                          style: theme.textTheme.labelSmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: cellSize * 2,
                    child: Row(
                      children: List.generate(widget.board[0].length, (col) {
                        return Expanded(
                          child: Center(
                            child: Text(
                              widget.colHints[col].join('\n'),
                              style: theme.textTheme.labelSmall?.copyWith(fontSize: 8),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  ...List.generate(widget.board.length, (row) {
                    return Row(
                      children: List.generate(widget.board[row].length, (col) {
                        final cellState = widget.board[row][col];
                        Color backgroundColor;

                        switch (cellState) {
                          case CellState.filled:
                            backgroundColor = Colors.black;
                          case CellState.marked:
                            backgroundColor = Colors.white;
                          case CellState.empty:
                            backgroundColor = Colors.white;
                        }

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _applyCellAction(row, col),
                            child: Container(
                              height: cellSize,
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                border: Border.all(color: theme.colorScheme.outline),
                              ),
                              child: cellState == CellState.marked
                                  ? Center(
                                      child: Text(
                                        '✕',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: cellSize * 0.6,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
