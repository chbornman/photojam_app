import 'package:flutter/material.dart';
import 'package:photojam_app/empty_page.dart';
// import 'package:photojam_app/features/admin/screens/jam_calendar_page.dart';
// import 'package:photojam_app/features/facilitator/screens/jam_selection_dialog.dart';
import 'package:photojam_app/core/widgets/standard_card.dart';

class FacilitatorPage extends StatelessWidget {
  const FacilitatorPage({super.key});

  void _showJamSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => const EmptyPage(),//JamSelectionDialog(),
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
            StandardCard(
              icon: Icons.calendar_month,
              title: 'Jam Calendar',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EmptyPage()), //JamCalendarPage()),
                );
              },
            ),
            const SizedBox(height: 10),
            StandardCard(
              icon: Icons.photo_library,
              title: 'Select Jam Photos',
              onTap: () => _showJamSelectionDialog(context),
            ),
          ],
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }
}
