// UserDataProvider.dart
import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/log_service.dart';
import 'package:flutter/foundation.dart';

class UserDataProvider with ChangeNotifier {
  final AuthAPI _authAPI;
  String? _userRole;
  String? _email;
  String? _username;
  bool? _isOAuthUser;

  UserDataProvider(this._authAPI);

  // Getters
  String? get userRole => _userRole;
  String? get email => _email;
  String? get username => _username;
  bool? get isOAuthUser => _isOAuthUser;

  // Setters that notify listeners
  set username(String? value) {
    _username = value;
    notifyListeners();
  }

  set email(String? value) {
    _email = value;
    notifyListeners();
  }

  Future<void> loadUserRole() async {
    try {
      LogService.instance.info("Starting to load user role and data");
      
      // Get basic user data
      _email = _authAPI.email;
      _username = _authAPI.username;
      _isOAuthUser = _authAPI.isOAuthUser();
      
      // Get user role from preferences
      _userRole = await _authAPI.getUserRole() ?? 'nonmember'; // Default to nonmember if null
      
      LogService.instance.info("Loaded user data - Role: $_userRole, Email: $_email, Username: $_username");
      
      notifyListeners();
    } catch (e) {
      LogService.instance.error("Error loading user data: $e");
      // Set default values in case of error
      _userRole = 'nonmember';
      _email = _authAPI.email ?? 'No email available';
      _username = _authAPI.username ?? 'User';
      notifyListeners();
    }
  }

  void setUserRole(String role) async {
    try {
      await _authAPI.setRole(role);
      _userRole = role;
      notifyListeners();
    } catch (e) {
      LogService.instance.error("Error setting user role: $e");
    }
  }

  void clearUserRole() {
    _userRole = null;
    _email = null;
    _username = null;
    _isOAuthUser = null;
    notifyListeners();
  }
}