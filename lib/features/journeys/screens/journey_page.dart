import 'package:flutter/material.dart';
import 'package:photojam_app/core/widgets/standard_card.dart';
import 'package:photojam_app/dialogs/signup_journey_dialog.dart';
import '../../../appwrite/database/providers/journey_provider.dart';
import '../widgets/journey_list.dart';

class JourneyPage extends StatelessWidget {
  const JourneyPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<AuthAPI>(
//       builder: (context, authAPI, _) {
//         return FutureBuilder<String>(
//           future: authAPI.roleService.getCurrentUserRole(),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             if (snapshot.hasError) {
//               return Center(
//                 child: Text('Error: ${snapshot.error}'),
//               );
//             }

//             final userRole = snapshot.data ?? 'nonmember';
//             return _JourneyPageContent(userRole: userRole);
//           },
//         );
//       },
//     );
//   }
// }

// class _JourneyPageContent extends StatelessWidget {
//   final String userRole;

//   const _JourneyPageContent({
//     required this.userRole,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final auth = context.read<AuthAPI>();
//     if (!auth.isAuthenticated) {
//       return const Center(child: Text('Not logged in'));
//     }

//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: _buildContent(context),
//       ),
//     );
//   }

//   Widget _buildContent(BuildContext context) {
//     final auth = context.read<AuthAPI>();
//     final userId = auth.userId;
//     if (userId == null)
//       return const Center(child: Text('User ID not available'));

//     if (userRole == 'nonmember') {
//       return Column(
//         children: [
//           Expanded(child: JourneyList(userId: userId, showAllJourneys: false)),
//           const SizedBox(height: 20),
//           _buildSignUpCard(context),
//         ],
//       );
//     }

//     return JourneyList(userId: userId, showAllJourneys: true);
//   }

//   Widget _buildSignUpCard(BuildContext context) {
//     return StandardCard(
//       icon: Icons.add_circle_outline,
//       title: "Sign Up for a Journey",
//       onTap: () => _showSignUpDialog(context),
//     );
//   }

//   Future<void> _showSignUpDialog(BuildContext context) async {
//     final journeyProvider = context.read<JourneyProvider>();
//     await showDialog(
//       context: context,
//       builder: (context) =>
//           SignUpJourneyDialog(journeyProvider: journeyProvider),
//     );
//   }
// }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Hi'),
      ),
    );
  }
}