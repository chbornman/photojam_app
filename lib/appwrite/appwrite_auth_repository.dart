import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:photojam_app/appwrite/auth/models/user_model.dart';
import 'package:photojam_app/appwrite/auth/repositories/auth_repository.dart';
import 'package:photojam_app/core/services/log_service.dart';

class AppwriteAuthRepository implements AuthRepository {
  final Account _account;
  final Client _client;

  AppwriteAuthRepository(this._account, this._client);

  @override
  Future<AppUser> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      LogService.instance.info('Creating new account for email: $email');
      final user = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      LogService.instance.info('Account created successfully: ${user.$id}');
      return AppUser.fromAccount(user);
    } catch (e) {
      LogService.instance.error('Error creating account: $e');
      throw _handleAuthError(e);
    }
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      LogService.instance.info('Attempting sign in for email: $email');

      final session = await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      LogService.instance.info('Session created: ${session.$id}');

      final user = await _account.get();
      LogService.instance.info('User details retrieved: ${user.$id}');

      _client.setSession(session.$id);

      return AppUser.fromAccount(user);
    } catch (e) {
      LogService.instance.error('Sign in failed: $e');
      throw _handleAuthError(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      LogService.instance.info('Signing out current session');
      await _account.deleteSession(sessionId: 'current');
      LogService.instance.info('Sign out successful');
    } catch (e) {
      LogService.instance.error('Sign out failed: $e');
      throw _handleAuthError(e);
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    try {
      LogService.instance.info('Fetching current user');
      final user = await _account.get();
      LogService.instance.info('Current user retrieved: ${user.$id}');
      return AppUser.fromAccount(user);
    } catch (e) {
      LogService.instance.info('No current user found');
      return null;
    }
  }

  @override
  Future<String> getUserRole() async {
    try {
      LogService.instance.info('Fetching user role from labels');
      final user = await _account.get();
      final labels = user.labels;

      LogService.instance.info('User labels: $labels');

      // Check labels in order of hierarchy
      if (labels.contains('admin')) {
        LogService.instance.info('User has admin role');
        return 'admin';
      } else if (labels.contains('facilitator')) {
        LogService.instance.info('User has facilitator role');
        return 'facilitator';
      } else if (labels.contains('member')) {
        LogService.instance.info('User has member role');
        return 'member';
      }

      LogService.instance
          .info('No matching role label found, defaulting to nonmember');
      return 'nonmember';
    } catch (e) {
      LogService.instance
          .error('Error getting user role, defaulting to nonmember: $e');
      return 'nonmember';
    }
  }

  @override
  Future<void> sendVerificationEmail() async {
    try {
      LogService.instance.info('Sending verification email');
      await _account.createVerification(
        url: 'https://yourapp.com/verify-email',
      );
      LogService.instance.info('Verification email sent');
    } catch (e) {
      LogService.instance.error('Failed to send verification email: $e');
      throw _handleAuthError(e);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      LogService.instance.info('Sending password reset email to: $email');
      await _account.createRecovery(
        email: email,
        url: 'https://yourapp.com/reset-password',
      );
      LogService.instance.info('Password reset email sent');
    } catch (e) {
      LogService.instance.error('Failed to send password reset: $e');
      throw _handleAuthError(e);
    }
  }

  @override
  Future<void> updatePassword(String password) async {
    try {
      LogService.instance.info('Updating user password');
      await _account.updatePassword(password: password);
      LogService.instance.info('Password updated successfully');
    } catch (e) {
      LogService.instance.error('Password update failed: $e');
      throw _handleAuthError(e);
    }
  }

  @override
  Future<void> updateName(String name) async {
    try {
      LogService.instance.info('Updating user name');
      await _account.updateName(name: name);
      LogService.instance.info('Name updated successfully');
    } catch (e) {
      LogService.instance.error('Name update failed: $e');
      throw _handleAuthError(e);
    }
  }

  @override
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      LogService.instance.info('Updating user preferences');
      await _account.updatePrefs(prefs: preferences);
      LogService.instance.info('Preferences updated successfully');
    } catch (e) {
      LogService.instance.error('Preferences update failed: $e');
      throw _handleAuthError(e);
    }
  }

  @override
  Future<Session> getCurrentSession() async {
    try {
      LogService.instance.info('Fetching current session');
      final session = await _account.getSession(sessionId: 'current');
      LogService.instance.info('Current session retrieved: ${session.$id}');
      return session;
    } catch (e) {
      LogService.instance.error('Failed to get current session: $e');
      throw _handleAuthError(e);
    }
  }

  Exception _handleAuthError(dynamic e) {
    if (e is AppwriteException) {
      return Exception(e.message);
    }
    return Exception('An unexpected error occurred');
  }
}