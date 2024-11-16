import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/core/services/log_service.dart';

class RoleService {
  final Client client;
  final Teams _teams;
  final Account _account;

  String? _cachedRole;
  String? _cachedUserId;

  Timer? _debounceTimer;
  bool _isCheckingRole = false;

  final Map<String, int> roleLevels = {
    'nonmember': 0,
    'member': 1,
    'facilitator': 2,
    'admin': 3,
  };

  RoleService(this.client)
      : _teams = Teams(client),
        _account = Account(client) {
    LogService.instance.info('RoleService initialized');
  }

  Future<String> getCurrentUserRole() async {
    // Don't use _authAPI.isAuthenticated here as it might be out of sync
    // Instead, check by trying to get the user
    try {
      final currentUser = await _account.get();
      LogService.instance.info('Current user ID: ${currentUser.$id}');

      if (_cachedUserId == currentUser.$id && _cachedRole != null) {
        LogService.instance.info(
            'Returning cached role: $_cachedRole for user: $_cachedUserId');
        return _cachedRole!;
      }

      _cachedUserId = currentUser.$id;

      try {
        LogService.instance
            .info('Fetching memberships for team: $appwriteTeamId');
        final memberships =
            await _teams.listMemberships(teamId: appwriteTeamId);

        final confirmedMemberships =
            memberships.memberships.where((m) => m.confirm == true).toList();

        LogService.instance
            .info('Found ${confirmedMemberships.length} confirmed memberships');

        if (confirmedMemberships.isEmpty) {
          LogService.instance.info(
              'No confirmed memberships found - setting role to nonmember');
          _cachedRole = 'nonmember';
          return _cachedRole!;
        }

        final highestRole = _determineHighestRole(confirmedMemberships);
        _cachedRole = highestRole;
        LogService.instance.info(
            'Determined user role: $highestRole for user: $_cachedUserId');
        return highestRole;
      } catch (teamError) {
        if (teamError is AppwriteException) {
          LogService.instance.info("""
Team access check failed:
- Code: ${teamError.code}
- Message: ${teamError.message}
This is expected for non-team members
""");
        }
        _cachedRole = 'nonmember';
        LogService.instance
            .info('Setting role to nonmember due to team access restriction');
        return _cachedRole!;
      }
    } catch (e) {
      LogService.instance.info('Not authenticated, returning nonmember role');
      _cachedRole = 'nonmember';
      _cachedUserId = null;
      return 'nonmember';
    }
  }

  Future<void> _waitForRoleCheck() {
    final completer = Completer<void>();

    void checkComplete() {
      if (!_isCheckingRole) {
        completer.complete();
      } else {
        // Check again in 100ms
        _debounceTimer =
            Timer(const Duration(milliseconds: 100), checkComplete);
      }
    }

    checkComplete();
    return completer.future;
  }

  String _determineHighestRole(List<Membership> memberships) {
    LogService.instance.info('Determining highest role from memberships');

    int highestLevel = 0;
    String highestRole = 'nonmember';

    for (var membership in memberships) {
      LogService.instance.info('Checking roles: ${membership.roles}');
      for (var role in membership.roles) {
        final level = roleLevels[role] ?? 0;
        if (level > highestLevel) {
          highestLevel = level;
          highestRole = role;
          LogService.instance
              .info('New highest role: $highestRole (level $highestLevel)');
        }
      }
    }

    return highestRole;
  }

  Future<void> clearRoleCache() async {
    LogService.instance.info('Clearing role cache and user ID');
    _debounceTimer?.cancel();
    _cachedRole = null;
    _cachedUserId = null;
  }

  Future<void> handleSignOut() async {
    LogService.instance
        .info('Handling sign out - clearing role cache and user ID');
    await clearRoleCache();
  }

  Future<void> handleSignIn() async {
    LogService.instance
        .info('Handling sign in - clearing role cache to force refresh');
    await clearRoleCache();
  }

  Future<bool> hasPermission(String requiredRole) async {
    final userRole = await getCurrentUserRole();
    final hasPermission =
        (roleLevels[userRole] ?? 0) >= (roleLevels[requiredRole] ?? 0);
    LogService.instance
        .info('Permission check: $userRole >= $requiredRole = $hasPermission');
    return hasPermission;
  }

  Future<void> verifyMembership({
    required String teamId,
    required String membershipId,
    required String userId,
    required String secret,
  }) async {
    LogService.instance.info("""
Verifying membership:
- Team ID: $teamId
- Membership ID: $membershipId
- User ID: $userId
""");

    try {
      await _teams.updateMembershipStatus(
        teamId: teamId,
        membershipId: membershipId,
        userId: userId,
        secret: secret,
      );
      LogService.instance.info('Membership verified successfully');
      await clearRoleCache();
      LogService.instance.info('Role cache cleared after verification');
    } catch (e) {
      if (e is AppwriteException) {
        LogService.instance.error("""
Membership Verification Error:
- Code: ${e.code}
- Message: ${e.message}
- Type: ${e.type}
""");

        if (e.code == 404) {
          throw Exception(
              'Invalid verification link. Please request a new invitation.');
        } else if (e.code == 401) {
          throw Exception('Unauthorized. Please make sure you\'re logged in.');
        }
      }
      LogService.instance.error('Unexpected error in verifyMembership: $e');
      rethrow;
    }
  }

  // Add these getters
  bool get isAdmin => _cachedRole == 'admin';
  bool get isFacilitator => _cachedRole == 'facilitator' || isAdmin;
  String get currentUserId => _cachedUserId ?? '';
}
