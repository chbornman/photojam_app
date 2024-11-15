// lib/services/role_service.dart
import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:photojam_app/log_service.dart';

class RoleService {
  final Client client;
  final Teams teams;
  final Account account;
  final Databases databases;

  RoleService(this.client) 
    : teams = Teams(client),
      account = Account(client),
      databases = Databases(client);

  // Define role levels
  static const Map<String, int> roleLevels = {
    'nonmember': 0,
    'member': 1,
    'facilitator': 2,
    'admin': 3,
  };

  // Get current user's role
  Future<String> getCurrentUserRole() async {
    try {
      LogService.instance.info("Getting current user role");
      final memberships = await teams.listMemberships(
        teamId: appwriteTeamId,  // Use your constant
      );

      if (memberships.memberships.isEmpty) {
        LogService.instance.info("No team memberships found - user is nonmember");
        return 'nonmember';
      }

      // Get highest role level
      int highestLevel = 0;
      String highestRole = 'nonmember';

      for (var membership in memberships.memberships) {
        for (var role in membership.roles) {
          final level = roleLevels[role] ?? 0;
          if (level > highestLevel) {
            highestLevel = level;
            highestRole = role;
          }
        }
      }

      LogService.instance.info("Current user role: $highestRole");
      return highestRole;
    } catch (e) {
      LogService.instance.error("Error getting user role: $e");
      return 'nonmember';
    }
  }

  // Check if user has minimum role level
  Future<bool> hasMinimumRole(String requiredRole) async {
    try {
      final userRole = await getCurrentUserRole();
      final userLevel = roleLevels[userRole] ?? 0;
      final requiredLevel = roleLevels[requiredRole] ?? 0;
      return userLevel >= requiredLevel;
    } catch (e) {
      LogService.instance.error("Error checking minimum role: $e");
      return false;
    }
  }

  // Request member role (for nonmembers)
  Future<void> requestMemberRole() async {
    try {
      LogService.instance.info("Requesting member role");
      final currentRole = await getCurrentUserRole();
      if (currentRole != 'nonmember') {
        throw Exception('User already has a role higher than nonmember');
      }

      await teams.createMembership(
        teamId: appwriteTeamId,
        roles: ['member'],
      );
      LogService.instance.info("Member role granted successfully");
    } catch (e) {
      LogService.instance.error("Error requesting member role: $e");
      rethrow;
    }
  }

  // Request facilitator role (for members)
  Future<void> requestFacilitatorRole() async {
    try {
      LogService.instance.info("Requesting facilitator role");
      final currentRole = await getCurrentUserRole();
      if (currentRole != 'member') {
        throw Exception('Only members can request facilitator role');
      }

      await databases.createDocument(
        databaseId: appwriteDatabaseId,  // Use your constant
        collectionId: 'facilitator-requests', // You might want to add this to constants
        documentId: ID.unique(),
        data: {
          'userId': (await account.get()).$id,
          'status': 'pending',
          'requestDate': DateTime.now().toIso8601String(),
        },
      );
      LogService.instance.info("Facilitator role request submitted");
    } catch (e) {
      LogService.instance.error("Error requesting facilitator role: $e");
      rethrow;
    }
  }

  // Admin Functions
  Future<List<UserData>> getAllUsers() async {
    try {
      LogService.instance.info("Getting all users");
      if (!await hasMinimumRole('admin')) {
        throw Exception('Unauthorized: Admin access required');
      }

      final memberships = await teams.listMemberships(
        teamId: appwriteTeamId,
      );

      return memberships.memberships.map((membership) => UserData(
        userId: membership.userId,
        email: membership.userEmail,
        name: membership.userName,
        roles: List<String>.from(membership.roles),
        membershipId: membership.$id,
      )).toList();
    } catch (e) {
      LogService.instance.error("Error getting all users: $e");
      rethrow;
    }
  }
}

// User data class
class UserData {
  final String userId;
  final String email;
  final String name;
  final List<String> roles;
  final String membershipId;

  UserData({
    required this.userId,
    required this.email,
    required this.name,
    required this.roles,
    required this.membershipId,
  });
}