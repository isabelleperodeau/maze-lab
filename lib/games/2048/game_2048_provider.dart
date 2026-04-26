import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_2048_state.dart';
import '../models/game_state.dart';

enum MoveDirection { up, down, left, right }

class Game2048Notifier extends Notifier<Game2048State> {
  Timer? _timer;
  final Random _random = Random();

  @override
  Game2048State build() {
    return _initializeGame(GameDifficulty.easy);
  }

  void startGame(GameDifficulty difficulty) {
    _stopTimer();
    state = _initializeGame(difficulty);
    _startTimer();
  }

  Game2048State _initializeGame(GameDifficulty difficulty) {
    final board = List.generate(4, (_) => List.filled(4, 0));
    _addNewTile(board);
    _addNewTile(board);

    return Game2048State(
      board: board,
      score: 0,
      moves: [],
      difficulty: difficulty,
      elapsedSeconds: 0,
    );
  }

  void move(MoveDirection direction) {
    final newBoard = state.board.map((row) => [...row]).toList();
    int scoreGained = 0;

    switch (direction) {
      case MoveDirection.left:
        for (int i = 0; i < 4; i++) {
          final result = _mergeLine(newBoard[i]);
          scoreGained += result['score'] as int;
          newBoard[i] = (result['line'] as List<int>);
        }
      case MoveDirection.right:
        for (int i = 0; i < 4; i++) {
          newBoard[i] = newBoard[i].reversed.toList();
          final result = _mergeLine(newBoard[i]);
          scoreGained += result['score'] as int;
          newBoard[i] = (result['line'] as List<int>).reversed.toList();
        }
      case MoveDirection.up:
        for (int j = 0; j < 4; j++) {
          final column = List.generate(4, (i) => newBoard[i][j]);
          final result = _mergeLine(column);
          scoreGained += result['score'] as int;
          final resultLine = result['line'] as List<int>;
          for (int i = 0; i < 4; i++) {
            newBoard[i][j] = resultLine[i];
          }
        }
      case MoveDirection.down:
        for (int j = 0; j < 4; j++) {
          final column = List.generate(4, (i) => newBoard[3 - i][j]);
          final result = _mergeLine(column);
          scoreGained += result['score'] as int;
          final resultLine = result['line'] as List<int>;
          for (int i = 0; i < 4; i++) {
            newBoard[3 - i][j] = resultLine[i];
          }
        }
    }

    // Check if board actually changed
    bool boardChanged = false;
    for (int i = 0; i < 4 && !boardChanged; i++) {
      for (int j = 0; j < 4 && !boardChanged; j++) {
        if (state.board[i][j] != newBoard[i][j]) {
          boardChanged = true;
        }
      }
    }

    if (!boardChanged) return;

    _addNewTile(newBoard);
    final newScore = state.score + scoreGained;
    final newMove = Move(row: direction.index, col: 0, value: scoreGained);
    final newMoves = [...state.moves, newMove];

    bool isSolved = _hasReached2048(newBoard);
    bool isGameLost = _isGameOver(newBoard);

    if (isSolved || isGameLost) {
      _stopTimer();
    }

    state = state.copyWith(
      board: newBoard,
      score: newScore,
      moves: newMoves,
      isSolved: isSolved,
      isGameOver: isGameLost,
    );
  }

  Map<String, dynamic> _mergeLine(List<int> line) {
    final result = List<int>.from(line);
    bool moved = false;
    int score = 0;

    // Remove zeros
    result.removeWhere((element) => element == 0);

    // Merge adjacent equal elements
    for (int i = 0; i < result.length - 1; i++) {
      if (result[i] == result[i + 1]) {
        result[i] *= 2;
        score += result[i];
        result.removeAt(i + 1);
      }
    }

    // Add zeros at the end
    while (result.length < 4) {
      result.add(0);
    }

    moved = result != line;

    return {'line': result, 'moved': moved, 'score': score};
  }

  void _addNewTile(List<List<int>> board) {
    final emptyCells = <(int, int)>[];
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (board[i][j] == 0) {
          emptyCells.add((i, j));
        }
      }
    }

    if (emptyCells.isNotEmpty) {
      final randomCell = emptyCells[_random.nextInt(emptyCells.length)];
      final newValue = _random.nextDouble() < 0.9 ? 2 : 4;
      board[randomCell.$1][randomCell.$2] = newValue;
    }
  }

  bool _hasReached2048(List<List<int>> board) {
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (board[i][j] >= 2048) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isGameOver(List<List<int>> board) {
    // Check if there's any empty cell
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (board[i][j] == 0) {
          return false; // Game is not over if there's an empty cell
        }
      }
    }

    // Check if any moves are possible (adjacent equal tiles)
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        final current = board[i][j];
        // Check right
        if (j < 3 && current == board[i][j + 1]) {
          return false;
        }
        // Check down
        if (i < 3 && current == board[i + 1][j]) {
          return false;
        }
      }
    }

    return true; // No empty cells and no possible moves
  }


  void toggleValidation() {
    state = state.copyWith(showValidation: !state.showValidation);
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

final game2048Provider = NotifierProvider<Game2048Notifier, Game2048State>(() {
  return Game2048Notifier();
});
