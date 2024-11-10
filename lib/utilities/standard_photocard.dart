import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photojam_app/log_service.dart';

class PhotoCard extends StatelessWidget {
  final String title;
  final String? date;
  final List<Widget> photoWidgets;

  const PhotoCard({
    Key? key,
    required this.title,
    this.date, // Making date optional
    required this.photoWidgets,
  }) : super(key: key);

  // Helper function to format date
  String formatDate(String? dateString) {
    if (dateString == null) return "No Date Provided"; // Default text if date is null

    try {
      DateTime parsedDate = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(parsedDate);
    } catch (e) {
      LogService.instance.error("Error formatting date: $e");
      return "Invalid Date";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 10,
      color: theme.colorScheme.surface.withOpacity(0.1),
      shadowColor: theme.colorScheme.onSurface.withOpacity(0.3),
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (date != null) ...[
              const SizedBox(height: 4),
              Text(
                formatDate(date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
            const SizedBox(height: 8),
            ...photoWidgets,
          ],
        ),
      ),
    );
  }
}