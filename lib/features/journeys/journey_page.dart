import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_state_provider.dart';
import 'package:photojam_app/appwrite/auth/providers/user_role_provider.dart';
import 'package:photojam_app/core/widgets/standard_card.dart';
import 'package:photojam_app/dialogs/signup_journey_dialog.dart';
import 'package:photojam_app/appwrite/database/providers/journey_provider.dart';
import 'package:photojam_app/features/admin/journey_lessons_edit.dart';
import 'package:photojam_app/features/journeys/journey_list.dart';
class JourneyPage extends ConsumerWidget {
  final String? journeyId;
  final String? journeyTitle;
  final bool isEditMode; // Add this

  const JourneyPage({
    super.key,
    this.journeyId,
    this.journeyTitle,
    this.isEditMode = false, // Add this
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userRoleAsync = ref.watch(userRoleProvider);

    // If in edit mode, directly return the edit page
    if (isEditMode && journeyId != null && journeyTitle != null) {
      return JourneyLessonsEditPage(
        journeyId: journeyId!,
        journeyTitle: journeyTitle!,
      );
    }

    return authState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (message) => Center(child: Text('Error: $message')),
      authenticated: (user) {
        return userRoleAsync.when(
          data: (userRole) => _JourneyPageContent(
            userRole: userRole,
            userId: user.id,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
      unauthenticated: () => const Center(child: Text('Not logged in')),
      initial: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _JourneyPageContent extends ConsumerWidget {
  final String userRole;
  final String userId;

  const _JourneyPageContent({
    required this.userRole,
    required this.userId,

  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // // If journeyId is provided, show journey lessons edit page
    // if (journeyId != null && journeyTitle != null) {
    //   return JourneyLessonsEditPage(
    //     journeyId: journeyId!,
    //     journeyTitle: journeyTitle!,
    //   );
    // }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildContent(context, ref),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    if (userRole == 'nonmember') {
      return Column(
        children: [
          Expanded(child: JourneyList(userId: userId, showAllJourneys: false)),
          const SizedBox(height: 20),
          _buildSignUpCard(context, ref),
        ],
      );
    }

    return JourneyList(userId: userId, showAllJourneys: true);
  }

  Widget _buildSignUpCard(BuildContext context, WidgetRef ref) {
    return StandardCard(
      icon: Icons.add_circle_outline,
      title: "Sign Up for a Journey",
      onTap: () => _showSignUpDialog(context, ref),
    );
  }

  Future<void> _showSignUpDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (context) => SignUpJourneyDialog(
        onSignUp: (journeyId) async {
          try {
            await ref.read(journeysProvider.notifier).addParticipant(
              journeyId,
              userId,
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Successfully signed up for journey!')),
              );
              Navigator.pop(context);
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error signing up: $e')),
              );
            }
          }
        },
      ),
    );
  }
}