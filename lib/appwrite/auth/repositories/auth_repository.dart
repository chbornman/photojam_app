import 'package:photojam_app/appwrite/auth/models/user_model.dart';

abstract class AuthRepository {
  Future<AppUser> createAccount({
    required String email,
    required String password,
    required String name,
  });
  
  Future<AppUser> signIn({
    required String email,
    required String password,
  });
  
  Future<void> signOut();
  Future<AppUser?> getCurrentUser();
  Future<void> sendVerificationEmail();
  Future<void> sendPasswordReset(String email);
  Future<void> updatePassword(String password);
  Future<void> updateName(String name);
  Future<void> updatePreferences(Map<String, dynamic> preferences);

  Future<List<String>> getUserTeams(String userId);
  Future<String> getUserRole();
}
