import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/features/auth/exceptions/login_exception.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_state_provider.dart';

class LoginController extends ChangeNotifier {
  final WidgetRef _ref;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  bool _mounted = true;

  LoginController(this._ref);

  bool get isLoading => _isLoading;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void _clearErrors() {
    if (!_mounted) return;
    _emailError = null;
    _passwordError = null;
    notifyListeners();
  }

  bool _validateInputs({
    required String email,
    required String password,
  }) {
    if (!_mounted) return false;
    bool isValid = true;
    _clearErrors();

    if (email.trim().isEmpty) {
      _emailError = 'Please enter your email';
      isValid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _emailError = 'Please enter a valid email';
      isValid = false;
    }

    if (password.isEmpty) {
      _passwordError = 'Please enter your password';
      isValid = false;
    }

    notifyListeners();
    return isValid;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (_isLoading || !_mounted) return;

    if (!_validateInputs(
      email: email,
      password: password,
    )) {
      return;
    }

    _isLoading = true;
    if (_mounted) notifyListeners();

    try {
      LogService.instance.info("Attempting to sign in with email: $email");

      // Get the auth state notifier
      final authStateNotifier = _ref.read(authStateProvider.notifier);

      // Use the state notifier to handle sign in
      await authStateNotifier.signIn(email, password);

      // Only check the current state if still mounted
      if (_mounted) {
        final currentState = _ref.read(authStateProvider);
        
        currentState.maybeWhen(
          error: (message) {
            throw LoginException(message);
          },
          orElse: () {}, // Do nothing for other states
        );
      }
    } on AppwriteException catch (e) {
      LogService.instance.error("Appwrite login failed: ${e.message}");
      throw LoginException(e.message.toString());
    } catch (e) {
      LogService.instance.error("Unexpected error during login: $e");
      if (e is LoginException) {
        rethrow;
      }
      throw const LoginException('An unexpected error occurred');
    } finally {
      if (_mounted) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}