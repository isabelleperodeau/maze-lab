import 'package:flutter/material.dart';

class GameType {
  const GameType({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
}

class GameTypes {
  static const sudoku = GameType(
    id: 'sudoku',
    name: 'Sudoku',
    icon: Icons.grid_3x3,
    color: Colors.blue,
  );
  static const kakuro = GameType(
    id: 'kakuro',
    name: 'Kakuro',
    icon: Icons.calculate,
    color: Colors.orange,
  );
  static const nonogram = GameType(
    id: 'nonogram',
    name: 'Nonogram',
    icon: Icons.grid_view,
    color: Colors.green,
  );
  static const twentyFortyEight = GameType(
    id: '2048',
    name: '2048',
    icon: Icons.apps,
    color: Colors.purple,
  );

  static const all = [sudoku, kakuro, nonogram, twentyFortyEight];
}