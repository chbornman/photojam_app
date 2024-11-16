import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/features/auth/exceptions/login_exception.dart';

class LoginController extends ChangeNotifier {
  final AuthAPI _authAPI;
  bool _isLoading = false;

  LoginController(this._authAPI);

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authAPI.isAuthenticated;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (_isLoading) return;

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

  // Future<void> signInWithProvider(OAuthProvider provider) async {
  //   if (_isLoading) return;

  //   _isLoading = true;
  //   notifyListeners();

  //   try {
  //     LogService.instance.info("Attempting to sign in with provider: $provider");
      
  //     await _authAPI.signInWithOAuth(provider);

  //     if (!_authAPI.isAuthenticated) {
  //       throw const LoginException('Failed to authenticate with provider');
  //     }

  //     LogService.instance.info("OAuth login successful for user: ${_authAPI.username}");
  //   } on AppwriteException catch (e) {
  //     LogService.instance.error("OAuth login failed: ${e.message}");
  //     throw LoginException(e.message.toString());
  //   } catch (e) {
  //     LogService.instance.error("Unexpected error during OAuth login: $e");
  //     throw const LoginException('An unexpected error occurred');
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

  Future<void> signOut() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      LogService.instance.info("Attempting to sign out");
      
      await _authAPI.signOut();

      LogService.instance.info("Sign out successful");
    } catch (e) {
      LogService.instance.error("Error during sign out: $e");
      throw const LoginException('Failed to sign out');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}