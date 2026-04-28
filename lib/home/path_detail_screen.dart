import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_state.dart';
import '../providers/path_play_provider.dart';
import 'path_play/puzzle_pebble_list.dart';

class PathDetailScreen extends ConsumerStatefulWidget {
  const PathDetailScreen({
    super.key,
    required this.pathId,
  });

  final String pathId;

  @override
  ConsumerState<PathDetailScreen> createState() => _PathDetailScreenState();
}

class _PathDetailScreenState extends ConsumerState<PathDetailScreen> {
  late int _intPathId;

  @override
  void initState() {
    super.initState();
    _intPathId = int.parse(widget.pathId);
    Future.microtask(() => _loadPath());
  }

  Future<void> _loadPath() async {
    final auth = ref.read(authStateProvider);
    if (auth != null) {
      await ref.read(pathPlayProvider.notifier).loadPath(_intPathId, auth.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pathPlayProvider);
    final theme = Theme.of(context);

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Path...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${state.error}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPath,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(state.pathName),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Header with timer and progress
          SliverToBoxAdapter(
            child: _buildHeader(state, theme),
          ),

          // Pebbles grid
          SliverToBoxAdapter(
            child: PuzzlePebbleList(
              puzzles: state.puzzles,
              currentPuzzleIndex: state.currentPuzzleIndex,
              onPuzzleTap: (index) {
                final puzzle = state.puzzles[index];
                _playPuzzle(puzzle, index);
              },
            ),
          ),

          // Completion message
          if (state.isPathComplete)
            SliverToBoxAdapter(
              child: _buildCompletionMessage(theme),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
      floatingActionButton: state.canPlayCurrentPuzzle
          ? FloatingActionButton.extended(
              onPressed: () {
                final puzzle = state.currentPuzzle;
                if (puzzle != null) {
                  _playPuzzle(puzzle, state.currentPuzzleIndex);
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: Text(state.isPathComplete ? 'View Result' : 'Continue'),
            )
          : null,
    );
  }

  Widget _buildHeader(PathPlayState state, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Total Time: ${state.formattedTime}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: theme.textTheme.titleMedium,
              ),
              Text(
                '${state.completedCount} of ${state.puzzles.length} puzzles',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.puzzles.isEmpty
                  ? 0
                  : state.completedCount / state.puzzles.length,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionMessage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        color: theme.colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.celebration,
                color: theme.colorScheme.primary,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                '🎉 Challenge Complete!',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'All puzzles solved!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _playPuzzle(PuzzleInfo puzzle, int index) {
    context.push(
      '/game/${puzzle.type}/medium?pathId=$_intPathId&puzzleIndex=$index&puzzleId=${puzzle.id}',
    );
  }
}
