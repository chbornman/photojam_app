import 'package:flutter/material.dart';
import 'package:appwrite/models.dart';
import 'package:intl/intl.dart';
import 'package:photojam_app/appwrite/auth/role_utils.dart';
import 'package:photojam_app/features/admin/jam_event.dart';

class JamEventCard extends StatelessWidget {
  final JamEvent event;
  final String userRole; // Changed to use single role string that comes from labels
  final String currentUserId;
  final List<User> availableFacilitators; // Changed from Membership to User
  final Future<void> Function(String jamId, String facilitatorId)?
      onAssignFacilitator;

  const JamEventCard({
    super.key,
    required this.event,
    required this.userRole,
    required this.currentUserId,
    required this.availableFacilitators,
    this.onAssignFacilitator,
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

  Widget _buildAssignButton(BuildContext context) {
    final labels = [userRole];
    final isAdmin = RoleUtils.isAdmin(labels);
    final isFacilitator = RoleUtils.isFacilitator(labels);

    if (!isFacilitator && !isAdmin) return const SizedBox.shrink();

    if (isAdmin) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.person_add),
        tooltip: 'Assign Facilitator',
        itemBuilder: (BuildContext context) => [
          ...availableFacilitators
              .where((user) => 
                  user.labels.contains('facilitator') || 
                  user.labels.contains('admin'))
              .map((user) => PopupMenuItem<String>(
                    value: user.$id,
                    child: Text(user.name),
                  )),
        ],
        onSelected: (String facilitatorId) {
          onAssignFacilitator?.call(event.id, facilitatorId);
        },
      );
    }

    if (isFacilitator) {
      return IconButton(
        icon: const Icon(Icons.person_add),
        tooltip: 'Sign up as Facilitator',
        onPressed: () {
          onAssignFacilitator?.call(event.id, currentUserId);
        },
      );
    }

    return const SizedBox.shrink();
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
            Text(
              event.facilitatorId != null && event.facilitatorId!.isNotEmpty
                  ? 'Facilitator: ${_getFacilitatorName(event.facilitatorId!)}'
                  : 'No facilitator assigned',
              style: event.facilitatorId == null || event.facilitatorId!.isEmpty
                  ? TextStyle(color: theme.colorScheme.error)
                  : null,
            ),
            Text('Submissions: ${event.submissionCount}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusIcon(context),
            if (event.dateTime.isAfter(DateTime.now()))
              _buildAssignButton(context),
          ],
        ),
      ),
    );
  }

  String _getFacilitatorName(String facilitatorId) {
    final facilitator = availableFacilitators.firstWhere(
      (user) => user.$id == facilitatorId,
      orElse: () => User(
        $id: 'unknown',
        $createdAt: '',
        $updatedAt: '',
        name: 'Unknown',
        email: 'unknown@example.com',
        phone: '',
        status: true,
        emailVerification: false,
        phoneVerification: false,
        prefs: Preferences(data: {}),
        labels: [], 
        registration: '',
        passwordUpdate: '',
        mfa: false,
        targets: [],
        accessedAt: '',
      ),
    );
    return facilitator.name;
  }
}