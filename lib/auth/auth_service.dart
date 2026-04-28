import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../services/api_client.dart';

class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'user_email';

  static const _secureStorage = FlutterSecureStorage();
  static final _googleSignIn = GoogleSignIn(
    clientId: '113246921478-1h9m23jkitptmk2lqn6kgjagoekuo49k.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  static Future<Map<String, String>> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await ApiClient.post('/users/register', {
      'username': username,
      'email': email,
      'password': password,
      'display_name': displayName,
    }) as Map<String, dynamic>;

    return _persistAuth(response);
  }

  static Future<Map<String, String>> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post('/users/login', {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;

    return _persistAuth(response);
  }

  static Future<Map<String, String>> _persistAuth(
    Map<String, dynamic> response,
  ) async {
    final token = response['access_token'] as String;
    final user = response['user'] as Map<String, dynamic>;
    final userId = user['id'].toString();
    final email = user['email'] as String;

    await ApiClient.setToken(token);
    await _secureStorage.write(key: _userIdKey, value: userId);
    await _secureStorage.write(key: _emailKey, value: email);

    return {'token': token, 'user_id': userId, 'email': email};
  }

  static Future<Map<String, String>?> restoreSession() async {
    final userId = await _secureStorage.read(key: _userIdKey);
    final email = await _secureStorage.read(key: _emailKey);
    if (userId == null || email == null) return null;

    try {
      await ApiClient.get('/users/me', auth: true);
    } on ApiException {
      await logout();
      return null;
    }

    return {'token': '', 'user_id': userId, 'email': email};
  }

  static Future<Map<String, String>> loginWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    if (accessToken == null) throw Exception('Failed to get access token');

    // For web, Google returns access token instead of ID token
    // We'll send the access token to backend for verification
    final response = await ApiClient.post('/users/oauth/google', {
      'id_token': accessToken,  // Actually an access token on web
    }) as Map<String, dynamic>;

    return _persistAuth(response);
  }

  static Future<Map<String, String>> loginWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final idToken = credential.identityToken;
    if (idToken == null) throw Exception('Failed to get ID token');

    final response = await ApiClient.post('/users/oauth/apple', {
      'id_token': idToken,
    }) as Map<String, dynamic>;

    return _persistAuth(response);
  }

  static Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await ApiClient.clearToken();
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _emailKey);
  }
}
