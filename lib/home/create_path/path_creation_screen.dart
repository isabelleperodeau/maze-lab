import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/path_creation_provider.dart';
import 'confirm_step.dart';
import 'game_selection_step.dart';
import 'path_info_step.dart';

class PathCreationScreen extends ConsumerWidget {
  const PathCreationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pathCreationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Challenge Path'),
        elevation: 0,
      ),
      body: _buildStep(state.currentStep),
      floatingActionButton: state.currentStep > 1
          ? FloatingActionButton.extended(
              onPressed: () => ref
                  .read(pathCreationProvider.notifier)
                  .previousStep(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            )
          : null,
    );
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 1:
        return const PathInfoStep();
      case 2:
        return const GameSelectionStep();
      case 3:
        return const ConfirmStep();
      default:
        return const Center(child: Text('Unknown step'));
    }
  }
}
