import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_state.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';
import '../home/paths_tab_screen.dart';
import '../home/create_path/path_creation_screen.dart';
import '../home/path_detail_screen.dart';
import '../games/sudoku/sudoku_screen.dart';
import '../games/kakuro/kakuro_screen.dart';
import '../games/nonogram/nonogram_screen.dart';
import '../games/twenty_forty_eight/twenty_forty_eight_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState != null;
      final isGoingToLogin = state.matchedLocation == '/login';

      if (!isLoggedIn) {
        return '/login';
      }

      if (isGoingToLogin) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/paths',
        builder: (context, state) => const PathsTabScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const PathCreationScreen(),
          ),
          GoRoute(
            path: ':pathId',
            builder: (context, state) {
              final pathId = state.pathParameters['pathId'] ?? '0';
              return PathDetailScreen(pathId: pathId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) => const _PlaceholderScreen(title: 'Friends'),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const _PlaceholderScreen(title: 'Profile'),
      ),
      GoRoute(
        path: '/game/:gameId/:difficulty',
        pageBuilder: (context, state) {
          final gameId = state.pathParameters['gameId'];
          final difficulty = state.pathParameters['difficulty'] ?? 'easy';
          final pathId = state.uri.queryParameters['pathId'];
          final puzzleIndex = state.uri.queryParameters['puzzleIndex'];
          final puzzleId = state.uri.queryParameters['puzzleId'];

          Widget child;
          switch (gameId) {
            case 'sudoku':
              child = SudokuScreen(
                difficulty: difficulty,
                pathId: pathId,
                puzzleIndex: puzzleIndex,
                puzzleId: puzzleId,
              );
            case 'kakuro':
              child = KakuroScreen(
                difficulty: difficulty,
                pathId: pathId,
                puzzleIndex: puzzleIndex,
                puzzleId: puzzleId,
              );
            case 'nonogram':
              child = NonogramScreen(
                difficulty: difficulty,
                pathId: pathId,
                puzzleIndex: puzzleIndex,
                puzzleId: puzzleId,
              );
            case '2048':
              child = TwentyFortyEightScreen(
                difficulty: difficulty,
                pathId: pathId,
                puzzleIndex: puzzleIndex,
                puzzleId: puzzleId,
              );
            default:
              child = const _PlaceholderScreen(title: 'Game');
          }

          return CustomTransitionPage(
            child: child,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset.zero,
                    end: const Offset(1, 0),
                  ).animate(secondaryAnimation),
                  child: child,
                ),
              );
            },
          );
        },
      ),
    ],
  );
});

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title screen coming soon'),
      ),
    );
  }
}
