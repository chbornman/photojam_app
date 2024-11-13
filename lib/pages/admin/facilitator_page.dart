import 'package:flutter/material.dart';
import 'package:photojam_app/pages/admin/jampreppage.dart';
import 'package:photojam_app/utilities/standard_card.dart';

class FacilitatorPage extends StatelessWidget {
  const FacilitatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Content Management Section
            StandardCard(
              icon: Icons.photo_library,
              title: 'Select Jam Photos',
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
