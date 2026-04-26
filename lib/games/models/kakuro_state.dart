import 'game_state.dart';

enum CellValidationState { valid, invalid, incomplete, empty }

class KakuroClue {
  const KakuroClue({this.vertical, this.horizontal});

  final int? vertical;
  final int? horizontal;
}

class KakuroBlock {
  const KakuroBlock({
    required this.id,
    required this.targetSum,
    required this.cells,
    required this.isHorizontal,
  });

  final String id;
  final int targetSum;
  final List<(int, int)> cells; // list of (row, col) tuples
  final bool isHorizontal;

  int getCellCount() => cells.length;
}

class KakuroGameState {
  const KakuroGameState({
    required this.board,
    required this.clues,
    required this.blocks,
    required this.moves,
    required this.cellValidationState,
    required this.difficulty,
    required this.elapsedSeconds,
    this.showValidation = false,
    this.isSolved = false,
  });

  final List<List<int>> board;
  final List<List<KakuroClue?>> clues;
  final List<KakuroBlock> blocks;
  final List<Move> moves;
  final Map<(int, int), CellValidationState> cellValidationState;
  final GameDifficulty difficulty;
  final int elapsedSeconds;
  final bool showValidation;
  final bool isSolved;

  KakuroGameState copyWith({
    List<List<int>>? board,
    List<List<KakuroClue?>>? clues,
    List<KakuroBlock>? blocks,
    List<Move>? moves,
    Map<(int, int), CellValidationState>? cellValidationState,
    GameDifficulty? difficulty,
    int? elapsedSeconds,
    bool? showValidation,
    bool? isSolved,
  }) {
    return KakuroGameState(
      board: board ?? this.board,
      clues: clues ?? this.clues,
      blocks: blocks ?? this.blocks,
      moves: moves ?? this.moves,
      cellValidationState: cellValidationState ?? this.cellValidationState,
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

final sampleKakuroValues = [
  [
    const KakuroClue(vertical: null, horizontal: null),
    const KakuroClue(vertical: 11, horizontal: null),
    const KakuroClue(vertical: 26, horizontal: null),
    const KakuroClue(vertical: null, horizontal: null),
    const KakuroClue(vertical: null, horizontal: null),
    const KakuroClue(vertical: 22, horizontal: null),
    const KakuroClue(vertical: 16, horizontal: null),
  ],
  [
    const KakuroClue(vertical: null, horizontal: 16),
    9,
    7,
    const KakuroClue(vertical: null, horizontal: null),
    const KakuroClue(vertical: 7, horizontal: 9),
    2,
    7,
  ],
  [
    const KakuroClue(vertical: null, horizontal: 3),
    2,
    1,
    const KakuroClue(vertical: 7, horizontal: 12),
    2,
    1,
    9,
  ],
  [
    const KakuroClue(vertical: null, horizontal: null),
    const KakuroClue(vertical: null, horizontal: 11),
    3,
    2,
    1,
    5,
    const KakuroClue(vertical: null, horizontal: null),
  ],
  [
    const KakuroClue(vertical: null, horizontal: null),
    const KakuroClue(vertical: 10, horizontal: 10),
    2,
    1,
    4,
    3,
    const KakuroClue(vertical: 12, horizontal: null),
  ],
  [
    const KakuroClue(vertical: null, horizontal: 10),
    1,
    5,
    4,
    const KakuroClue(vertical: null, horizontal: 16),
    7,
    9,
  ],
  [
    const KakuroClue(vertical: null, horizontal: 17),
    9,
    8,
    const KakuroClue(vertical: null, horizontal: null),
    const KakuroClue(vertical: null, horizontal: 7),
    4,
    3,
  ],
];
