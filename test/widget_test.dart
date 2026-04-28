import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:maze_lab/home/home_screen.dart';

void main() {
  testWidgets('HomeScreen renders with maze-lab title', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    expect(find.text('maze-lab'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
