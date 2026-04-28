import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/path_creation_provider.dart';

class PathInfoStep extends ConsumerStatefulWidget {
  const PathInfoStep({super.key});

  @override
  ConsumerState<PathInfoStep> createState() => _PathInfoStepState();
}

class _PathInfoStepState extends ConsumerState<PathInfoStep> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(pathCreationProvider);
    _nameController = TextEditingController(text: state.pathName);
    _descriptionController = TextEditingController(text: state.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
            'Create Your Challenge Path',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Step 1 of 3: Path Information',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Path Name',
              hintText: 'e.g., "Logic Master Challenge"',
              border: OutlineInputBorder(),
              helperText: 'Required (3-50 characters)',
            ),
            maxLength: 50,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Optional description of your challenge',
              border: OutlineInputBorder(),
              helperText: 'Max 200 characters',
              alignLabelWithHint: true,
            ),
            maxLength: 200,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Make it public?',
                style: theme.textTheme.bodyLarge,
              ),
              Switch(
                value: state.isPublic,
                onChanged: (value) {
                  ref.read(pathCreationProvider.notifier).updatePathInfo(
                        name: _nameController.text,
                        description: _descriptionController.text,
                        isPublic: value,
                      );
                },
              ),
            ],
          ),
          if (state.isPublic)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Anyone can find and play this challenge',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Only you can see this challenge',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isValid() ? _proceed : null,
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }

  bool _isValid() {
    final name = _nameController.text.trim();
    return name.length >= 3 && name.length <= 50;
  }

  void _proceed() {
    ref.read(pathCreationProvider.notifier).updatePathInfo(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          isPublic: ref.read(pathCreationProvider).isPublic,
        );
    ref.read(pathCreationProvider.notifier).nextStep();
  }
}
