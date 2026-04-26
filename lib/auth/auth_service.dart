import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'user_email';

  static final _secureStorage = const FlutterSecureStorage();
  static final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static Future<Map<String, String>> loginWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign-in cancelled');

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) throw Exception('Failed to get ID token');

      return _verifyWithBackend(idToken, 'google');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, String>> loginWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null) throw Exception('Failed to get ID token');

      return _verifyWithBackend(idToken, 'apple');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, String>> mockLogin() async {
    // Mock login for development (no real OAuth)
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    final mockToken = 'dev_token_${DateTime.now().millisecondsSinceEpoch}';
    final mockUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    const mockEmail = 'dev_user@example.com';

    // Store securely
    await _secureStorage.write(key: _tokenKey, value: mockToken);
    await _secureStorage.write(key: _userIdKey, value: mockUserId);
    await _secureStorage.write(key: _emailKey, value: mockEmail);

    return {
      'token': mockToken,
      'user_id': mockUserId,
      'email': mockEmail,
    };
  }

  static Future<Map<String, String>> _verifyWithBackend(String idToken, String provider) async {
    // TODO: Replace with real backend call when available
    // For now, mock the backend response for development
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    final mockToken = 'dev_token_${DateTime.now().millisecondsSinceEpoch}';
    final mockUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final mockEmail = 'dev_user@example.com';

    // Store securely
    await _secureStorage.write(key: _tokenKey, value: mockToken);
    await _secureStorage.write(key: _userIdKey, value: mockUserId);
    await _secureStorage.write(key: _emailKey, value: mockEmail);

    return {
      'token': mockToken,
      'user_id': mockUserId,
      'email': mockEmail,
    };
  }

  static Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  static Future<String?> getUserId() async {
    return await _secureStorage.read(key: _userIdKey);
  }

  static Future<String?> getEmail() async {
    return await _secureStorage.read(key: _emailKey);
  }

  static Future<void> logout() async {
    await _googleSignIn.signOut();
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _emailKey);
  }
}
