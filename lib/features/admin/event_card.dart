import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_state_provider.dart';
import 'package:photojam_app/appwrite/database/providers/jam_provider.dart';
import 'package:photojam_app/core/utils/snackbar_util.dart';
import 'package:photojam_app/features/admin/facilitator_calendar_page.dart';
import 'package:photojam_app/features/admin/event.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final String userRole;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.userRole,
    this.onTap,
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
        onTap: onTap, // Dynamic tap handler
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(
          event.title,
          style: theme.textTheme.titleMedium
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
                  'Time: ${timeFormat.format(event.dateTime)}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  'Submissions: ${event.submissionCount}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              event.hasFacilitator
                  ? 'Facilitator Assigned'
                  : 'No Facilitator Assigned',
              style: theme.textTheme.bodySmall?.copyWith(
                color: event.hasFacilitator
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
            ),
          ],
        ),
        trailing: _buildStatusIcon(context),
      ),
    );
  }
}

class EventCardParent extends StatefulWidget {
  final Event event;
  final String userRole;

  const EventCardParent({
    Key? key,
    required this.event,
    required this.userRole,
  }) : super(key: key);

  @override
  _EventCardParentState createState() => _EventCardParentState();
}

class _EventCardParentState extends State<EventCardParent> {
  @override
  Widget build(BuildContext context) {
    final container = ProviderScope.containerOf(context, listen: false);
    final currentUser = container.read(authStateProvider).user;

    return EventCard(
      event: widget.event,
      userRole: widget.userRole,
      onTap: () async {
        final currentUserId = currentUser?.id;
        if (currentUserId != null) {
          try {
            final newFacilitatorId = widget.event.facilitatorId == currentUserId
                ? null
                : currentUserId;

            await container.read(jamsProvider.notifier).updateFacilitator(
                  widget.event.id,
                  newFacilitatorId,
                );

            container.refresh(EventsMapProvider);

            if (mounted) {
              SnackbarUtil.showSuccessSnackBar(
                  context,
                  newFacilitatorId == null
                      ? 'Facilitator role removed successfully!'
                      : 'You are now the facilitator!');
            }
          } catch (error) {
            if (mounted) {
              SnackbarUtil.showErrorSnackBar(context, 'Error updating facilitator: $error');
            }
          }
        }
      },
    );
  }
}
