import '../services/api_client.dart';

class PuzzleData {
  final int id;
  final String type;
  final String difficulty;
  final Map<String, dynamic> data;
  final Map<String, dynamic> solution;

  PuzzleData({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.data,
    required this.solution,
  });

  factory PuzzleData.fromJson(Map<String, dynamic> json) {
    return PuzzleData(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      difficulty: json['difficulty'] ?? '',
      data: json['data'] ?? {},
      solution: json['solution'] ?? {},
    );
  }
}

class PuzzleService {
  static Future<PuzzleData> getRandomPuzzle(
    String gameType,
    String difficulty,
  ) async {
    try {
      final response = await ApiClient.get(
        '/puzzles/random/$gameType?difficulty=$difficulty',
        auth: true,
      ) as Map<String, dynamic>;

      return PuzzleData.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch puzzle: $e');
    }
  }
}
