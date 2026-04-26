# Flutter API Integration Guide

How to connect the Flutter app to the Maze Lab API backend.

## Setup

1. Add HTTP client to `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.0
  shared_preferences: ^2.2.0  # for storing auth tokens
```

2. Create an API service in `lib/services/api_service.dart`:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  static String? _accessToken;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> get(String endpoint, {bool requireAuth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (requireAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode}');
    }
  }

  static Future<void> register(String username, String email, String password, String displayName) async {
    final data = await post('/users/register', {
      'username': username,
      'email': email,
      'password': password,
      'display_name': displayName,
    });
    
    _accessToken = data['access_token'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', _accessToken!);
  }

  static Future<void> login(String email, String password) async {
    final data = await post('/users/login', {
      'email': email,
      'password': password,
    });
    
    _accessToken = data['access_token'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', _accessToken!);
  }

  static Future<void> logout() async {
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }
}
```

3. Initialize in `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.initialize();
  runApp(const MyApp());
}
```

## Example: Register and Login

```dart
// In your registration screen
try {
  await ApiService.register(
    usernameController.text,
    emailController.text,
    passwordController.text,
    displayNameController.text,
  );
  // Navigate to home screen
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Registration failed: $e')),
  );
}
```

## Example: Fetch Random Puzzle

```dart
// In your quick play screen
Future<Map<String, dynamic>> getRandomPuzzle(String puzzleType) async {
  return await ApiService.get('/puzzles/random/$puzzleType');
}
```

## Example: Record Completion

```dart
// After user completes a puzzle
await ApiService.post('/completions', {
  'path_id': currentPathId,
  'puzzle_id': puzzleId,
  'time_taken': timeInMilliseconds,
}, requireAuth: true);
```

## API Response Format

### Login/Register Response
```json
{
  "access_token": "eyJhbGc...",
  "token_type": "bearer",
  "user": {
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com",
    "display_name": "John",
    "avatar_url": null,
    "created_at": "2026-04-26T00:00:00"
  }
}
```

### Puzzle Response
```json
{
  "id": 1,
  "type": "sudoku",
  "difficulty": "medium",
  "data": { /* puzzle-specific data */ },
  "created_at": "2026-04-26T00:00:00"
}
```

### Path Response
```json
{
  "id": 1,
  "name": "Beginner's Puzzle Pack",
  "description": "Start here",
  "creator_id": 1,
  "is_public": true,
  "is_challenge": false,
  "created_at": "2026-04-26T00:00:00",
  "puzzles": [ /* array of puzzle objects */ ]
}
```

## Environment-Specific Configuration

For different environments (development, staging, production), update `baseUrl`:

```dart
// In ApiService
static String get baseUrl {
  const String env = String.fromEnvironment('API_ENV', defaultValue: 'dev');
  switch (env) {
    case 'prod':
      return 'https://api.maze-lab.com';
    case 'staging':
      return 'https://staging-api.maze-lab.com';
    default:
      return 'http://localhost:8000';
  }
}

// Run with: flutter run --dart-define=API_ENV=prod
```
