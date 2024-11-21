import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/auth/models/auth_state.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_providers.dart';
import 'package:photojam_app/appwrite/auth/repositories/auth_repository.dart';

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref.watch(authRepositoryProvider));
});

class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  
  AuthStateNotifier(this._authRepository) : super(const AuthState.initial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      state = const AuthState.loading();
      final user = await _authRepository.signIn(
        email: email,
        password: password,
      );
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
}
