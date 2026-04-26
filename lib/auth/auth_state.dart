import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    state = AuthState(
      userId: userId,
      email: email,
      token: token,
    );
  }

  Future<void> logout() async {
    state = null;
  }
}

final authStateProvider = NotifierProvider<AuthNotifier, AuthState?>(() {
  return AuthNotifier();
});
