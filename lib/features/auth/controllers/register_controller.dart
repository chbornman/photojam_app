import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/core/services/log_service.dart';

class RegisterController extends ChangeNotifier {
  final AuthAPI _authAPI;
  final BuildContext context;
  bool _isLoading = false;

  // Add validation state
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  RegisterController(this._authAPI, this.context);

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
    } else if (password != confirmPassword) {
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
      LogService.instance.info("Creating new user account for: $email");

      await _authAPI.createAccount(
        name: name,
        email: email,
        password: password,
      );

      LogService.instance.info("Account created, signing in");

      await _authAPI.signIn(
        email: email,
        password: password,
      );

      if (!_authAPI.isAuthenticated) {
        throw Exception('Failed to authenticate after registration');
      }

      LogService.instance.info("Initial sign in successful");
      await _authAPI.signOut();
      LogService.instance.info("Registration process complete");

      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      LogService.instance.error("Registration failed: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
