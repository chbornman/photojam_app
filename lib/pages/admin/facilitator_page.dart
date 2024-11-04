import 'package:flutter/material.dart';
import 'package:photojam_app/pages/admin/jampreppage.dart';
import 'package:photojam_app/utilities/standard_card.dart';

class FacilitatorPage extends StatelessWidget {
  const FacilitatorPage({Key? key}) : super(key: key);

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
              'This page allows facilitators to select and download submitted photos, and sign up to facilitate jams',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),

            // Content Management Section
            StandardCard(
              icon: Icons.photo_library,
              title: 'Select Jam Photos',
              subtitle:
                  'View submissions and download photos to share with the Jam',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => JamPrepPage()),
                );
              },
            ),
            const SizedBox(height: 10),

            // System Logs Section
            StandardCard(
              icon: Icons.report,
              title: 'Facilitator Calendar',
              subtitle: 'Sign up to lead a Jam',
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => SystemLogsPage()),
                // );
              },
            ),
          ],
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }
}
