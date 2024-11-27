import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/features/auth/login_controller.dart';
import 'package:photojam_app/features/auth/login_form.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_state_provider.dart';
import 'package:photojam_app/appwrite/auth/providers/user_role_provider.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/app.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to auth state changes
    ref.listen(authStateProvider, (previous, next) {
      next.whenOrNull(
        authenticated: (_) async {
          LogService.instance.info('User authenticated, fetching role...');
          
          try {
            // Wait for the role provider to refresh and get the new role
            await Future.delayed(const Duration(milliseconds: 100));
            final roleAsync = await ref.read(userRoleProvider.future);
            LogService.instance.info('User role fetched: $roleAsync');
            
            if (context.mounted) {
              // Navigate to App with the user role
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => App(userRole: roleAsync),
                ),
                (route) => false,
              );
            }
          } catch (e) {
            LogService.instance.error('Error fetching user role: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Error loading user role'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        },
        error: (message) {
          LogService.instance.error('Auth error: $message');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
      );
    });

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    // App logo and welcome section
                    Hero(
                      tag: 'app_logo',
                      child: Center(
                        child: Image.asset(
                          'assets/icon/app_icon_transparent.png',
                          width: 100,
                          height: 100,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Photo Jam',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'The world\'s nicest photo community',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    // Use the LoginForm with the controller from the provider
                    Consumer(
                      builder: (context, ref, _) {
                        final controller = ref.watch(loginControllerProvider);
                        return LoginForm(controller: controller);
                      },
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}