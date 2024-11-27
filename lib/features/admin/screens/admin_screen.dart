import 'package:flutter/material.dart';
import 'package:photojam_app/empty_page.dart';
import 'package:photojam_app/features/admin/screens/content_management_screen.dart';
import 'package:photojam_app/features/admin/screens/system_logs.dart';
import 'package:photojam_app/core/widgets/standard_card.dart';

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
            // Jam Calendar Section
            StandardCard(
              icon: Icons.calendar_month,
              title: 'Jam Calendar',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EmptyPage()),//JamCalendarPage()),
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
                  MaterialPageRoute(builder: (context) => EmptyPage()),//UserManagementPage()),
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
