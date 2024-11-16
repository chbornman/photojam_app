import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/features/auth/exceptions/login_exception.dart';

class LoginController extends ChangeNotifier {
  final AuthAPI _authAPI;
  bool _isLoading = false;
  
  // Add validation state
  String? _emailError;
  String? _passwordError;

  LoginController(this._authAPI);

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authAPI.isAuthenticated;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;

  void _clearErrors() {
    _emailError = null;
    _passwordError = null;
    notifyListeners();
  }

  bool _validateInputs({
    required String email,
    required String password,
  }) {
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
    if (_isLoading) return;

    if (!_validateInputs(
      email: email,
      password: password,
    )) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      LogService.instance.info("Attempting to sign in with email: $email");
      
      await _authAPI.signIn(
        email: email,
        password: password,
      );

      if (!_authAPI.isAuthenticated) {
        throw const LoginException('Failed to authenticate');
      }

      LogService.instance.info("Login successful for user: ${_authAPI.username}");
    } on AppwriteException catch (e) {
      LogService.instance.error("Appwrite login failed: ${e.message}");
      throw LoginException(e.message.toString());
    } catch (e) {
      LogService.instance.error("Unexpected error during login: $e");
      throw const LoginException('An unexpected error occurred');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}