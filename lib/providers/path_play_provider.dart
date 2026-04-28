import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/path_service.dart';
import '../services/completion_service.dart';

class PuzzleInfo {
  final int id;
  final String type;
  final String difficulty;
  final int order;
  final bool isCompleted;

  const PuzzleInfo({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.order,
    required this.isCompleted,
  });

  PuzzleInfo copyWith({bool? isCompleted}) {
    return PuzzleInfo(
      id: id,
      type: type,
      difficulty: difficulty,
      order: order,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class PathPlayState {
  final int pathId;
  final String pathName;
  final List<PuzzleInfo> puzzles;
  final int currentPuzzleIndex;
  final int globalElapsedSeconds;
  final bool isPathComplete;
  final bool isLoading;
  final String? error;

  const PathPlayState({
    required this.pathId,
    required this.pathName,
    required this.puzzles,
    this.currentPuzzleIndex = 0,
    this.globalElapsedSeconds = 0,
    this.isPathComplete = false,
    this.isLoading = false,
    this.error,
  });

  PathPlayState copyWith({
    int? pathId,
    String? pathName,
    List<PuzzleInfo>? puzzles,
    int? currentPuzzleIndex,
    int? globalElapsedSeconds,
    bool? isPathComplete,
    bool? isLoading,
    String? error,
  }) {
    return PathPlayState(
      pathId: pathId ?? this.pathId,
      pathName: pathName ?? this.pathName,
      puzzles: puzzles ?? this.puzzles,
      currentPuzzleIndex: currentPuzzleIndex ?? this.currentPuzzleIndex,
      globalElapsedSeconds: globalElapsedSeconds ?? this.globalElapsedSeconds,
      isPathComplete: isPathComplete ?? this.isPathComplete,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  String get formattedTime {
    final minutes = globalElapsedSeconds ~/ 60;
    final seconds = globalElapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int get completedCount => puzzles.where((p) => p.isCompleted).length;
  bool get canPlayCurrentPuzzle => currentPuzzleIndex < puzzles.length;
  PuzzleInfo? get currentPuzzle =>
      canPlayCurrentPuzzle ? puzzles[currentPuzzleIndex] : null;
}

class PathPlayNotifier extends Notifier<PathPlayState> {
  @override
  PathPlayState build() => PathPlayState(
    pathId: 0,
    pathName: '',
    puzzles: [],
  );

  Future<void> loadPath(int pathId, String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final path = await PathService.getPath(pathId);

      final completions = await CompletionService.getUserPathCompletions(
        pathId,
        userId,
      );

      final completedPuzzleIds = completions.map((c) => c.puzzleId).toSet();

      int totalTime = completions.fold<int>(
        0,
        (sum, c) => sum + (c.timeTaken ?? 0),
      );

      final puzzleInfos = path.puzzles.asMap().entries.map((entry) {
        final index = entry.key;
        final puzzle = entry.value;
        return PuzzleInfo(
          id: puzzle.id,
          type: puzzle.type,
          difficulty: puzzle.difficulty,
          order: index + 1,
          isCompleted: completedPuzzleIds.contains(puzzle.id),
        );
      }).toList();

      int currentIndex = puzzleInfos.indexWhere((p) => !p.isCompleted);
      if (currentIndex == -1) {
        currentIndex = puzzleInfos.length - 1;
      }

      state = state.copyWith(
        pathId: pathId,
        pathName: path.name,
        puzzles: puzzleInfos,
        currentPuzzleIndex: currentIndex,
        globalElapsedSeconds: totalTime,
        isPathComplete: puzzleInfos.every((p) => p.isCompleted),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> markPuzzleComplete(int puzzleIndex, int timeTaken) async {
    if (puzzleIndex < 0 || puzzleIndex >= state.puzzles.length) return;

    try {
      final puzzle = state.puzzles[puzzleIndex];

      await CompletionService.recordCompletion(
        pathId: state.pathId,
        puzzleId: puzzle.id,
        timeTaken: timeTaken,
      );

      final updatedPuzzles = state.puzzles.map((p) {
        return p.order - 1 == puzzleIndex ? p.copyWith(isCompleted: true) : p;
      }).toList();

      int nextIndex = updatedPuzzles.indexWhere((p) => !p.isCompleted);
      if (nextIndex == -1) {
        nextIndex = updatedPuzzles.length - 1;
      }

      final isComplete = updatedPuzzles.every((p) => p.isCompleted);

      state = state.copyWith(
        puzzles: updatedPuzzles,
        currentPuzzleIndex: nextIndex,
        globalElapsedSeconds: state.globalElapsedSeconds + timeTaken,
        isPathComplete: isComplete,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void reset() {
    state = PathPlayState(
      pathId: 0,
      pathName: '',
      puzzles: [],
    );
  }
}

final pathPlayProvider =
    NotifierProvider<PathPlayNotifier, PathPlayState>(() {
  return PathPlayNotifier();
});
