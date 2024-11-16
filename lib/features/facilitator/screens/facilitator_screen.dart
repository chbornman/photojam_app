import 'package:flutter/material.dart';
import 'package:photojam_app/features/facilitator/screens/jam_selection_dialog.dart';
import 'package:photojam_app/core/widgets/standard_card.dart';

class FacilitatorPage extends StatelessWidget {
  const FacilitatorPage({super.key});

  void _showJamSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => const JamSelectionDialog(),
    );
  }

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
              onTap: () => _showJamSelectionDialog(context),
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