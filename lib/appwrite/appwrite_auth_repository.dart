import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:photojam_app/appwrite/auth/models/user_model.dart';
import 'package:photojam_app/appwrite/auth/repositories/auth_repository.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/core/services/log_service.dart';

class AppwriteAuthRepository implements AuthRepository {
  final Account _account;
  final Teams _teams;
  final Client _client;  // Add this

  AppwriteAuthRepository(this._account, this._teams, this._client);  // Update constructor

  @override
  Future<AppUser> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final user = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      return AppUser.fromAccount(user);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  @override
  Future<AppUser> signIn(
      {required String email, required String password}) async {
    try {
      // Create session and store it
      final session = await _account.createEmailPasswordSession(
          email: email, password: password);

      // Get user details
      final user = await _account.get();

      // Set the session on the client
      _client.setSession(session.$id); // Add this line

      return AppUser.fromAccount(user);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    try {
      final user = await _account.get();
      return AppUser.fromAccount(user);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String> getUserRole() async {
    String userRole = 'nonmember';

    try {
      final currentUser = await _account.get();
      LogService.instance.info('Current user ID: ${currentUser.$id}');

      LogService.instance.info(
          'Fetching memberships for team: ${AppConstants.appwriteTeamId}');
      final memberships =
          await _teams.listMemberships(teamId: AppConstants.appwriteTeamId);

      final confirmedMemberships =
          memberships.memberships.where((m) => m.confirm == true).toList();

      LogService.instance
          .info('Found ${confirmedMemberships.length} confirmed memberships');

      if (confirmedMemberships.isEmpty) {
        LogService.instance
            .info('No confirmed memberships found - setting role to nonmember');
        userRole = 'nonmember';
      } else {
        for (var membership in confirmedMemberships) {
          if (membership.userId == currentUser.$id) {
            LogService.instance.info('User is a member of the team');

            // Check the roles in the membership
            final roles = membership.roles;

            if (roles.contains('admin')) {
              LogService.instance.info('User has admin role');
              userRole = 'admin';
            } else if (roles.contains('facilitator')) {
              LogService.instance.info('User has facilitator role');
              userRole = 'facilitator';
            } else if (roles.contains('member')) {
              LogService.instance.info('User has member role');
              userRole = 'member';
            } else {
              LogService.instance.info(
                  'User is confirmed but has no recognized roles - setting to member');
              userRole =
                  'member'; //TODO check if this should be nonmember instead
            }
            break;
          }
        }
      }
    } catch (e) {
      LogService.instance.info('Not authenticated, returning nonmember role');
      userRole = 'nonmember';
    }

    return userRole;
  }

  @override
  Future<void> sendVerificationEmail() async {
    try {
      await _account.createVerification(
        url: 'https://yourapp.com/verify-email', // Configure this
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _account.createRecovery(
        email: email,
        url: 'https://yourapp.com/reset-password', // Configure this
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  @override
  Future<void> updatePassword(String password) async {
    try {
      await _account.updatePassword(password: password);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  @override
  Future<void> updateName(String name) async {
    try {
      await _account.updateName(name: name);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  @override
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      await _account.updatePrefs(prefs: preferences);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Exception _handleAuthError(dynamic e) {
    if (e is AppwriteException) {
      return Exception(e.message);
    }
    return Exception('An unexpected error occurred');
  }

  @override
  Future<List<String>> getUserTeams(String userId) async {
    try {
      // First get the list of teams
      final teams = await _teams.list();
      List<String> userTeams = [];

      // For each team, check if the user is a member
      for (var team in teams.teams) {
        try {
          await _teams.getMembership(
            teamId: team.$id,
            membershipId:
                userId, // This might need adjustment based on your membership structure
          );
          userTeams.add(team.$id);
        } catch (e) {
          // If user is not a member of this team, skip it
          continue;
        }
      }

      return userTeams;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  @override
  Future<Session> getCurrentSession() async {
    try {
      final session = await _account.getSession(sessionId: 'current');
      return session;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }
}
