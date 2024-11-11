import 'package:flutter/material.dart';
import 'package:photojam_app/pages/admin/contentmanagement_page.dart';
import 'package:photojam_app/pages/admin/jamcalendar_page.dart';
import 'package:photojam_app/pages/admin/usermanagement_page.dart';
import 'package:photojam_app/utilities/system_logs.dart';
import 'package:photojam_app/utilities/standard_card.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'This page allows administrators to manage users, content, and view system logs.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),

            // Jam Calendar Section
            StandardCard(
              icon: Icons.calendar_month,
              title: 'Jam Calendar',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => JamCalendar()),
                );
              },
            ),
            const SizedBox(height: 10),

            // User Management Section
            StandardCard(
              icon: Icons.people,
              title: 'User Management',
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ContentManagementPage()),
                );
              },
            ),
            const SizedBox(height: 10),

            // System Logs Section
            StandardCard(
              icon: Icons.report,
              title: 'System Logs',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SystemLogsPage()),
                );
              },
            ),
          ],
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }
}
