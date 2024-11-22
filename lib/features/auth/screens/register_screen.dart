import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/features/auth/controllers/register_controller.dart';
import 'package:photojam_app/features/auth/widgets/register_form.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_state_provider.dart';
import 'package:photojam_app/appwrite/auth/providers/user_role_provider.dart';
import 'package:photojam_app/app.dart';

class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to auth state changes for navigation after successful registration
    ref.listen(authStateProvider, (previous, next) {
      next.whenOrNull(
        authenticated: (_) async {
          // Get user role after successful authentication
          final roleAsync = await ref.read(userRoleProvider.future);

          if (context.mounted) {
            // Navigate to App with the user role, replacing the entire stack
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => App(userRole: roleAsync),
              ),
              (route) => false, // This removes all previous routes
            );
          }
        },
        error: (message) {
          // Show error message
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

    final registerController = RegisterController(ref);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Header section
                    Text(
                      'Create Account',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join our community and start sharing your moments',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onBackground
                                .withOpacity(0.7),
                          ),
                    ),
                    const SizedBox(height: 48),
                    // Registration form
                    RegisterForm(controller: registerController),
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
