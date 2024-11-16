import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/core/services/role_service.dart';
import 'package:photojam_app/core/services/log_service.dart';

class AccountController extends ChangeNotifier {
  final AuthAPI _authAPI;
  final RoleService _roleService;
  
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  
  AccountController(this._authAPI, this._roleService) {
    loadUserData(); // Load data when controller is created
  }
  
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get userData => _userData;
  
  Future<void> loadUserData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Use AuthAPI getters instead of getCurrentUser
      final username = _authAPI.username;
      final email = _authAPI.email;
      final role = await _roleService.getCurrentUserRole();
      
      _userData = {
        'username': username ?? 'Unknown User',
        'email': email ?? 'No email available',
        'role': role,
        'isOAuthUser': _authAPI.isOAuthUser
      };
    } catch (e) {
      LogService.instance.error("Error loading user data: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> updateName(String newName) async {
    try {
      await _authAPI.updateName(newName);
      await loadUserData();
    } catch (e) {
      LogService.instance.error("Error updating name: $e");
      rethrow;
    }
  }
  
  Future<void> updateEmail({
    required String newEmail,
    required String password,
  }) async {
    try {
      await _authAPI.updateEmail(
        newEmail: newEmail,
        password: password,
      );
      await loadUserData();
    } catch (e) {
      LogService.instance.error("Error updating email: $e");
      rethrow;
    }
  }
  
  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _authAPI.updatePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      LogService.instance.error("Error updating password: $e");
      rethrow;
    }
  }
  
  Future<void> requestMemberRole() async {
    try {
      // await _roleService.requestMemberRole(); TODO
      await loadUserData();
    } catch (e) {
      LogService.instance.error("Error requesting member role: $e");
      rethrow;
    }
  }
  
  Future<void> requestFacilitatorRole() async {
    try {
      // await _roleService.requestFacilitatorRole(); TODO
      await loadUserData();
    } catch (e) {
      LogService.instance.error("Error requesting facilitator role: $e");
      rethrow;
    }
  }
}