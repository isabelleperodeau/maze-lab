import 'game_state.dart';

enum CellState { empty, filled, marked }

class NonogramGameState {
  const NonogramGameState({
    required this.board,
    required this.solution,
    required this.rowHints,
    required this.colHints,
    required this.moves,
    required this.difficulty,
    required this.elapsedSeconds,
    this.showValidation = false,
    this.isSolved = false,
  });

  final List<List<CellState>> board;
  final List<List<int>> solution;
  final List<List<int>> rowHints;
  final List<List<int>> colHints;
  final List<Move> moves;
  final GameDifficulty difficulty;
  final int elapsedSeconds;
  final bool showValidation;
  final bool isSolved;

  NonogramGameState copyWith({
    List<List<CellState>>? board,
    List<List<int>>? solution,
    List<List<int>>? rowHints,
    List<List<int>>? colHints,
    List<Move>? moves,
    GameDifficulty? difficulty,
    int? elapsedSeconds,
    bool? showValidation,
    bool? isSolved,
  }) {
    return NonogramGameState(
      board: board ?? this.board,
      solution: solution ?? this.solution,
      rowHints: rowHints ?? this.rowHints,
      colHints: colHints ?? this.colHints,
      moves: moves ?? this.moves,
      difficulty: difficulty ?? this.difficulty,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      showValidation: showValidation ?? this.showValidation,
      isSolved: isSolved ?? this.isSolved,
    );
  }

  String get formattedTime {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

final sampleNonogramSolution = [
  [0, 0, 1, 1, 1, 1, 0, 0, 0, 0],
  [0, 1, 1, 1, 1, 1, 1, 0, 0, 0],
  [1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
  [0, 1, 1, 1, 1, 1, 1, 1, 0, 0],
  [0, 0, 1, 1, 1, 1, 1, 0, 0, 0],
  [0, 0, 0, 1, 1, 1, 0, 0, 0, 0],
];

List<List<int>> _generateHints(List<List<int>> solution, bool isRow) {
  final hints = <List<int>>[];
  final lines = isRow ? solution : _transposeMatrix(solution);

  for (final line in lines) {
    final lineHints = <int>[];
    int count = 0;
    for (final cell in line) {
      if (cell == 1) {
        count++;
      } else if (count > 0) {
        lineHints.add(count);
        count = 0;
      }
    }
    if (count > 0) {
      lineHints.add(count);
    }
    hints.add(lineHints.isEmpty ? [0] : lineHints);
  }

  return hints;
}

List<List<int>> _transposeMatrix(List<List<int>> matrix) {
  final result = <List<int>>[];
  for (int i = 0; i < matrix[0].length; i++) {
    final row = <int>[];
    for (int j = 0; j < matrix.length; j++) {
      row.add(matrix[j][i]);
    }
    result.add(row);
  }
  return result;
}

final sampleNonogramRowHints = _generateHints(sampleNonogramSolution, true);
final sampleNonogramColHints = _generateHints(sampleNonogramSolution, false);
