import 'package:flutter/material.dart';

class UserInfo extends StatelessWidget {
  final Map<String, dynamic> userData;

  const UserInfo({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, ${userData['username']}!',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          userData['email'] ?? 'No email available',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ],
    );
  }
}