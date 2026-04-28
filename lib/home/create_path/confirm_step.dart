import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/game_type.dart';
import '../../providers/path_creation_provider.dart';
import '../../services/path_service.dart';

class ConfirmStep extends ConsumerStatefulWidget {
  const ConfirmStep({super.key});

  @override
  ConsumerState<ConfirmStep> createState() => _ConfirmStepState();
}

class _ConfirmStepState extends ConsumerState<ConfirmStep> {
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pathCreationProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Your Challenge',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Step 3 of 3: Confirm and Create',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          _buildPathSummary(state, theme),
          const SizedBox(height: 32),
          _buildGamesList(state, theme),
          const SizedBox(height: 48),
          if (_isCreating)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _goBack,
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _createPath,
                    child: const Text('Create Challenge'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPathSummary(PathCreationState state, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Path Information',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    'Name:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    state.pathName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.description.isNotEmpty)
              Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Description:',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          state.description,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    'Visibility:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Icon(
                        state.isPublic ? Icons.public : Icons.lock,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.isPublic ? 'Public' : 'Private',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamesList(PathCreationState state, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Games (${state.selectedGames.length})',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.selectedGames.length,
          itemBuilder: (context, index) {
            final game = state.selectedGames[index];
            final gameType = GameTypes.all
                .firstWhere((g) => g.id == game.gameType);

            return Card(
              child: ListTile(
                leading: Icon(gameType.icon, color: gameType.color),
                title: Text(gameType.name),
                subtitle: Text(_capitalize(game.difficulty)),
                trailing: Text(
                  '#${index + 1}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _goBack() {
    ref.read(pathCreationProvider.notifier).previousStep();
  }

  Future<void> _createPath() async {
    setState(() => _isCreating = true);

    try {
      final state = ref.read(pathCreationProvider);

      final puzzles = <Map<String, dynamic>>[];
      for (int i = 0; i < state.selectedGames.length; i++) {
        final game = state.selectedGames[i];
        final puzzle = await PathService.fetchRandomPuzzle(
          game.gameType,
          game.difficulty,
        );
        puzzles.add({
          'puzzle_id': puzzle.id,
          'order': i + 1,
        });
      }

      final path = await PathService.createPath(
        name: state.pathName,
        description: state.description,
        isPublic: state.isPublic,
        puzzles: puzzles,
      );

      ref.read(pathCreationProvider.notifier).reset();

      if (mounted) {
        context.go('/paths/${path.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _capitalize(String s) =>
      s[0].toUpperCase() + s.substring(1);
}
