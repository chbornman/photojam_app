import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/log_service.dart';
import 'package:photojam_app/pages/login/login_exception.dart';

class LoginController extends ChangeNotifier {
  final AuthAPI _authAPI;
  bool _isLoading = false;

  LoginController(this._authAPI);

  bool get isLoading => _isLoading;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      LogService.instance.info("Attempting to sign in");
      
      await _authAPI.createEmailPasswordSession(
        email: email,
        password: password,
      );

      LogService.instance.info("Login successful");
    } on AppwriteException catch (e) {
      LogService.instance.error("Login failed: ${e.message}");
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
