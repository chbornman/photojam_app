import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_state_provider.dart';
import 'package:photojam_app/appwrite/auth/providers/user_role_provider.dart';
import 'package:photojam_app/appwrite/database/providers/journey_provider.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/core/utils/snackbar_util.dart';

class SignUpJourneyDialog extends ConsumerStatefulWidget {
  final Function(String) onSignUp;

  const SignUpJourneyDialog({
    super.key,
    required this.onSignUp,
  });

  @override
  ConsumerState<SignUpJourneyDialog> createState() =>
      _SignUpJourneyDialogState();
}

class _SignUpJourneyDialogState extends ConsumerState<SignUpJourneyDialog> {
  String? selectedJourneyId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableJourneys();
  }

  Future<void> _loadAvailableJourneys() async {
    try {
      final authState = ref.read(authStateProvider);
      final userRole = await ref.read(userRoleProvider.future);

      authState.whenOrNull(
        authenticated: (user) async {
          if (userRole == 'nonmember') {
            _showError('Access restricted. Please upgrade your membership.');
            return;
          }

          // Load journeys
          await ref.read(journeysProvider.notifier).loadJourneys();

          if (mounted) {
            setState(() => isLoading = false);
          }
        },
      );
    } catch (e) {
      LogService.instance.error('Error fetching available journeys: $e');
      _showError('Failed to load available journeys');
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    setState(() => isLoading = false);
    SnackbarUtil.showErrorSnackBar(context, message);
    Navigator.of(context).pop();
  }

  Future<void> _signUpForJourney() async {
    if (selectedJourneyId == null) return;

    setState(() => isLoading = true);

    try {
      // Call the onSignUp callback
      await widget.onSignUp(selectedJourneyId!);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      LogService.instance.error('Error signing up for journey: $e');
      _showError('Failed to sign up for journey');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AlertDialog(
        content: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Watch all journeys and user's journeys
    final journeysAsync = ref.watch(journeysProvider);
    final authState = ref.watch(authStateProvider);

    return journeysAsync.when(
      data: (allJourneys) {
        // Get user's existing journey IDs
        final userJourneys = authState.whenOrNull(
          authenticated: (user) {
            return ref.watch(userJourneysProvider(user.id));
          },
        );

        // Filter available journeys
        final availableJourneys = userJourneys?.whenOrNull(
              data: (userJourneyList) {
                final userJourneyIds = userJourneyList.map((j) => j.id).toSet();
                return allJourneys
                    .where((journey) => !userJourneyIds.contains(journey.id))
                    .toList();
              },
            ) ??
            allJourneys;

        if (availableJourneys.isEmpty) {
          return AlertDialog(
            title: const Text("No Available Journeys"),
            content: const Text("There are no new journeys available to join."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Close"),
              ),
            ],
          );
        }

        return AlertDialog(
          title: const Text("Sign Up for a Journey"),
          content: DropdownButtonFormField<String>(
            value: selectedJourneyId,
            items: availableJourneys.map<DropdownMenuItem<String>>((journey) {
              return DropdownMenuItem<String>(
                value: journey.id,
                child: Text(journey.title),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => selectedJourneyId = value);
            },
            decoration: const InputDecoration(labelText: "Select Journey"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: selectedJourneyId == null ? null : _signUpForJourney,
              child: const Text("Sign Up"),
            ),
          ],
        );
      },
      loading: () => const AlertDialog(
        content: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => AlertDialog(
        title: const Text("Error"),
        content: Text("Failed to load journeys: $error"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
