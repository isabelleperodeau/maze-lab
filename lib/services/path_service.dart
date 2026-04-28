import '../services/api_client.dart';

class PuzzleData {
  final int id;
  final String type;
  final String difficulty;

  PuzzleData({
    required this.id,
    required this.type,
    required this.difficulty,
  });

  factory PuzzleData.fromJson(Map<String, dynamic> json) {
    return PuzzleData(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      difficulty: json['difficulty'] ?? '',
    );
  }
}

class PathData {
  final int id;
  final String name;
  final String description;
  final bool isPublic;
  final int creatorId;

  PathData({
    required this.id,
    required this.name,
    required this.description,
    required this.isPublic,
    required this.creatorId,
  });

  factory PathData.fromJson(Map<String, dynamic> json) {
    return PathData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isPublic: json['is_public'] ?? false,
      creatorId: json['creator_id'] ?? 0,
    );
  }
}

class PathService {
  static Future<PuzzleData> fetchRandomPuzzle(
    String gameType,
    String difficulty,
  ) async {
    try {
      final response = await ApiClient.get(
        '/puzzles/random/$gameType?difficulty=$difficulty',
        auth: true,
      ) as Map<String, dynamic>;

      // Handle both single puzzle and wrapped response
      final puzzleData = response['puzzle'] ?? response;
      return PuzzleData.fromJson(puzzleData);
    } catch (e) {
      throw Exception('Failed to fetch puzzle: $e');
    }
  }

  static Future<PathData> createPath({
    required String name,
    required String description,
    required bool isPublic,
    required List<Map<String, dynamic>> puzzles,
  }) async {
    try {
      final response = await ApiClient.post(
        '/paths/',
        {
          'name': name,
          'description': description,
          'is_public': isPublic,
          'puzzles': puzzles,
        },
        auth: true,
      ) as Map<String, dynamic>;

      return PathData.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create path: $e');
    }
  }

  static Future<List<PathData>> getUserPaths(String userId) async {
    try {
      final response = await ApiClient.get(
        '/paths/user/$userId',
        auth: true,
      ) as List;

      return response
          .cast<Map<String, dynamic>>()
          .map((p) => PathData.fromJson(p))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user paths: $e');
    }
  }

  static Future<PathData> getPath(int pathId) async {
    try {
      final response = await ApiClient.get(
        '/paths/$pathId',
        auth: true,
      ) as Map<String, dynamic>;

      return PathData.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch path: $e');
    }
  }
}
