# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project: maze-lab

A logic puzzle platform built with Flutter.

**Concept:**
- Collection of mini-games: Sudoku, Kakuro, Nonogram, 2048, more added over time
- Players solve mini-games to progress to the next level
- Custom paths: users pick which mini-games go into their path
- Social/competitive: publish a path as a challenge (public or friends-only) with leaderboards
- Expandable: architecture should make adding new puzzle types straightforward

**Tech stack:**
- Frontend/app: Flutter (Dart) — targets web, iOS, Android, desktop from one codebase
- Backend: TBD. FastAPI is the leading candidate (owner is a Python dev).

## Working with the owner

- Primary language: Python. Comfortable in JS, PHP, C, C++. Basic Rust.
- Game dev background with Sprite3.
- **New to Flutter/Dart** — frame explanations using Python or JS analogies where helpful. Assume strong general programming fundamentals; don't over-explain language-agnostic concepts.

## Conventions

- Keep the puzzle-game architecture pluggable: each mini-game should be self-contained so new ones can be added without touching unrelated code.
- When introducing Flutter idioms (widgets, state management, build context, etc.) for the first time, briefly note the analogous concept from Python/JS rather than assuming familiarity.
- Suggested state management: **Riverpod** (`flutter_riverpod`). Not yet adopted in code — confirm before introducing.

## Client-side implementation: Games (COMPLETED)

Three games are fully implemented with complete mechanics, validation, and UI:

### Architecture
- **State management**: Riverpod (`flutter_riverpod` package) using `NotifierProvider` pattern
- **Difficulty levels**: Enum `GameDifficulty { easy, medium, hard, expert }`
- **Game lifecycle**: Each game has a screen (UI layer) and provider (logic layer)
  - Screen is `ConsumerStatefulWidget` that watches game state and renders UI
  - Provider is `Notifier<GameState>` that manages game logic, validation, and timer
- **File structure**:
  ```
  lib/games/
  ├── models/
  │   ├── game_state.dart              # Shared enums (GameDifficulty, Move)
  │   ├── kakuro_state.dart            # KakuroGameState class
  │   ├── nonogram_state.dart          # NonogramGameState, CellState enum
  │   └── game_2048_state.dart         # Game2048State class
  ├── kakuro/
  │   ├── kakuro_screen.dart           # UI layer
  │   └── kakuro_provider.dart         # Logic layer (NotifierProvider)
  ├── nonogram/
  │   ├── nonogram_screen.dart         # UI layer
  │   └── nonogram_provider.dart       # Logic layer
  └── twenty_forty_eight/
      ├── twenty_forty_eight_screen.dart # UI layer
      └── 2048/game_2048_provider.dart   # Logic layer
  ```

### Game 1: Kakuro (7x7 grid puzzle)

**Puzzle structure:**
- Black cells (non-playable)
- Clue cells with horizontal indice (target sum) and/or vertical indice
- Answer cells (1-9 only)
- Current state stored as single 7x7 array with mixed types: `int 0 = black, KakuroClue = clue cell, int 1-9 = answer`

**Game mechanics:**
- Player taps cell → opens modal to enter digit (1-9) or clear
- Toggle button shows/hides real-time validation colors
- Drag applies the selected value directly (no cycling)
- Click applies selected value; cycles if cell already has that value OR click within 1 second of previous click

**Validation rules:**
- Each horizontal block must sum exactly to its horizontal indice
- Each vertical block must sum exactly to its vertical indice
- No digit repeats within a block
- Real-time color feedback:
  - Green: cell valid (all blocks containing it are correct)
  - Red: cell invalid (violates sum or repeat in at least one block)
  - Yellow: incomplete (blocks not yet summed correctly)

**Game state** (`KakuroGameState`):
```dart
board              // 7x7 mixed-type array (black/clue/answer)
solution           // 7x7 answer grid for checking
moves              // List<Move> - history of all player actions
difficulty         // GameDifficulty enum
elapsedSeconds     // Int - elapsed time
isSolved           // Bool - puzzle complete and all blocks valid
showValidation     // Bool - toggle for showing colors
```

**Completion**: `isSolved` becomes true when board matches solution exactly (auto-detected).

---

### Game 2: Nonogram (10x10 grid puzzle)

**Puzzle structure:**
- Grid cells can be empty, filled (black), or marked (red X for "no" clues)
- Row hints: sequences of consecutive filled cells for each row
- Column hints: sequences of consecutive filled cells for each column
- Solution is binary (filled or not); marked cells are UI-only

**Game mechanics:**
- Two input modes: "Noir" (filled) and "Marquer" (marked)
- Click: applies selected mode; cycles if cell already has that value OR within 1 second of previous
- Drag: applies selected mode directly to all cells touched (no cycling)
- Cycle sequence (starting from Noir): filled → marked → empty → filled
- Undo: empties last clicked cell (move stays in history)
- Clear: empties entire board (move count preserved)

**Game state** (`NonogramGameState`):
```dart
board              // 10x10 grid of CellState enum (empty/filled/marked)
solution           // 10x10 binary grid (1 = filled, 0 = empty)
rowHints           // List<List<int>> - hint sequences per row
colHints           // List<List<int>> - hint sequences per column
moves              // List<Move> - history
difficulty         // GameDifficulty
elapsedSeconds     // Int
isSolved           // Bool - board matches solution exactly
showValidation     // Bool - validation toggle (currently unused)
```

**Completion**: `isSolved` becomes true when all cells match solution (marked/empty cells ignored, only filled vs empty checked).

---

### Game 3: 2048 (4x4 tile merge game)

**Puzzle structure:**
- 4x4 grid of tiles (value is power of 2, or 0 for empty)
- Spawn: new tile (90% = 2, 10% = 4) appears in random empty cell after each valid move
- Movement: slide all tiles in direction, merge adjacent equal tiles once per direction

**Game mechanics:**
- Arrow buttons (up/down/left/right) to move tiles
- Tile merge logic: consolidate zeros, merge adjacent equal values once, pad with zeros
- Move valid only if board changes (no-op moves are ignored)
- Auto-spawn new tile after valid move
- Score accumulates from merges (merged tile value added to score)

**Win/loss conditions:**
- **Win**: Any cell contains value ≥ 2048 → show success dialog
- **Loss**: All cells filled AND no adjacent equal tiles exist AND no 2048 → show game over dialog

**Game state** (`Game2048State`):
```dart
board              // 4x4 grid of ints (0-2048+)
score              // Int - accumulated points from merges
moves              // List<Move> - history
difficulty         // GameDifficulty (cosmetic only)
elapsedSeconds     // Int
isSolved           // Bool - 2048 reached
isGameOver         // Bool - no moves possible and no 2048
```

**Completion**: `isSolved=true` if any tile ≥ 2048; `isGameOver=true` if board full + no moves possible + no 2048.

---

### Shared patterns across all games

**Timer management:**
- `_startTimer()`: tick once per second, increment `elapsedSeconds`
- `_stopTimer()`: cancel timer (called on win/loss)
- `formattedTime` getter: converts seconds to "MM:SS" string

**Move tracking:**
```dart
class Move {
  final int row;
  final int col;
  final dynamic value;  // score (2048), state index (nonogram), etc.
}
```

**Difficulty parameter:**
- Passed from home screen as String (e.g., "easy", "medium")
- Converted to enum in `initState()` via `GameDifficulty.values.firstWhere()`
- Used to seed initial puzzle complexity (if implemented)

---

## Backend requirements (API contracts)

### Endpoints needed

1. **GET /games/{gameType}/puzzles**
   - Query params: `difficulty` (easy/medium/hard/expert), `count` (optional, default 1)
   - Returns: `List<Puzzle>`
   - Example response for Kakuro:
     ```json
     {
       "puzzles": [{
         "id": "kakuro_001",
         "type": "kakuro",
         "difficulty": "easy",
         "board": [/* 7x7 serialized puzzle */],
         "solution": [/* 7x7 answer grid */]
       }]
     }
     ```

2. **POST /games/{gameId}/submit**
   - Body: 
     ```json
     {
       "userId": "...",
       "finalBoard": [/* grid state */],
       "moves": [{"row": 0, "col": 1, "value": 5}, ...],
       "elapsedSeconds": 42,
       "isSolved": true
     }
     ```
   - Returns: `{ "valid": true, "score": 1000, "leaderboardRank": 5 }`

3. **GET /games/{gameType}/solution/{puzzleId}** (optional, for cheating/hints)
   - Returns the solution for a puzzle

### Data serialization

**Board formats:**
- **Kakuro**: 7x7 array with mixed types. Serialize as:
  ```json
  [
    [0, 0, {"h": 11, "v": null}, 1, 2, ...],
    ...
  ]
  ```
  Where `0 = black`, `{"h": N, "v": N} = clue`, `1-9 = answer`.

- **Nonogram**: 10x10 array of integers (0 = empty, 1 = filled, 2 = marked)

- **2048**: 4x4 array of integers (0-2048+)

### Leaderboard data
- Game type, difficulty, user ID, time, date, whether solution is valid
- Rank by time (ascending) for same score/difficulty

---

## Current work: in-app landing page (home screen)

Design agreed upon, not yet implemented. Sections top-to-bottom:

1. **AppBar** — `maze-lab` wordmark, profile avatar + notifications on the right.
2. **Continue card** — current path with progress bar and "Continue" CTA. Empty state: "Start your first path".
3. **Quick play row** — horizontal scroll of game tiles (Sudoku, Kakuro, Nonogram, 2048…); tap = single random puzzle of that type.
4. **Friend challenges** — published paths from friends, avatar + name + best time.
5. **Featured / public paths** — curated/trending, with leaderboard preview.
6. **BottomNavigationBar** — Home · Paths · Friends · Profile.

**Build order:**
1. `flutter create maze_lab` (snake_case for Dart package names).
2. Add `flutter_riverpod` to `pubspec.yaml`.
3. Replace default counter in `lib/main.dart` with a `HomeScreen` skeleton (Scaffold + AppBar + empty body).
4. Confirm boot with `flutter run -d chrome` (or iOS sim).
5. Add sections one at a time, with hardcoded stub data (no backend yet).
