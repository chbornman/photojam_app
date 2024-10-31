import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/widgets.dart';

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
      print('Authenticated user ID: $userid');
      print('username: $username');
    }).catchError((error) {
      print('Error loading user: $error');
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
      print("Attempting to create user with email: $email");

      // Create the user with email, password, and name only
      final user = await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      print("User created successfully with ID: ${user.$id}");

      // Return the created user without setting a role
      return user;
    } on AppwriteException catch (e) {
      // Log specific details about the exception
      print("AppwriteException: ${e.message}");
      print("Status Code: ${e.code}");
      print("Response: ${e.response}");

      // Propagate the exception after logging
      rethrow;
    } catch (e) {
      print("Unexpected error: $e");
      rethrow;
    }
  }

  Future<String?> getUserRole() async {
    try {
      final prefs = await account.getPrefs();
      return prefs.data['role'] as String?;
    } catch (e) {
      print("Error retrieving user role: $e");
      return null;
    }
  }

  Future<void> setRole(String role) async {
    // Check if the user is logged in
    if (_status != AuthStatus.authenticated) {
      print("User is not logged in. Unable to set role.");
      throw Exception("User must be logged in to set a role.");
    }

    try {
      print("Setting user role to: $role");

      // Update the role in user preferences
      await account.updatePrefs(prefs: {'role': role});

      // Verify that the role was saved correctly
      final prefs = await account.getPrefs();
      if (prefs.data['role'] == role) {
        print("Role set successfully: ${prefs.data['role']}");
      } else {
        print(
            "Role verification failed. Expected: $role, Found: ${prefs.data['role']}");
        throw Exception("Role verification failed after setting.");
      }
    } on AppwriteException catch (e) {
      // Log detailed Appwrite-related errors for troubleshooting
      print("AppwriteException: ${e.message}");
      print("Status Code: ${e.code}");
      print("Response: ${e.response}");

      // Re-throw the exception for further handling
      rethrow;
    } catch (e) {
      // Handle any unexpected errors
      print("Unexpected error in setRole: $e");
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
        print("Existing session deleted.");
      } catch (e) {
        print("No existing session to delete or deletion failed: $e");
      }

      // Create a new session
      final session = await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      _currentUser =
          await account.get(); // Get user details for the new session
      _status = AuthStatus.authenticated;
      return session;
    } on AppwriteException catch (e) {
      print("Login failed: ${e.message}");
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

  // Method to update the user's name
  Future<void> updateName(String newName) async {
    try {
      await account.updateName(name: newName);
      _currentUser = await account.get(); // Refresh current user data
      notifyListeners(); // Notify listeners of the change
    } catch (e) {
      print("Error updating name: $e");
      rethrow;
    }
  }

  // Method to update the user's password
  Future<void> updatePassword(
      String currentPassword, String newPassword) async {
    try {
      await account.updatePassword(
          password: newPassword, oldPassword: currentPassword);
      notifyListeners(); // Notify listeners if there's any UI dependency
    } catch (e) {
      print("Error updating password: $e");
      rethrow;
    }
  }

  // Method to check if the user is connected via OAuth
  bool isOAuthUser() {
    return _currentUser != null && _currentUser!.emailVerification == false;
  }

  // Method to update the user's email
  Future<void> updateEmail(String newEmail, String currentPassword) async {
    try {
      await account.updateEmail(email: newEmail, password: currentPassword);
      _currentUser = await account.get(); // Refresh current user data
      notifyListeners();
    } catch (e) {
      print("Error updating email: $e");
      rethrow;
    }
  }

  // Method to retrieve the current user's username
  Future<String?> getUsername() async {
    try {
      // Retrieve the user's account details
      User user = await account.get();

      // Assuming "name" is used as the username
      return user
          .name; // Replace 'name' with 'username' if you use a custom field
    } catch (e) {
      print("Error retrieving username: $e");
      return null;
    }
  }

  /// Retrieves the current session token or creates a new session if needed
  Future<String?> getToken() async {
    if (_authToken != null) {
      return _authToken; // Return the cached token if it exists
    }

    try {
      final session = await account.getSession(sessionId: 'current');
      _authToken = session.$id; // Use the session ID as token
    } catch (e) {
      print('No active session found, creating a new one.');
      // If there is no active session, create a new session here
      // Ensure credentials are provided, for example:
      final email = "user@example.com"; // Replace with user's email
      final password = "user_password"; // Replace with user's password

      try {
        final session = await account.createEmailPasswordSession(
          email: email,
          password: password,
        );
        _authToken = session.$id;
        _currentUser = await account.get(); // Refresh user data
        _status = AuthStatus.authenticated;
      } catch (e) {
        print("Failed to create session: $e");
        _status = AuthStatus.unauthenticated;
      }
    }

    notifyListeners();
    return _authToken;
  }
}
