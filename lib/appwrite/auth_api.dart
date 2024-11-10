import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/widgets.dart';
import 'package:photojam_app/log_service.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class AuthAPI extends ChangeNotifier {
  final Client client;
  final Account account;

  User? _currentUser;
  AuthStatus _status = AuthStatus.uninitialized;
  String? _authToken; // Add a field to store the token

  // Constructor with injected client
  AuthAPI(this.client) : account = Account(client) {
    loadUser().then((_) {
      LogService.instance.info('Authenticated user ID: $userid');
      LogService.instance.info('username: $username');
    }).catchError((error) {
      LogService.instance.error('Error loading user: $error');
    });
  }

  // getters
  String? get userid => _currentUser?.$id;
  String? get email => _currentUser?.email;
  String? get username => _currentUser?.name;
  AuthStatus get status => _status;

  /// Fetch user information with retry logic and set authentication status
  loadUser() async {
    try {
      final user = await account.get();
      _status = AuthStatus.authenticated;
      _currentUser = user;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  /// Ensures that the user ID is available by loading the user if necessary
  Future<String?> fetchUserId() async {
    if (_currentUser == null) {
      await loadUser();
    }
    return userid;
  }

  Future<User> createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      LogService.instance.info("Attempting to create user with email: $email");

      // Create the user with email, password, and name only
      final user = await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      LogService.instance.info("User created successfully with ID: ${user.$id}");

      // Return the created user without setting a role
      return user;
    } on AppwriteException catch (e) {
      // Log specific details about the exception
      LogService.instance.error("AppwriteException: ${e.message}");
      LogService.instance.error("Status Code: ${e.code}");
      LogService.instance.error("Response: ${e.response}");

      // Propagate the exception after logging
      rethrow;
    } catch (e) {
      LogService.instance.error("Unexpected error: $e");
      rethrow;
    }
  }

  Future<String?> getUserRole() async {
    try {
      final prefs = await account.getPrefs();
      // Additional Debug: Print retrieved role
      final role = prefs.data['role'] as String?;
      LogService.instance.info("Retrieved user role: $role");
      return role;
    } catch (e) {
      // Debug: Role retrieval failed or not set
      LogService.instance.error("Error retrieving user role or role not set in preferences.");
      return null;
    }
  }

  Future<void> setRole(String role) async {
    if (_status != AuthStatus.authenticated) {
      LogService.instance.info("User is not logged in. Unable to set role.");
      throw Exception("User must be logged in to set a role.");
    }

    try {
      LogService.instance.info("Setting user role to: $role");

      // Update the role in user preferences
      await account.updatePrefs(prefs: {'role': role});

      // Verify that the role was saved correctly
      final prefs = await account.getPrefs();
      if (prefs.data['role'] == role) {
        LogService.instance.info("Role set successfully: ${prefs.data['role']}");
      } else {
        LogService.instance.info("Role verification failed. Expected: $role, Found: ${prefs.data['role']}");
        throw Exception("Role verification failed after setting.");
      }
    } on AppwriteException catch (e) {
      LogService.instance.error("AppwriteException: ${e.message}");
      LogService.instance.error("Status Code: ${e.code}");
      LogService.instance.error("Response: ${e.response}");
      rethrow;
    } catch (e) {
      LogService.instance.error("Unexpected error in setRole: $e");
      rethrow;
    }
  }

  Future<Session?> createEmailPasswordSession({
    required String email,
    required String password,
  }) async {
    try {
      // Attempt to delete any existing session
      try {
        await account.deleteSession(sessionId: 'current');
        LogService.instance.info("Existing session deleted.");
      } catch (e) {
        LogService.instance.error("No existing session to delete or deletion failed: $e");
      }

      // Create a new session
      final session = await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      
      // Additional Debug: Print session details to verify session creation
      LogService.instance.info("Session created successfully: Session ID: ${session.$id}");
      _currentUser = await account.get(); // Get user details for the new session
      _status = AuthStatus.authenticated;
      LogService.instance.info("User authenticated successfully. User ID: ${_currentUser?.$id}, Status: $_status");
      return session;
    } on AppwriteException catch (e) {
      LogService.instance.error("Login failed: ${e.message}");
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  signInWithProvider({required OAuthProvider provider}) async {
    try {
      final session = await account.createOAuth2Session(provider: provider);
      _currentUser = await account.get();
      _status = AuthStatus.authenticated;
      return session;
    } finally {
      notifyListeners();
    }
  }

  signOut() async {
    try {
      await account.deleteSession(sessionId: 'current');
      _status = AuthStatus.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  Future<Preferences> getUserPreferences() async {
    return await account.getPrefs();
  }

  updatePreferences({required String bio}) async {
    return account.updatePrefs(prefs: {'bio': bio});
  }

  Future<void> updateName(String newName) async {
    try {
      await account.updateName(name: newName);
      _currentUser = await account.get(); // Refresh current user data
      notifyListeners(); // Notify listeners of the change
    } catch (e) {
      LogService.instance.error("Error updating name: $e");
      rethrow;
    }
  }

  Future<void> updatePassword(
      String currentPassword, String newPassword) async {
    try {
      await account.updatePassword(
          password: newPassword, oldPassword: currentPassword);
      notifyListeners(); // Notify listeners if there’s any UI dependency
    } catch (e) {
      LogService.instance.error("Error updating password: $e");
      rethrow;
    }
  }

  bool isOAuthUser() {
    return _currentUser != null && _currentUser!.emailVerification == false;
  }

  Future<void> updateEmail(String newEmail, String currentPassword) async {
    try {
      await account.updateEmail(email: newEmail, password: currentPassword);
      _currentUser = await account.get(); // Refresh current user data
      notifyListeners();
    } catch (e) {
      LogService.instance.error("Error updating email: $e");
      rethrow;
    }
  }

  Future<String?> getUsername() async {
    try {
      User user = await account.get();
      return user.name; 
    } catch (e) {
      LogService.instance.error("Error retrieving username: $e");
      return null;
    }
  }

  Future<String?> getToken() async {
    if (_authToken != null) {
      return _authToken;
    }

    try {
      final session = await account.getSession(sessionId: 'current');
      _authToken = session.$id;
    } catch (e) {
      LogService.instance.error('No active session found, creating a new one.');
      final email = "user@example.com";
      final password = "user_password";

      try {
        final session = await account.createEmailPasswordSession(
          email: email,
          password: password,
        );
        _authToken = session.$id;
        _currentUser = await account.get();
        _status = AuthStatus.authenticated;
      } catch (e) {
        LogService.instance.error("Failed to create session: $e");
        _status = AuthStatus.unauthenticated;
      }
    }

    notifyListeners();
    return _authToken;
  }
}