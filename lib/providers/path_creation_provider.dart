import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedGame {
  final String gameType; // 'kakuro', 'nonogram', '2048', 'sudoku'
  final String difficulty; // 'easy', 'medium', 'hard'

  const SelectedGame({
    required this.gameType,
    required this.difficulty,
  });

  @override
  String toString() => 'SelectedGame(type: $gameType, difficulty: $difficulty)';
}

class PathCreationState {
  final int currentStep; // 1, 2, 3
  final String pathName;
  final String description;
  final bool isPublic;
  final String globalDifficulty; // 'easy', 'medium', 'hard'
  final List<SelectedGame> selectedGames;

  const PathCreationState({
    this.currentStep = 1,
    this.pathName = '',
    this.description = '',
    this.isPublic = false,
    this.globalDifficulty = 'easy',
    this.selectedGames = const [],
  });

  PathCreationState copyWith({
    int? currentStep,
    String? pathName,
    String? description,
    bool? isPublic,
    String? globalDifficulty,
    List<SelectedGame>? selectedGames,
  }) {
    return PathCreationState(
      currentStep: currentStep ?? this.currentStep,
      pathName: pathName ?? this.pathName,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      globalDifficulty: globalDifficulty ?? this.globalDifficulty,
      selectedGames: selectedGames ?? this.selectedGames,
    );
  }
}

class PathCreationNotifier extends Notifier<PathCreationState> {
  @override
  PathCreationState build() => const PathCreationState();

  void updatePathInfo({
    required String name,
    required String description,
    required bool isPublic,
  }) {
    state = state.copyWith(
      pathName: name,
      description: description,
      isPublic: isPublic,
    );
  }

  void setGlobalDifficulty(String difficulty) {
    state = state.copyWith(globalDifficulty: difficulty);
  }

  void addGame(String gameType, String difficulty) {
    final newGame = SelectedGame(gameType: gameType, difficulty: difficulty);
    final updatedGames = [...state.selectedGames, newGame];
    state = state.copyWith(selectedGames: updatedGames);
  }

  void removeGame(int index) {
    if (index >= 0 && index < state.selectedGames.length) {
      final updatedGames = [...state.selectedGames];
      updatedGames.removeAt(index);
      state = state.copyWith(selectedGames: updatedGames);
    }
  }

  void nextStep() {
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void reset() {
    state = const PathCreationState();
  }

  bool isStep1Valid() {
    return state.pathName.trim().length >= 3 && state.pathName.length <= 50;
  }

  bool isStep2Valid() {
    return state.selectedGames.isNotEmpty && state.selectedGames.length <= 10;
  }
}

final pathCreationProvider =
    NotifierProvider<PathCreationNotifier, PathCreationState>(() {
  return PathCreationNotifier();
});
