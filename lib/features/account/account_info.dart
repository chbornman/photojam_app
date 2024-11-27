// widgets/account_info.dart
import 'package:flutter/material.dart';

class AccountInfo extends StatelessWidget {
  final String name;
  final String email;
  final String role;

  const AccountInfo({
    super.key,
    required this.name,
    required this.email,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $name',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(email),
            const SizedBox(height: 4),
            Text('Role: ${role.toUpperCase()}'),
          ],
        ),
      ),
    );
  }
}
