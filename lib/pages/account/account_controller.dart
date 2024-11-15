import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/role_service.dart';
import 'package:photojam_app/log_service.dart';

class AccountController extends ChangeNotifier {
  final AuthAPI _authAPI;
  final RoleService _roleService;
  
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  
  AccountController(this._authAPI, this._roleService);
  
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get userData => _userData;
  
  Future<void> loadUserData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final user = await _authAPI.getCurrentUser();
      final role = await _roleService.getCurrentUserRole();
      
      _userData = {
        'username': user.name,
        'email': user.email,
        'role': role,
        'isOAuthUser': false
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
    await _authAPI.updateName(newName);
    await loadUserData();
  }
  
  Future<void> updateEmail(String newEmail, String currentPassword) async {
    await _authAPI.updateEmail(newEmail, currentPassword);
    await loadUserData();
  }
  
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    await _authAPI.updatePassword(currentPassword, newPassword);
  }
  
  Future<void> requestMemberRole() async {
    await _roleService.requestMemberRole();
    await loadUserData();
  }
  
  Future<void> requestFacilitatorRole() async {
    await _roleService.requestFacilitatorRole();
    await loadUserData();
  }
}