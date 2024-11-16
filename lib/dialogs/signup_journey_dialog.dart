import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/core/services/role_service.dart';
import 'package:photojam_app/features/journeys/providers/journey_provider.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/core/services/log_service.dart';

class SignUpJourneyDialog extends StatefulWidget {
  final JourneyProvider journeyProvider;

  const SignUpJourneyDialog({
    super.key,
    required this.journeyProvider,
  });

  @override
  State<SignUpJourneyDialog> createState() => _SignUpJourneyDialogState();
}

class _SignUpJourneyDialogState extends State<SignUpJourneyDialog> {
  String? selectedJourneyId;
  bool isLoading = true;
  List<Map<String, dynamic>> availableJourneys = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableJourneys();
  }

  Future<void> _loadAvailableJourneys() async {
    try {
      final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
      final auth = Provider.of<AuthAPI>(context, listen: false);
      final roleService = Provider.of<RoleService>(context, listen: false);

      final userId = auth.userId;
      if (userId == null) {
        _showError('User not logged in');
        return;
      }

      // Check user role
      final userRole = await roleService.getCurrentUserRole();
      LogService.instance.info('User role: $userRole');

      if (userRole == 'nonmember') {
        _showError('Access restricted. Please upgrade your membership.');
        return;
      }

      // Get all active journeys
      final allJourneys = await databaseApi.getAllActiveJourneys();

      // Get user's current journeys
      final userJourneys = await databaseApi.getJourneysByUser(userId);
      final userJourneyIds = userJourneys.documents.map((doc) => doc.$id).toSet();

      // Filter out journeys user is already part of
      availableJourneys = allJourneys.documents
          .where((journey) => !userJourneyIds.contains(journey.$id))
          .map((doc) => {
                'id': doc.$id,
                'title': doc.data['title'] ?? 'Untitled Journey',
              })
          .toList();

      if (availableJourneys.isNotEmpty) {
        selectedJourneyId = availableJourneys.first['id'];
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      LogService.instance.error('Error fetching available journeys: $e');
      _showError('Failed to load available journeys');
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Navigator.of(context).pop();
  }

  Future<void> _signUpForJourney() async {
    if (selectedJourneyId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
      final auth = Provider.of<AuthAPI>(context, listen: false);
      final userId = auth.userId;

      if (userId == null) {
        _showError('User not logged in');
        return;
      }

      await databaseApi.addUserToJourney(selectedJourneyId!, userId);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully signed up for the journey!')),
      );

      // Refresh journeys list
      await widget.journeyProvider.loadUserJourneys(userId);

      Navigator.of(context).pop();
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
            value: journey['id'] as String,
            child: Text(journey['title']),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedJourneyId = value;
          });
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
  }
}
