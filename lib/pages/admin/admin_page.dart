import 'package:flutter/material.dart';
import 'package:photojam_app/pages/admin/contentmanagement_page.dart';
import 'package:photojam_app/pages/admin/usermanagement_page.dart';
import 'package:photojam_app/standard_card.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Management Section
            StandardCard(
              icon: Icons.people,
              title: 'User Management',
              subtitle: 'View and manage users',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserManagementPage()),
                );
              },
            ),
            const SizedBox(height: 10),
            
            // Content Management Section
            StandardCard(
              icon: Icons.photo_library,
              title: 'Content Management',
              subtitle: 'Manage photos and submissions',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContentManagementPage()),
                );
              },
            ),
            const SizedBox(height: 10),
            
            // System Logs Section
            StandardCard(
              icon: Icons.report,
              title: 'System Logs',
              subtitle: 'View system logs and errors',
              onTap: () {
                // Navigate to System Logs Page (placeholder)
              },
            ),
          ],
        ),
      ),
    );
  }
}