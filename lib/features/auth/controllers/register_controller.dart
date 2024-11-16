import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/core/services/log_service.dart';

class RegisterController extends ChangeNotifier {
  final AuthAPI _authAPI;
  bool _isLoading = false;

  RegisterController(this._authAPI);

  bool get isLoading => _isLoading;

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (_isLoading) return;
    
    if (password != confirmPassword) {
      throw const FormatException("Passwords do not match!");
    }

    _isLoading = true;
    notifyListeners();

    try {
      LogService.instance.info("Creating new user account for: $email");
      
      // Create the account
      await _authAPI.createAccount(
        name: name,
        email: email,
        password: password,
      );

      LogService.instance.info("Account created, signing in");
      
      // Sign in with the new account
      await _authAPI.signIn(
        email: email,
        password: password,
      );

      // Verify we're authenticated
      if (!_authAPI.isAuthenticated) {
        throw Exception('Failed to authenticate after registration');
      }

      LogService.instance.info("Initial sign in successful");
      
      // Sign out to force them to the login screen
      await _authAPI.signOut();
      
      LogService.instance.info("Registration process complete");
    } catch (e) {
      LogService.instance.error("Registration failed: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}