import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/game_type.dart';
import '../../providers/path_creation_provider.dart';

class GameSelectionStep extends ConsumerStatefulWidget {
  const GameSelectionStep({super.key});

  @override
  ConsumerState<GameSelectionStep> createState() => _GameSelectionStepState();
}

class _GameSelectionStepState extends ConsumerState<GameSelectionStep> {
  late String selectedGameType;
  late String selectedDifficulty;

  @override
  void initState() {
    super.initState();
    final state = ref.read(pathCreationProvider);
    selectedGameType = GameTypes.all.first.id;
    selectedDifficulty = state.globalDifficulty;
  }

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
            'Select Games',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Step 2 of 3: Choose which games to include',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          _buildDifficultySection(state, theme),
          const SizedBox(height: 32),
          _buildGameSelectionSection(state, theme),
          const SizedBox(height: 32),
          if (state.selectedGames.isNotEmpty) ...[
            Text(
              'Selected Games (${state.selectedGames.length})',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildGamesList(state, theme),
            const SizedBox(height: 32),
          ],
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
                  onPressed: _isValid(state) ? _proceed : null,
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySection(PathCreationState state, ThemeData theme) {
    const difficulties = ['easy', 'medium', 'hard'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Default Difficulty',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: difficulties
              .map((d) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(_capitalize(d)),
                        selected: selectedDifficulty == d,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => selectedDifficulty = d);
                            ref
                                .read(pathCreationProvider.notifier)
                                .setGlobalDifficulty(d);
                          }
                        },
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildGameSelectionSection(PathCreationState state, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Games',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButton<String>(
                isExpanded: true,
                value: selectedGameType,
                items: GameTypes.all.map((game) {
                  return DropdownMenuItem(
                    value: game.id,
                    child: Row(
                      children: [
                        Icon(game.icon, color: game.color),
                        const SizedBox(width: 8),
                        Text(game.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedGameType = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Difficulty (defaults to ${_capitalize(state.globalDifficulty)})',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: ['easy', 'medium', 'hard']
                    .map((d) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(_capitalize(d)),
                              selected: selectedDifficulty == d,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => selectedDifficulty = d);
                                }
                              },
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: state.selectedGames.length < 10
                      ? _addGame
                      : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Game'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGamesList(PathCreationState state, ThemeData theme) {
    return ListView.builder(
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
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                ref
                    .read(pathCreationProvider.notifier)
                    .removeGame(index);
              },
            ),
          ),
        );
      },
    );
  }

  void _addGame() {
    ref.read(pathCreationProvider.notifier).addGame(
          selectedGameType,
          selectedDifficulty,
        );
    setState(() => selectedDifficulty = ref.read(pathCreationProvider).globalDifficulty);
  }

  void _goBack() {
    ref.read(pathCreationProvider.notifier).previousStep();
  }

  void _proceed() {
    ref.read(pathCreationProvider.notifier).nextStep();
  }

  bool _isValid(PathCreationState state) {
    return state.selectedGames.isNotEmpty;
  }

  String _capitalize(String s) =>
      s[0].toUpperCase() + s.substring(1);
}
