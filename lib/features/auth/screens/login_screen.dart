// import 'package:flutter/material.dart';
// import 'package:photojam_app/features/auth/controllers/login_controller.dart';
// import 'package:photojam_app/features/auth/widgets/login_form.dart';
// import 'package:provider/provider.dart';

// class LoginPage extends StatelessWidget {
//   const LoginPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: ChangeNotifierProvider(
//         create: (_) => LoginController(context.read()),
//         child: const _LoginContent(),
//       ),
//     );
//   }
// }

// class _LoginContent extends StatelessWidget {
//   const _LoginContent();

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: CustomScrollView(
//         slivers: [
//           SliverFillRemaining(
//             hasScrollBody: false,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(height: 60),
//                   // App logo and welcome section
//                   Center(
//                     child: Image.asset(
//                       'assets/icon/app_icon_transparent.png',
//                       width: 100,
//                       height: 100,
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//                   Center(
//                     child: Text(
//                       'Photo Jam',
//                       style: Theme.of(context)
//                           .textTheme
//                           .headlineLarge
//                           ?.copyWith(
//                             fontWeight: FontWeight.bold,
//                             color: Theme.of(context).colorScheme.onSurface,
//                           ),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Center(
//                     child: Text(
//                       'The world\'s nicest photo community',
//                       style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                             color: Theme.of(context)
//                                 .colorScheme
//                                 .onBackground
//                                 .withOpacity(0.7),
//                           ),
//                     ),
//                   ),
//                   const SizedBox(height: 60),
//                   // Login form
//                   const LoginForm(),
//                   const Spacer(),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
