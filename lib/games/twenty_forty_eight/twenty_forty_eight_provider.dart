import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/twenty_forty_eight_state.dart';
import '../models/game_state.dart';

class TwentyFortyEightGameNotifier extends Notifier<TwentyFortyEightGameState> {
  Timer? _timer;

  @override
  TwentyFortyEightGameState build() {
    final initialBoard = sampleTwentyFortyEightBoard.map((row) => [...row]).toList();
    return TwentyFortyEightGameState(
      board: initialBoard,
      score: 0,
      moves: [],
      difficulty: GameDifficulty.easy,
      elapsedSeconds: 0,
    );
  }

  void startGame(GameDifficulty difficulty) {
    _stopTimer();
    final initialBoard = sampleTwentyFortyEightBoard.map((row) => [...row]).toList();

    state = TwentyFortyEightGameState(
      board: initialBoard,
      score: 0,
      moves: [],
      difficulty: difficulty,
      elapsedSeconds: 0,
    );

    _startTimer();
  }

  void moveLeft() {
    // Placeholder for merge left logic
  }

  void moveRight() {
    // Placeholder for merge right logic
  }

  void moveUp() {
    // Placeholder for merge up logic
  }

  void moveDown() {
    // Placeholder for merge down logic
  }

  void undo() {
    if (state.moves.isEmpty) return;

    state = state.copyWith(
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

final twentyFortyEightGameProvider =
    NotifierProvider<TwentyFortyEightGameNotifier, TwentyFortyEightGameState>(() {
  return TwentyFortyEightGameNotifier();
});
