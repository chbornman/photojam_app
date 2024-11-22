// import 'package:flutter/material.dart';
// import 'package:photojam_app/features/account/controllers/account_controller.dart';
// import 'package:photojam_app/core/utils/url_launcher.dart';
// import 'package:photojam_app/core/widgets/standard_card.dart';
// import 'package:photojam_app/config/app_constants.dart';

// class RoleBasedActions extends StatelessWidget {
//   final Map<String, dynamic> userData;

//   const RoleBasedActions({super.key, required this.userData});

//   @override
//   Widget build(BuildContext context) {
//     final controller = context.read<AccountController>();
    
//     return Column(
//       children: [
//         if (userData['role'] == 'nonmember')
//           StandardCard(
//             icon: Icons.person_add,
//             title: "Become a Member",
//             subtitle: "Join our community and enjoy exclusive benefits",
//             onTap: () => _handleRoleRequest(
//               context,
//               controller.requestMemberRole,
//               "Successfully became a member!",
//               "Failed to become a member",
//             ),
//           )
//         else if (userData['role'] == 'member')
//           StandardCard(
//             icon: Icons.person_add,
//             title: "Become a Facilitator",
//             subtitle: "Lead Jams and share your photography passion",
//             onTap: () => _handleRoleRequest(
//               context,
//               controller.requestFacilitatorRole,
//               "Facilitator request submitted!",
//               "Failed to submit facilitator request",
//             ),
//           ),
//         if (userData['role'] != 'nonmember')
//           StandardCard(
//             icon: Icons.chat,
//             title: "Go to the Signal Chat",
//             onTap: () => UrlLauncher.launchUrl(signalGroupUrl),
//           ),
//       ],
//     );
//   }

//   Future<void> _handleRoleRequest(
//     BuildContext context,
//     Future<void> Function() request,
//     String successMessage,
//     String errorMessage,
//   ) async {
//     try {
//       await request();
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
//       );
//     } catch (e) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
//       );
//     }
//   }
// }