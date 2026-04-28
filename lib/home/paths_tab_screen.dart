import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_state.dart';
import '../services/path_service.dart';

class PathsTabScreen extends ConsumerStatefulWidget {
  const PathsTabScreen({super.key});

  @override
  ConsumerState<PathsTabScreen> createState() => _PathsTabScreenState();
}

class _PathsTabScreenState extends ConsumerState<PathsTabScreen> {
  late Future<List<PathData>> _userPathsFuture;

  @override
  void initState() {
    super.initState();
    _loadPaths();
  }

  void _loadPaths() {
    final auth = ref.read(authStateProvider);
    if (auth != null) {
      _userPathsFuture = PathService.getUserPaths(auth.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Challenge Paths'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/paths/create');
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Path'),
      ),
      body: auth == null
          ? const Center(child: Text('Not authenticated'))
          : FutureBuilder<List<PathData>>(
              future: _userPathsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(_loadPaths),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final paths = snapshot.data ?? [];

                if (paths.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No challenge paths yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first challenge to get started',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(_loadPaths),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: paths.length,
                    itemBuilder: (context, index) {
                      final path = paths[index];
                      return _buildPathCard(path, theme, context);
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPathCard(PathData path, ThemeData theme, BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => context.push('/paths/${path.id}'),
        title: Text(path.name),
        subtitle: path.description.isNotEmpty
            ? Text(path.description, maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              path.isPublic ? Icons.public : Icons.lock,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }
}
