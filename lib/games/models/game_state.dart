enum GameDifficulty { easy, medium, hard }

class Move {
  const Move({
    required this.row,
    required this.col,
    required this.value,
  });

  final int row;
  final int col;
  final int value;
}

class SudokuGameState {
  const SudokuGameState({
    required this.board,
    required this.solution,
    required this.moves,
    required this.difficulty,
    required this.elapsedSeconds,
  });

  final List<List<int>> board; // 0 = empty
  final List<List<int>> solution; // complete puzzle for validation
  final List<Move> moves; // undo history
  final GameDifficulty difficulty;
  final int elapsedSeconds;

  SudokuGameState copyWith({
    List<List<int>>? board,
    List<List<int>>? solution,
    List<Move>? moves,
    GameDifficulty? difficulty,
    int? elapsedSeconds,
  }) {
    return SudokuGameState(
      board: board ?? this.board,
      solution: solution ?? this.solution,
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

  bool isBoardFull() => board.every((row) => row.every((cell) => cell != 0));

  bool isValid() => isBoardFull() && board.toString() == solution.toString();
}

// Sample Sudoku puzzle (easy)
final sampleEasyPuzzle = [
  [5, 3, 0, 0, 7, 0, 0, 0, 0],
  [6, 0, 0, 1, 9, 5, 0, 0, 0],
  [0, 9, 8, 0, 0, 0, 0, 6, 0],
  [8, 0, 0, 0, 6, 0, 0, 0, 3],
  [4, 0, 0, 8, 0, 3, 0, 0, 1],
  [7, 0, 0, 0, 2, 0, 0, 0, 6],
  [0, 6, 0, 0, 0, 0, 2, 8, 0],
  [0, 0, 0, 4, 1, 9, 0, 0, 5],
  [0, 0, 0, 0, 8, 0, 0, 7, 9],
];

final sampleSolution = [
  [5, 3, 4, 6, 7, 8, 9, 1, 2],
  [6, 7, 2, 1, 9, 5, 3, 4, 8],
  [1, 9, 8, 3, 4, 2, 5, 6, 7],
  [8, 5, 9, 7, 6, 1, 4, 2, 3],
  [4, 2, 6, 8, 5, 3, 7, 9, 1],
  [7, 1, 3, 9, 2, 4, 8, 5, 6],
  [9, 6, 1, 5, 3, 7, 2, 8, 4],
  [2, 8, 7, 4, 1, 9, 6, 3, 5],
  [3, 4, 5, 2, 8, 6, 1, 7, 9],
];
