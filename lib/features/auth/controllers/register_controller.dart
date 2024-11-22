import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/features/auth/exceptions/register_exception.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_providers.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_state_provider.dart';

class RegisterController extends ChangeNotifier {
  final WidgetRef _ref;
  bool _isLoading = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  RegisterController(this._ref);

  bool get isLoading => _isLoading;
  String? get nameError => _nameError;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;
  String? get confirmPasswordError => _confirmPasswordError;

  void _clearErrors() {
    _nameError = null;
    _emailError = null;
    _passwordError = null;
    _confirmPasswordError = null;
    notifyListeners();
  }

  bool _validateInputs({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    bool isValid = true;
    _clearErrors();

    if (name.trim().isEmpty) {
      _nameError = 'Please enter your name';
      isValid = false;
    }

    if (email.trim().isEmpty) {
      _emailError = 'Please enter your email';
      isValid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _emailError = 'Please enter a valid email';
      isValid = false;
    }

    if (password.isEmpty) {
      _passwordError = 'Please enter a password';
      isValid = false;
    } else if (password.length < 8) {
      _passwordError = 'Password must be at least 8 characters';
      isValid = false;
    }

    if (confirmPassword.isEmpty) {
      _confirmPasswordError = 'Please confirm your password';
      isValid = false;
    } else if (confirmPassword != password) {
      _confirmPasswordError = 'Passwords do not match';
      isValid = false;
    }

    notifyListeners();
    return isValid;
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (_isLoading) return;

    if (!_validateInputs(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    )) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      LogService.instance.info("Attempting to register user: $email");
      
      final authRepo = _ref.read(authRepositoryProvider);
      
      // Create account
      final user = await authRepo.createAccount(
        email: email,
        password: password,
        name: name,
      );

      // Sign in after successful registration
      await _ref.read(authStateProvider.notifier).signIn(email, password);

      LogService.instance.info("Registration successful for user: ${user.name}");
    } on AppwriteException catch (e) {
      LogService.instance.error("Appwrite registration failed: ${e.message}");
      throw RegisterException(e.message.toString());
    } catch (e) {
      LogService.instance.error("Unexpected error during registration: $e");
      if (e is RegisterException) {
        rethrow;
      }
      throw const RegisterException('An unexpected error occurred');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}