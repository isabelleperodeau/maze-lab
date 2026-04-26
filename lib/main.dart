import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/auth_state.dart';
import 'config/router.dart';

void main() {
  runApp(const ProviderScope(child: MazeLabApp()));
}

class MazeLabApp extends ConsumerStatefulWidget {
  const MazeLabApp({super.key});

  @override
  ConsumerState<MazeLabApp> createState() => _MazeLabAppState();
}

class _MazeLabAppState extends ConsumerState<MazeLabApp> {
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    await ref.read(authStateProvider.notifier).restoreSession();
    if (mounted) setState(() => _restored = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      useMaterial3: true,
    );

    if (!_restored) {
      return MaterialApp(
        title: 'maze-lab',
        theme: theme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'maze-lab',
      theme: theme,
      routerConfig: router,
    );
  }
}
