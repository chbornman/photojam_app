// import 'package:flutter/material.dart';
// import 'package:photojam_app/features/account/controllers/account_controller.dart';
// import 'package:photojam_app/features/account/widgets/account_management.dart';
// import 'package:photojam_app/features/account/widgets/role_based_actions.dart';
// import 'package:photojam_app/features/account/widgets/user_info.dart';

// class AccountContent extends StatelessWidget {
//   const AccountContent({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final controller = context.watch<AccountController>();
    
//     if (controller.isLoading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
    
//     if (controller.userData == null) {
//       return const Scaffold(
//         body: Center(child: Text('Error loading user data')),
//       );
//     }
    
//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               UserInfo(userData: controller.userData!),
//               const SizedBox(height: 20),
//               AccountManagement(userData: controller.userData!),
//               const SizedBox(height: 10),
//               RoleBasedActions(userData: controller.userData!),
//             ],
//           ),
//         ),
//       ),
//       backgroundColor: Theme.of(context).colorScheme.surface,
//     );
//   }
// }
