import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/features/auth/login_exception.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_state_provider.dart';
import 'package:photojam_app/appwrite/auth/providers/user_role_provider.dart';

// State class to encapsulate login form state
class LoginState {
  final bool isLoading;
  final String? emailError;
  final String? passwordError;

  const LoginState({
    this.isLoading = false,
    this.emailError,
    this.passwordError,
  });

  LoginState copyWith({
    bool? isLoading,
    String? emailError,
    String? passwordError,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      emailError: emailError,  // Pass null to clear error
      passwordError: passwordError,  // Pass null to clear error
    );
  }
}

// Provider for the login controller
final loginControllerProvider = ChangeNotifierProvider.autoDispose((ref) {
  return LoginController(ref);
});

class LoginController extends ChangeNotifier {
  final AutoDisposeRef _ref;
  LoginState _state = const LoginState();
  bool _disposed = false;

  LoginController(this._ref) {
    _ref.onDispose(() {
      _disposed = true;
    });
  }

  // Getters
  bool get isLoading => _state.isLoading;
  String? get emailError => _state.emailError;
  String? get passwordError => _state.passwordError;

  void _updateState(LoginState newState) {
    if (!_disposed) {
      _state = newState;
      notifyListeners();
    }
  }

  void _clearErrors() {
    if (!_disposed) {
      _updateState(_state.copyWith(
        emailError: null,
        passwordError: null,
      ));
    }
  }

  bool _validateInputs({
    required String email,
    required String password,
  }) {
    if (_disposed) return false;
    
    bool isValid = true;
    String? emailError;
    String? passwordError;

    // Validate email
    if (email.trim().isEmpty) {
      emailError = 'Please enter your email';
      isValid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      emailError = 'Please enter a valid email';
      isValid = false;
    }

    // Validate password
    if (password.isEmpty) {
      passwordError = 'Please enter your password';
      isValid = false;
    }

    // Update state with any validation errors
    _updateState(_state.copyWith(
      emailError: emailError,
      passwordError: passwordError,
    ));

    return isValid;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (_state.isLoading || _disposed) return;

    if (!_validateInputs(email: email, password: password)) {
      return;
    }

    try {
      _updateState(_state.copyWith(isLoading: true));
      LogService.instance.info("Attempting to sign in with email: $email");

      if (_disposed) return;

      // Get auth state notifier and attempt sign in
      final authStateNotifier = _ref.read(authStateProvider.notifier);
      await authStateNotifier.signIn(email, password);

      // Check the auth state after sign in
      if (!_disposed) {
        final authState = _ref.read(authStateProvider);
        
        await authState.whenOrNull(
          authenticated: (_) async {
            LogService.instance.info("Sign in successful, refreshing role...");
            // Only invalidate after successful authentication
            _ref.invalidate(userRoleProvider);
          },
          error: (message) {
            LogService.instance.error("Sign in error: $message");
            throw LoginException(message);
          },
        );
      }
    } on AppwriteException catch (e) {
      LogService.instance.error("Appwrite login failed: ${e.message}");
      if (!_disposed) {
        throw LoginException(e.message.toString());
      }
    } catch (e) {
      LogService.instance.error("Unexpected error during login: $e");
      if (!_disposed) {
        if (e is LoginException) {
          rethrow;
        }
        throw const LoginException('An unexpected error occurred');
      }
    } finally {
      if (!_disposed) {
        _updateState(_state.copyWith(isLoading: false));
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}