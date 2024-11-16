import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:provider/provider.dart';

class DeepLinkHandler {
  static Future<void> handleDeepLink(Uri uri, BuildContext context) async {
    LogService.instance.info("Handling deep link: ${uri.toString()}");

    switch (uri.host) {
      case 'verify-membership':
        await _handleMembershipVerification(uri, context);
        break;
      // Add other deep link types here
      default:
        LogService.instance.info("Unknown deep link host: ${uri.host}");
    }
  }

  static Future<void> _handleMembershipVerification(
      Uri uri, BuildContext context) async {
    final params = uri.queryParameters;
    final userId = params['userId'];
    final secret = params['secret'];
    final membershipId = params['membershipId'];
    final teamId = params['teamId'];

    if (_validateMembershipParams(params)) {
      try {
        final authAPI = Provider.of<AuthAPI>(context, listen: false);
        await authAPI.roleService.verifyMembership(
          teamId: teamId!,
          membershipId: membershipId!,
          userId: userId!,
          secret: secret!,
        );

        _showSuccessMessage(context);
      } catch (e) {
        LogService.instance.error("Membership verification error: $e");
        _showErrorMessage(context, e);
      }
    } else {
      LogService.instance.error("Invalid membership verification parameters");
      _showErrorMessage(context, "Invalid verification link");
    }
  }

  static bool _validateMembershipParams(Map<String, String?> params) {
    return params['userId'] != null &&
        params['secret'] != null &&
        params['membershipId'] != null &&
        params['teamId'] != null;
  }

  static void _showSuccessMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Team membership verified successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  static void _showErrorMessage(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to verify membership: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
