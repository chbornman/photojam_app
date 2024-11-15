
// lib/features/journeys/screens/journey_page.dart
import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/core/widgets/standard_card.dart';
import 'package:photojam_app/dialogs/signup_journey_dialog.dart';
import 'package:provider/provider.dart';
import '../providers/journey_provider.dart';
import '../widgets/journey_list.dart';
import 'package:photojam_app/core/services/role_service.dart';

class JourneyPage extends StatelessWidget {
  const JourneyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoleService>(
      builder: (context, roleService, _) {
        return FutureBuilder<String>(
          future: roleService.getCurrentUserRole(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final userRole = snapshot.data ?? 'nonmember';
            return Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildContent(context, userRole),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, String userRole) {
    final userId = Provider.of<AuthAPI>(context, listen: false).userid;
    if (userId == null) return const Center(child: Text('Not logged in'));

    if (userRole == 'nonmember') {
      return Column(
        children: [
          Expanded(child: JourneyList(userId: userId, showAllJourneys: false)),
          const SizedBox(height: 20),
          _buildSignUpCard(context),
        ],
      );
    }

    return JourneyList(userId: userId, showAllJourneys: true);
  }

  Widget _buildSignUpCard(BuildContext context) {
    return StandardCard(
      icon: Icons.add_circle_outline,
      title: "Sign Up for a Journey",
      onTap: () => _showSignUpDialog(context),
    );
  }

  Future<void> _showSignUpDialog(BuildContext context) async {
    final journeyProvider = Provider.of<JourneyProvider>(context, listen: false);
    await showDialog(
      context: context,
      builder: (context) => SignUpJourneyDialog(journeyProvider: journeyProvider),
    );
  }
}
