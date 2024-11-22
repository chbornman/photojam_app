
// // lib/features/account/widgets/account_management.dart
// import 'package:flutter/material.dart';
// import 'package:photojam_app/features/account/controllers/account_controller.dart';
// import 'package:photojam_app/features/account/models/update_dialogs.dart';
// import 'package:photojam_app/core/widgets/standard_card.dart';

// class AccountManagement extends StatelessWidget {
//   final Map<String, dynamic> userData;

//   const AccountManagement({super.key, required this.userData});

//   @override
//   Widget build(BuildContext context) {
//     final controller = context.read<AccountController>();
    
//     return Column(
//       children: [
//         StandardCard(
//           icon: Icons.person,
//           title: "Change Name",
//           onTap: () => UpdateDialogs.showUpdateNameDialog(
//             context: context,
//             currentName: userData['username'],
//             onUpdate: controller.updateName,
//           ),
//         ),
//         const SizedBox(height: 10),
//         StandardCard(
//           icon: Icons.email,
//           title: "Change Email",
//           onTap: () => UpdateDialogs.showUpdateEmailDialog(
//             context: context,
//             currentEmail: userData['email'],
//             onUpdate: controller.updateEmail,
//           ),
//         ),
//         const SizedBox(height: 10),
//         if (!userData['isOAuthUser'])
//           StandardCard(
//             icon: Icons.lock,
//             title: "Change Password",
//             onTap: () => UpdateDialogs.showUpdatePasswordDialog(
//               context: context,
//               onUpdate: controller.updatePassword,
//             ),
//           ),
//       ],
//     );
//   }
// }