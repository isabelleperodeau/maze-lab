import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';

class SudokuGameNotifier extends Notifier<SudokuGameState> {
  Timer? _timer;

  @override
  SudokuGameState build() {
    // Initialize with a sample puzzle
    final initialBoard = sampleEasyPuzzle.map((row) => [...row]).toList();
    return SudokuGameState(
      board: initialBoard,
      solution: sampleSolution.map((row) => [...row]).toList(),
      moves: [],
      difficulty: GameDifficulty.easy,
      elapsedSeconds: 0,
    );
  }

  void startGame(GameDifficulty difficulty) {
    _stopTimer();

    // Deep copy the puzzle to reset it
    final initialBoard = sampleEasyPuzzle.map((row) => [...row]).toList();

    state = SudokuGameState(
      board: initialBoard,
      solution: sampleSolution.map((row) => [...row]).toList(),
      moves: [],
      difficulty: difficulty,
      elapsedSeconds: 0,
    );

    _startTimer();
  }

  void setCell(int row, int col, int value) {
    if (state.board[row][col] != 0) return; // Can't change original numbers

    final newBoard = state.board.map((r) => [...r]).toList();
    newBoard[row][col] = value;

    final newMove = Move(row: row, col: col, value: value);
    final newMoves = [...state.moves, newMove];

    state = state.copyWith(board: newBoard, moves: newMoves);
  }

  void undo() {
    if (state.moves.isEmpty) return;

    final lastMove = state.moves.last;
    final newBoard = state.board.map((r) => [...r]).toList();
    newBoard[lastMove.row][lastMove.col] = 0;

    state = state.copyWith(
      board: newBoard,
      moves: state.moves.sublist(0, state.moves.length - 1),
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

final sudokuGameProvider = NotifierProvider<SudokuGameNotifier, SudokuGameState>(() {
  return SudokuGameNotifier();
});
