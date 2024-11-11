import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/log_service.dart';

class UserDataProvider extends ChangeNotifier {
  String? username;
  String? email;
  bool isOAuthUser = false;
  String? userRole;

  Future<void> initializeUserData(AuthAPI authAPI) async {
    try {
      email = authAPI.email ?? 'no email';
      username = authAPI.username ?? 'no username';
      isOAuthUser = false; //TODO authAPI.isOAuthUser();
      userRole = await authAPI.getUserRole();
      notifyListeners();
    } catch (e) {
      LogService.instance.error("Error loading user data: $e");
    }
  }
}