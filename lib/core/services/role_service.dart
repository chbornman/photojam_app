import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/core/services/log_service.dart';

class RoleService {
  final Client client;
  final Teams _teams;
  final Account _account;
  String? _cachedRole;

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
    LogService.instance.info('getCurrentUserRole called');

    if (_cachedRole != null) {
      LogService.instance.info('Returning cached role: $_cachedRole');
      return _cachedRole!;
    }

    try {
      LogService.instance
          .info('Fetching memberships for team: $appwriteTeamId');
      final memberships = await _teams.listMemberships(teamId: appwriteTeamId);

      final confirmedMemberships =
          memberships.memberships.where((m) => m.confirm == true).toList();

      LogService.instance
          .info('Found ${confirmedMemberships.length} confirmed memberships');

      if (confirmedMemberships.isEmpty) {
        LogService.instance
            .info('No confirmed memberships found - user is nonmember');
        _cachedRole = 'nonmember';
        return _cachedRole!;
      }

      final highestRole = _determineHighestRole(confirmedMemberships);
      _cachedRole = highestRole;
      LogService.instance.info('Determined user role: $highestRole');
      return highestRole;
    } catch (e) {
      if (e is AppwriteException) {
        LogService.instance.error("""
AppwriteException in getCurrentUserRole:
- Code: ${e.code}
- Message: ${e.message}
- Type: ${e.type}
""");

        if (e.code == 401 || e.code == 404) {
          _cachedRole = 'nonmember';
          return _cachedRole!;
        }
      }

      LogService.instance.error('Unexpected error getting user role: $e');
      _cachedRole = 'nonmember';
      return _cachedRole!;
    }
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
      // Verify the membership with Appwrite
      await _teams.updateMembershipStatus(
        teamId: teamId,
        membershipId: membershipId,
        userId: userId,
        secret: secret,
      );
      LogService.instance.info('Membership verified successfully');

      // Clear the role cache to force a refresh
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

  Future<void> clearRoleCache() async {
    LogService.instance.info('Clearing role cache');
    _cachedRole = null;
  }

  Future<bool> hasPermission(String requiredRole) async {
    final userRole = await getCurrentUserRole();
    final hasPermission =
        (roleLevels[userRole] ?? 0) >= (roleLevels[requiredRole] ?? 0);
    LogService.instance
        .info('Permission check: $userRole >= $requiredRole = $hasPermission');
    return hasPermission;
  }
}
