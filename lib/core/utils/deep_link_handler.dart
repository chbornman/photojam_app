import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/auth/providers/user_role_provider.dart';
import 'package:uni_links/uni_links.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_providers.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_state_provider.dart';
import 'package:photojam_app/core/services/log_service.dart';

class DeepLinkHandler {
  static Future<void> initialize(BuildContext context, WidgetRef ref) async {
    // Handle initial URI if app was launched from dead state
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        await _handleDeepLink(initialUri, context, ref);
      }
    } catch (e) {
      LogService.instance.error('Error handling initial deep link: $e');
    }

    // Handle URIs while app is running
    uriLinkStream.listen((Uri? uri) async {
      if (uri != null) {
        await _handleDeepLink(uri, context, ref);
      }
    }, onError: (err) {
      LogService.instance.error('Error handling deep link: $err');
    });
  }

  static Future<void> _handleDeepLink(Uri uri, BuildContext context, WidgetRef ref) async {
    if (uri.path.contains('/verify-membership')) {
      final params = uri.queryParameters;
      final requiredParams = ['teamId', 'membershipId', 'userId', 'secret'];
      
      if (requiredParams.every(params.containsKey)) {
        try {
          final authRepository = ref.read(authRepositoryProvider);
          
          // Get the user before verification to check if it's the current user
          final currentUser = await authRepository.getCurrentUser();
          
          if (currentUser == null) {
            throw Exception('No authenticated user found');
          }
          
          if (currentUser.id != params['userId']) {
            throw Exception('Membership verification is for a different user');
          }
          
          // Verify the membership using Teams functionality from auth repository
          await ref.read(authStateProvider.notifier).checkAuthStatus();
          
          // Invalidate the user role provider to refresh the role
          ref.invalidate(userRoleProvider);
          
          LogService.instance.info('Team membership verified successfully');
          
          // Show success message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Team membership verified successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          LogService.instance.error('Failed to verify membership: $e');
          
          // Show error message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to verify membership: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        LogService.instance.error('Missing required parameters in verification URL');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid verification link: missing parameters'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}