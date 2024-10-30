import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:flutter/widgets.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class AuthAPI extends ChangeNotifier {
  Client client = Client();
  late final Account account;

  User? _currentUser;
  AuthStatus _status = AuthStatus.uninitialized;

  // Getter methods
  User? get currentUser => _currentUser;
  AuthStatus get status => _status;
  String? get username => _currentUser?.name;
  String? get email => _currentUser?.email;
  String? get userid => _currentUser?.$id;

  // Constructor
  AuthAPI() {
    init();
    loadUser().then((_) {
      print('Authenticated user ID: $userid'); // Debug print
    });
  }

  // Initialize the Appwrite client
  void init() {
    client
        .setEndpoint(APPWRITE_URL)
        .setProject(APPWRITE_PROJECT_ID)
        .setSelfSigned();
    account = Account(client);
  }

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
      {required String email, required String password}) async {
    try {
      final user = await account.create(
          userId: ID.unique(), email: email, password: password, name: 'Cal B');
      return user;
    } finally {
      notifyListeners();
    }
  }

  Future<Session> createEmailPasswordSession(
      {required String email, required String password}) async {
    try {
      final session = await account.createEmailPasswordSession(
          email: email, password: password);
      _currentUser = await account.get();
      _status = AuthStatus.authenticated;
      return session;
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
  Future<void> updatePassword(String newPassword) async {
    try {
      await account.updatePassword(password: newPassword);
      notifyListeners(); // Notify listeners if there's any UI dependency
    } catch (e) {
      print("Error updating password: $e");
      rethrow;
    }
  }
}
