import 'game_state.dart';

class TwentyFortyEightGameState {
  const TwentyFortyEightGameState({
    required this.board,
    required this.score,
    required this.moves,
    required this.difficulty,
    required this.elapsedSeconds,
  });

  final List<List<int>> board; // 4x4 grid with tile values (0 = empty)
  final int score;
  final List<Move> moves;
  final GameDifficulty difficulty;
  final int elapsedSeconds;

  TwentyFortyEightGameState copyWith({
    List<List<int>>? board,
    int? score,
    List<Move>? moves,
    GameDifficulty? difficulty,
    int? elapsedSeconds,
  }) {
    return TwentyFortyEightGameState(
      board: board ?? this.board,
      score: score ?? this.score,
      moves: moves ?? this.moves,
      difficulty: difficulty ?? this.difficulty,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }

  String get formattedTime {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool isGameOver() {
    // Check if no empty cells and no valid moves
    return board.every((row) => row.every((cell) => cell != 0));
  }
}

// Sample 2048 board (4x4)
final sampleTwentyFortyEightBoard = [
  [2, 0, 0, 0],
  [0, 0, 0, 0],
  [0, 0, 0, 0],
  [0, 0, 0, 2],
];
