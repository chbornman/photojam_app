import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/core/services/log_service.dart';

class TeamService {
  final Teams teams;
  final Client client;

  TeamService(this.client) : teams = Teams(client);

  Future<List<Membership>> getTeamMembers(String teamId) async {
    try {
      final result = await teams.listMemberships(teamId: teamId);
      return result.memberships;
    } catch (e) {
      LogService.instance.error('Error getting team members: $e');
      rethrow;
    }
  }

  /// New function to fetch all facilitators from the team
  Future<List<Membership>> getFacilitators(String teamId) async {
    try {
      LogService.instance.info('Fetching facilitators for team $teamId');
      final teamMembers = await getTeamMembers(teamId);

      // Filter members with the role "facilitator"
      final facilitators = teamMembers.where((member) {
        return member.roles.contains('facilitator');
      }).toList();

      LogService.instance.info(
          'Found ${facilitators.length} facilitators in team $teamId');
      return facilitators;
    } catch (e) {
      LogService.instance.error('Error fetching facilitators: $e');
      rethrow;
    }
  }

  Future<void> addMember({
    required String teamId,
    required String email,
    required List<String> roles,
    int retryDelaySeconds = 2,
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        await teams.createMembership(
          teamId: teamId,
          email: email,
          roles: roles,
          url: appDeepLinkUrl,
        );
        LogService.instance.info(
            "Invitation sent to $email for team $teamId with roles $roles");
        return;
      } catch (e) {
        if (e is AppwriteException && e.code == 429 && attempts < maxRetries - 1) {
          LogService.instance.info("Rate limit hit, waiting before retry");
          await Future.delayed(Duration(seconds: retryDelaySeconds));
          attempts++;
        } else {
          LogService.instance.error("Error adding member to team: $e");
          rethrow;
        }
      }
    }
  }

  Future<void> verifyMembership({
    required String teamId,
    required String membershipId,
    required String userId,
    required String secret,
  }) async {
    try {
      await teams.updateMembershipStatus(
        teamId: teamId,
        membershipId: membershipId,
        userId: userId,
        secret: secret,
      );
      LogService.instance.info("Verified membership for user $userId");
    } catch (e) {
      LogService.instance.error('Error verifying membership: $e');
      rethrow;
    }
  }

  Future<void> removeMember({
    required String teamId,
    required String membershipId,
  }) async {
    try {
      await teams.deleteMembership(
        teamId: teamId,
        membershipId: membershipId,
      );
      LogService.instance.info(
          "Removed member $membershipId from team $teamId");
    } catch (e) {
      LogService.instance.error('Error removing member from team: $e');
      rethrow;
    }
  }

  Future<void> updateMemberRoles({
    required String teamId,
    required String membershipId,
    required List<String> roles,
  }) async {
    try {
      await teams.updateMembership(
        teamId: teamId,
        membershipId: membershipId,
        roles: roles,
      );
      LogService.instance.info(
          "Updated member $membershipId roles to $roles");
    } catch (e) {
      LogService.instance.error('Error updating member roles: $e');
      rethrow;
    }
  }
}