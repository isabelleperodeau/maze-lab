import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service.dart';

class AuthState {
  const AuthState({
    required this.userId,
    required this.email,
    required this.token,
  });

  final String userId;
  final String email;
  final String token;
}

class AuthNotifier extends Notifier<AuthState?> {
  @override
  AuthState? build() => null;

  Future<void> setUser(String userId, String email, String token) async {
    state = AuthState(userId: userId, email: email, token: token);
  }

  Future<void> restoreSession() async {
    final session = await AuthService.restoreSession();
    if (session != null) {
      state = AuthState(
        userId: session['user_id']!,
        email: session['email']!,
        token: session['token']!,
      );
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    state = null;
  }
}

final authStateProvider = NotifierProvider<AuthNotifier, AuthState?>(() {
  return AuthNotifier();
});
