import '../services/api_client.dart';

class CompletionData {
  final int id;
  final int userId;
  final int pathId;
  final int puzzleId;
  final int? timeTaken; // in seconds
  final DateTime completedAt;

  CompletionData({
    required this.id,
    required this.userId,
    required this.pathId,
    required this.puzzleId,
    required this.timeTaken,
    required this.completedAt,
  });

  factory CompletionData.fromJson(Map<String, dynamic> json) {
    return CompletionData(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      pathId: json['path_id'] ?? 0,
      puzzleId: json['puzzle_id'] ?? 0,
      timeTaken: json['time_taken'],
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : DateTime.now(),
    );
  }
}

class CompletionService {
  static Future<List<CompletionData>> getUserPathCompletions(
    int pathId,
    String userId,
  ) async {
    try {
      final userIdInt = int.tryParse(userId) ?? 0;
      final response = await ApiClient.get(
        '/completions?path_id=$pathId&user_id=$userIdInt',
        auth: true,
      ) as List;

      return response
          .cast<Map<String, dynamic>>()
          .map((c) => CompletionData.fromJson(c))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> recordCompletion({
    required int pathId,
    required int puzzleId,
    required int timeTaken,
  }) async {
    try {
      await ApiClient.post(
        '/completions',
        {
          'path_id': pathId,
          'puzzle_id': puzzleId,
          'time_taken': timeTaken,
        },
        auth: true,
      );
    } catch (e) {
      throw Exception('Failed to record completion: $e');
    }
  }
}
