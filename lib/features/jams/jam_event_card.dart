import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photojam_app/features/admin/jam_event_model.dart';

class JamEventCard extends StatelessWidget {
  final JamEvent jamEvent;
  final VoidCallback? onTap;

  const JamEventCard({
    super.key,
    required this.jamEvent,
    this.onTap,
  });

  Widget _buildStatusIcon(BuildContext context) {
    if (jamEvent.signedUp) {
      return Icon(Icons.check_circle, color: Colors.green[600]);
    } else {
      return Text(
        'Click to Sign up',
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 16.0,       
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        onTap: onTap, // Dynamic tap handler
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(
          jamEvent.jam.title,
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Time: ${timeFormat.format(jamEvent.jam.eventDatetime)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            // MiniPreviews(
            // ),
          ],
        ),
        trailing: _buildStatusIcon(context),
      ),
    );
  }
}

class JamEventCardParent extends StatefulWidget {
  final JamEvent jamEvent;
  final String userRole;

  const JamEventCardParent({
    Key? key,
    required this.jamEvent,
    required this.userRole,
  }) : super(key: key);

  @override
  _JamEventCardParentState createState() => _JamEventCardParentState();
}
class _JamEventCardParentState extends State<JamEventCardParent> {
  @override
  Widget build(BuildContext context) {
    return JamEventCard(
      jamEvent: widget.jamEvent,
    );
  }
}
