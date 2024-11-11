import 'package:flutter/material.dart';
import 'package:photojam_app/log_service.dart';
import 'package:photojam_app/utilities/userdataprovider.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/pages/journeys/myjourneys_page.dart';
import 'package:photojam_app/utilities/standard_card.dart';

class JourneyPage extends StatefulWidget {
  const JourneyPage({super.key});

  @override
  _JourneyPageState createState() => _JourneyPageState();
}

class _JourneyPageState extends State<JourneyPage> {
  late DatabaseAPI databaseApi;
  late StorageAPI storageApi;
  late AuthAPI auth;
  bool dependenciesInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!dependenciesInitialized) {
      databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
      storageApi = Provider.of<StorageAPI>(context, listen: false);
      auth = Provider.of<AuthAPI>(context, listen: false);
      dependenciesInitialized = true;
    }
  }

  Future<void> _openSignUpForJourneyDialog() async {
    try {
      final userId = auth.userid;

      final allJourneys = await databaseApi.getAllActiveJourneys();
      final userJourneys = await databaseApi.getJourneysByUser(userId!);

      final userJourneyIds =
          userJourneys.documents.map((doc) => doc.$id).toSet();
      final availableJourneys = allJourneys.documents
          .where((journey) => !userJourneyIds.contains(journey.$id))
          .toList();

      if (availableJourneys.isEmpty) {
        _showMessage("No available journeys to sign up for.");
        return;
      }

      String? selectedJourneyId = availableJourneys.first.$id;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Sign Up for a Journey"),
            content: DropdownButtonFormField<String>(
              value: selectedJourneyId,
              items: availableJourneys.map((journey) {
                return DropdownMenuItem(
                  value: journey.$id,
                  child: Text(journey.data['title'] ?? "Untitled Journey"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedJourneyId = value;
                });
              },
              decoration: InputDecoration(labelText: "Select Journey"),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (selectedJourneyId != null) {
                    await databaseApi.addUserToJourney(
                        selectedJourneyId!, userId);
                    _showMessage("Successfully signed up for the journey!");

                    Navigator.of(context).pop(); // Close the dialog

                    // Trigger a reload of the page after closing the dialog
                    setState(() {
                      // Trigger a refresh
                      dependenciesInitialized = false;
                    });
                  }
                },
                child: Text("Sign Up"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      LogService.instance.error('Error fetching available journeys: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userRole = context.watch<UserDataProvider>().userRole;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              // Wrap MyJourneysPage with Expanded to prevent unbounded height errors
              child: MyJourneysPage(userId: auth.userid ?? ''),
            ),
            const SizedBox(height: 20),
            if (userRole == 'nonmember')
              StandardCard(
                icon: Icons.add_circle_outline,
                title: "Sign Up for a Journey",
                onTap: _openSignUpForJourneyDialog,
              ),
          ],
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }
}
