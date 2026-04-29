import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nonogram_state.dart';
import '../models/game_state.dart';
import '../../services/puzzle_service.dart';

class NonogramGameNotifier extends Notifier<NonogramGameState> {
  Timer? _timer;
  late List<List<int>> _solution;

  @override
  NonogramGameState build() {
    return _initializeGame(GameDifficulty.easy);
  }

  Future<void> startGame(GameDifficulty difficulty) async {
    _stopTimer();
    try {
      final puzzle = await PuzzleService.getRandomPuzzle('nonogram', difficulty.name);

      // Parse solution grid
      final gridData = puzzle.solution['grid'] as List;
      final solutionGrid = gridData.map((row) => (row as List).cast<int>().toList()).toList();

      // Parse row hints
      final rowHintsData = puzzle.data['row_hints'] as List;
      final rowHints = rowHintsData.map((h) => (h as List).cast<int>().toList()).toList();

      // Parse column hints
      final colHintsData = puzzle.data['col_hints'] as List;
      final colHints = colHintsData.map((h) => (h as List).cast<int>().toList()).toList();

      _solution = solutionGrid.map((row) => [...row]).toList();

      final initialBoard = List.generate(
        _solution.length,
        (_) => List.filled(_solution[0].length, CellState.empty),
      );

      state = NonogramGameState(
        board: initialBoard,
        solution: _solution,
        rowHints: rowHints,
        colHints: colHints,
        moves: [],
        difficulty: difficulty,
        elapsedSeconds: 0,
      );
      _startTimer();
    } catch (e) {
      // Fallback to sample data on error
      state = _initializeGameWithSampleData(difficulty);
      _startTimer();
    }
  }

  NonogramGameState _initializeGame(GameDifficulty difficulty) {
    _solution = sampleNonogramSolution.map((row) => [...row]).toList();

    final initialBoard = List.generate(
      _solution.length,
      (_) => List.filled(_solution[0].length, CellState.empty),
    );

    return NonogramGameState(
      board: initialBoard,
      solution: _solution,
      rowHints: sampleNonogramRowHints,
      colHints: sampleNonogramColHints,
      moves: [],
      difficulty: difficulty,
      elapsedSeconds: 0,
    );
  }

  NonogramGameState _initializeGameWithSampleData(GameDifficulty difficulty) {
    return _initializeGame(difficulty);
  }

  void setCellState(int row, int col, CellState newState) {
    final newBoard = state.board.map((r) => [...r]).toList();
    newBoard[row][col] = newState;

    final newMove = Move(row: row, col: col, value: newState.index);
    final newMoves = [...state.moves, newMove];

    bool puzzleSolved = _isSolvedWithBoard(newBoard);

    if (puzzleSolved) {
      _stopTimer();
    }

    state = state.copyWith(
      board: newBoard,
      moves: newMoves,
      isSolved: puzzleSolved,
    );
  }

  void undo() {
    if (state.moves.isEmpty) return;

    final lastMove = state.moves.last;
    final newBoard = state.board.map((r) => [...r]).toList();
    newBoard[lastMove.row][lastMove.col] = CellState.empty;

    state = state.copyWith(
      board: newBoard,
    );
  }

  bool _isSolvedWithBoard(List<List<CellState>> board) {
    for (int r = 0; r < board.length; r++) {
      for (int c = 0; c < board[r].length; c++) {
        final userCell = board[r][c];
        final solutionCell = _solution[r][c];

        final shouldBeFilled = solutionCell == 1;
        final isFilled = userCell == CellState.filled;

        if (shouldBeFilled != isFilled) {
          return false;
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

  void clearBoard() {
    final emptyBoard = List.generate(
      state.board.length,
      (_) => List.filled(state.board[0].length, CellState.empty),
    );
    state = state.copyWith(
      board: emptyBoard,
      isSolved: false,
    );
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
}

final nonogramGameProvider = NotifierProvider<NonogramGameNotifier, NonogramGameState>(() {
  return NonogramGameNotifier();
});
