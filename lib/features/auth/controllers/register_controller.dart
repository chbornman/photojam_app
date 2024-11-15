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
      LogService.instance.info("Creating new user account");
      await _authAPI.createUser(
        name: name,
        email: email,
        password: password,
      );

      LogService.instance.info("User created, creating temporary session");
      await _authAPI.createEmailPasswordSession(
        email: email,
        password: password,
      );

      LogService.instance.info("User created as nonmember");
      await _authAPI.signOut();
      
      LogService.instance.info("Registration complete");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}