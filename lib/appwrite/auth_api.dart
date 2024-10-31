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

  // Constructor with injected client
  AuthAPI(this.client) : account = Account(client) {
    loadUser().then((_) {
      print('Authenticated user ID: $userid');
    }).catchError((error) {
      print('Error loading user: $error');
    });
  }

  // getters
  String? get userid => _currentUser?.$id;
  String? get email => _currentUser?.email;
  String? get username => _currentUser?.name;
  AuthStatus get status => _status;

  /// Fetch user information and set authentication status
  Future<User?> loadUser() async {
    try {
      final user = await account.get();
      _status = AuthStatus.authenticated;
      _currentUser = user;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
    } finally {
      notifyListeners();
    }
    return _currentUser;
  }

  /// Ensures that the user ID is available by loading the user if necessary
  Future<String?> fetchUserId() async {
    if (_currentUser == null) {
      await loadUser();
    }
    return userid;
  }

  Future<User> createUser(
      {required String name,
      required String email,
      required String password}) async {
    try {
      final user = await account.create(
          userId: ID.unique(), email: email, password: password, name: name);
      return user;
    } finally {
      notifyListeners();
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
}
