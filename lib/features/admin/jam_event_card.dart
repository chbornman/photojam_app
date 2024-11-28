import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photojam_app/features/admin/jam_event.dart';
class JamEventCard extends StatelessWidget {
  final JamEvent event;
  final String userRole;

  const JamEventCard({
    super.key,
    required this.event,
    required this.userRole,
  });

  Widget _buildStatusIcon(BuildContext context) {
    final theme = Theme.of(context);

    if (event.hasFacilitator && event.hasPhotosSelected) {
      return Icon(Icons.check_circle, color: Colors.green[600]);
    } else if (event.hasFacilitator) {
      return Icon(Icons.warning_amber_rounded, color: Colors.amber[600]);
    } else {
      return Icon(Icons.cancel, color: theme.colorScheme.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        title: Text(
          event.title,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Time: ${timeFormat.format(event.dateTime)}'),
            Text('Submissions: ${event.submissionCount}'),
          ],
        ),
        trailing: _buildStatusIcon(context),
      ),
    );
  }
}