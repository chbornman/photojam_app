// lib/utils/deep_link_handler.dart
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:photojam_app/core/services/team_service.dart';
import 'package:uni_links/uni_links.dart';

class DeepLinkHandler {
  static Future<void> initialize(BuildContext context, Client client) async {
    // Handle initial URI if app was launched from dead state
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        await _handleDeepLink(initialUri, context, client);
      }
    } catch (e) {
      debugPrint('Error handling initial deep link: $e');
    }

    // Handle URIs while app is running
    uriLinkStream.listen((Uri? uri) async {
      if (uri != null) {
        await _handleDeepLink(uri, context, client);
      }
    }, onError: (err) {
      debugPrint('Error handling deep link: $err');
    });
  }

  static Future<void> _handleDeepLink(Uri uri, BuildContext context, Client client) async {
    if (uri.host == 'verify-membership') {
      final userId = uri.queryParameters['userId'];
      final secret = uri.queryParameters['secret'];
      final membershipId = uri.queryParameters['membershipId'];
      final teamId = uri.queryParameters['teamId'];

      if (userId != null && secret != null && membershipId != null && teamId != null) {
        try {
          final teamService = TeamService(client);
          await teamService.verifyMembership(
            teamId: teamId,
            membershipId: membershipId,
            userId: userId,
            secret: secret,
          );
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team membership verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to verify membership: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
