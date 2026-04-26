import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kakuro_state.dart';
import '../models/game_state.dart';

class KakuroGameNotifier extends Notifier<KakuroGameState> {
  Timer? _timer;
  late List<List<dynamic>> _solutionGrid;

  @override
  KakuroGameState build() {
    return _initializeGame(GameDifficulty.easy);
  }

  void startGame(GameDifficulty difficulty) {
    _stopTimer();
    state = _initializeGame(difficulty);
    _startTimer();
  }

  KakuroGameState _initializeGame(GameDifficulty difficulty) {
    _solutionGrid = sampleKakuroValues.map((row) => [...row]).toList();

    // Create board from sampleKakuroValues: replace answer values with 0 (empty)
    final initialBoard = <List<int>>[];
    for (int r = 0; r < _solutionGrid.length; r++) {
      final row = <int>[];
      for (int c = 0; c < _solutionGrid[r].length; c++) {
        final cell = _solutionGrid[r][c];
        if (cell == 0) {
          row.add(-1); // Black cell
        } else if (cell is KakuroClue) {
          row.add(-1); // Clue cell (blocked)
        } else if (cell is int) {
          row.add(0); // Answer cell (initially empty)
        }
      }
      initialBoard.add(row);
    }

    // Extract clues from solution grid
    final cluesGrid = <List<KakuroClue?>>[];
    for (int r = 0; r < _solutionGrid.length; r++) {
      final row = <KakuroClue?>[];
      for (int c = 0; c < _solutionGrid[r].length; c++) {
        final cell = _solutionGrid[r][c];
        if (cell is KakuroClue) {
          row.add(cell);
        } else {
          row.add(null);
        }
      }
      cluesGrid.add(row);
    }

    final blocks = _createBlocks(cluesGrid);
    final validationState = _validateBoard(initialBoard, blocks);

    return KakuroGameState(
      board: initialBoard,
      clues: cluesGrid,
      blocks: blocks,
      moves: [],
      cellValidationState: validationState,
      difficulty: difficulty,
      elapsedSeconds: 0,
    );
  }

  void setCell(int row, int col, int value) {
    if (state.board[row][col] < 0) return;

    final newBoard = state.board.map((r) => [...r]).toList();
    newBoard[row][col] = value;
    final newValidationState = _validateBoard(newBoard, state.blocks);

    final newMove = Move(row: row, col: col, value: value);
    final newMoves = [...state.moves, newMove];

    // Check if puzzle is now solved
    bool puzzleSolved = _isSolvedWithBoard(newBoard);

    if (puzzleSolved) {
      _stopTimer();
    }

    state = state.copyWith(
      board: newBoard,
      moves: newMoves,
      cellValidationState: newValidationState,
      isSolved: puzzleSolved,
    );
  }

  void undo() {
    if (state.moves.isEmpty) return;

    final lastMove = state.moves.last;
    final newBoard = state.board.map((r) => [...r]).toList();
    newBoard[lastMove.row][lastMove.col] = 0;
    final newValidationState = _validateBoard(newBoard, state.blocks);

    state = state.copyWith(
      board: newBoard,
      moves: state.moves.sublist(0, state.moves.length - 1),
      cellValidationState: newValidationState,
    );
  }

  List<KakuroBlock> _createBlocks(List<List<KakuroClue?>> clues) {
    final blocks = <KakuroBlock>[];
    int blockId = 0;

    for (int r = 0; r < clues.length; r++) {
      for (int c = 0; c < clues[r].length; c++) {
        final clue = clues[r][c];
        if (clue == null) continue;

        if (clue.horizontal != null) {
          final cells = <(int, int)>[];
          for (int cc = c + 1; cc < clues[r].length; cc++) {
            if (clues[r][cc] != null) break;
            cells.add((r, cc));
          }
          if (cells.isNotEmpty) {
            blocks.add(KakuroBlock(
              id: 'h_${blockId++}',
              targetSum: clue.horizontal!,
              cells: cells,
              isHorizontal: true,
            ));
          }
        }

        if (clue.vertical != null) {
          final cells = <(int, int)>[];
          for (int rr = r + 1; rr < clues.length; rr++) {
            if (clues[rr][c] != null) break;
            cells.add((rr, c));
          }
          if (cells.isNotEmpty) {
            blocks.add(KakuroBlock(
              id: 'v_${blockId++}',
              targetSum: clue.vertical!,
              cells: cells,
              isHorizontal: false,
            ));
          }
        }
      }
    }

    return blocks;
  }

  Map<(int, int), CellValidationState> _validateBoard(
    List<List<int>> board,
    List<KakuroBlock> blocks,
  ) {
    final validationState = <(int, int), CellValidationState>{};

    for (final block in blocks) {
      final blockValues = block.cells.map((cell) => board[cell.$1][cell.$2]).toList();
      final hasEmpty = blockValues.contains(0);
      final sum = blockValues.where((v) => v != 0).fold(0, (a, b) => a + b);
      final hasDuplicate = blockValues.where((v) => v != 0).length !=
          blockValues.where((v) => v != 0).toSet().length;

      CellValidationState state;
      if (hasEmpty) {
        state = CellValidationState.incomplete;
      } else if (hasDuplicate || sum != block.targetSum) {
        state = CellValidationState.invalid;
      } else {
        state = CellValidationState.valid;
      }

      for (final cell in block.cells) {
        final existing = validationState[cell] ?? CellValidationState.empty;
        if (existing == CellValidationState.invalid || state == CellValidationState.invalid) {
          validationState[cell] = CellValidationState.invalid;
        } else if (existing == CellValidationState.incomplete || state == CellValidationState.incomplete) {
          validationState[cell] = CellValidationState.incomplete;
        } else if (state == CellValidationState.valid) {
          validationState[cell] = CellValidationState.valid;
        }
      }
    }

    return validationState;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  bool _isSolvedWithBoard(List<List<int>> board) {
    // Compare user's board with solution grid
    for (int r = 0; r < board.length; r++) {
      for (int c = 0; c < board[r].length; c++) {
        final userValue = board[r][c];
        final solutionCell = _solutionGrid[r][c];

        // Answer cells (int values in solution): must match exactly
        if (solutionCell is int && solutionCell != 0) {
          if (userValue != solutionCell) {
            return false;
          }
        }
        // Black cells and clue cells: user should not fill them
        else if (solutionCell == 0 || solutionCell is KakuroClue) {
          if (userValue != -1) {
            return false;
          }
        }
      }
    }

    return true;
  }

  bool isSolved() {
    return _isSolvedWithBoard(state.board);
  }

  void toggleValidation() {
    state = state.copyWith(showValidation: !state.showValidation);
  }
}

final kakuroGameProvider = NotifierProvider<KakuroGameNotifier, KakuroGameState>(() {
  return KakuroGameNotifier();
});
