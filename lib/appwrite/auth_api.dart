import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/core/services/role_service.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class AuthAPI extends ChangeNotifier {
  final Client client;
  final Account account;
  late final RoleService roleService;

  User? _currentUser;
  AuthStatus _status = AuthStatus.uninitialized;
  String? _sessionId;

  AuthAPI(this.client) : account = Account(client) {
    roleService = RoleService(client);
    _initializeAuth();
  }

  // Getters
  String? get userId => _currentUser?.$id;
  String? get email => _currentUser?.email;
  String? get username => _currentUser?.name;
  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isOAuthUser => _currentUser?.emailVerification == false;

  Future<void> _initializeAuth() async {
    try {
      _currentUser = await account.get();
      _status = AuthStatus.authenticated;
      LogService.instance.info('Auth initialized - User: ${_currentUser?.$id}');
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      LogService.instance.info('Auth initialized - No authenticated user');
      await roleService.clearRoleCache(); // Clear role cache when no auth
    } finally {
      notifyListeners();
    }
  }

  Future<User> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      LogService.instance.info('Creating account for: $email');

      final user = await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      LogService.instance.info('Account created: ${user.$id}');
      await roleService.clearRoleCache();

      // Sign in immediately after account creation
      await _signInInternal(email: email, password: password);

      LogService.instance.info('Registration process complete');

      return user;
    } catch (e) {
      LogService.instance.error('Account creation failed: $e');
      rethrow;
    }
  }

  Future<void> _signInInternal({
    required String email,
    required String password,
  }) async {
    try {
      LogService.instance.info('Signing in: $email');

      // Ensure clean session state
      await _clearCurrentSession();
      await roleService.clearRoleCache();

      // Create new session
      final session = await account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      _sessionId = session.$id;
      _currentUser = await account.get();
      _status = AuthStatus.authenticated;

      LogService.instance.info('Sign in successful: ${_currentUser?.$id}');
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      LogService.instance.error('Sign in failed: $e');
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _signInInternal(email: email, password: password);
  }

  Future<void> signInWithOAuth(OAuthProvider provider) async {
    try {
      LogService.instance.info('Starting OAuth sign in: $provider');

      await _clearCurrentSession();
      await roleService.clearRoleCache();

      final session = await account.createOAuth2Session(provider: provider);

      _sessionId = session.$id;
      _currentUser = await account.get();
      _status = AuthStatus.authenticated;

      LogService.instance
          .info('OAuth sign in successful: ${_currentUser?.$id}');
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      LogService.instance.error('OAuth sign in failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      LogService.instance.info('Signing out user: ${_currentUser?.$id}');
      await _clearCurrentSession();
      await roleService.clearRoleCache(); // Clear role cache on sign out

      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _sessionId = null;

      LogService.instance.info('Sign out successful');
      notifyListeners();
    } catch (e) {
      LogService.instance.error('Sign out failed: $e');
      rethrow;
    }
  }

  Future<void> _clearCurrentSession() async {
    try {
      await account.deleteSession(sessionId: 'current');
      LogService.instance.info('Current session cleared');
    } catch (e) {
      // Ignore if no session exists
      LogService.instance.info('No current session to clear');
    }
  }

  // Profile Management
  Future<void> updateName(String newName) async {
    try {
      LogService.instance.info('Updating name to: $newName');

      await account.updateName(name: newName);
      _currentUser = await account.get();

      LogService.instance.info('Name updated successfully');
      notifyListeners();
    } catch (e) {
      LogService.instance.error('Name update failed: $e');
      rethrow;
    }
  }

  Future<void> updateEmail({
    required String newEmail,
    required String password,
  }) async {
    try {
      LogService.instance.info('Updating email to: $newEmail');

      await account.updateEmail(
        email: newEmail,
        password: password,
      );
      _currentUser = await account.get();

      LogService.instance.info('Email updated successfully');
      notifyListeners();
    } catch (e) {
      LogService.instance.error('Email update failed: $e');
      rethrow;
    }
  }

  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      LogService.instance.info('Updating password');

      await account.updatePassword(
        password: newPassword,
        oldPassword: oldPassword,
      );

      LogService.instance.info('Password updated successfully');
    } catch (e) {
      LogService.instance.error('Password update failed: $e');
      rethrow;
    }
  }

  // User Preferences
  Future<Preferences> getUserPreferences() async {
    try {
      return await account.getPrefs();
    } catch (e) {
      LogService.instance.error('Failed to get user preferences: $e');
      rethrow;
    }
  }

  Future<void> updatePreferences(Map<String, dynamic> prefs) async {
    try {
      LogService.instance.info('Updating user preferences');
      await account.updatePrefs(prefs: prefs);
      LogService.instance.info('Preferences updated successfully');
    } catch (e) {
      LogService.instance.error('Failed to update preferences: $e');
      rethrow;
    }
  }

  // Session Management
  Future<String?> getSessionId() async {
    if (_sessionId != null) return _sessionId;

    try {
      final session = await account.getSession(sessionId: 'current');
      _sessionId = session.$id;
      return _sessionId;
    } catch (e) {
      LogService.instance.error('Failed to get session ID: $e');
      return null;
    }
  }
}
