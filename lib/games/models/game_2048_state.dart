import 'game_state.dart';

class Game2048State {
  const Game2048State({
    required this.board,
    required this.score,
    required this.moves,
    required this.difficulty,
    required this.elapsedSeconds,
    this.showValidation = false,
    this.isSolved = false,
    this.isGameOver = false,
  });

  final List<List<int>> board; // 0 = empty, others = 2^n values
  final int score;
  final List<Move> moves;
  final GameDifficulty difficulty;
  final int elapsedSeconds;
  final bool showValidation;
  final bool isSolved;
  final bool isGameOver;

  Game2048State copyWith({
    List<List<int>>? board,
    int? score,
    List<Move>? moves,
    GameDifficulty? difficulty,
    int? elapsedSeconds,
    bool? showValidation,
    bool? isSolved,
    bool? isGameOver,
  }) {
    return Game2048State(
      board: board ?? this.board,
      score: score ?? this.score,
      moves: moves ?? this.moves,
      difficulty: difficulty ?? this.difficulty,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      showValidation: showValidation ?? this.showValidation,
      isSolved: isSolved ?? this.isSolved,
      isGameOver: isGameOver ?? this.isGameOver,
    );
  }

  String get formattedTime {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
