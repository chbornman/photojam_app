
// lib/features/jams/widgets/jam_dropdown.dart
import 'package:flutter/material.dart';
import 'package:appwrite/models.dart';
import 'package:intl/intl.dart';

class JamDropdown extends StatelessWidget {
  final List<Document> jams;
  final String? selectedJamId;
  final ValueChanged<String?> onChanged;

  const JamDropdown({
    super.key,
    required this.jams,
    required this.selectedJamId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        hintText: jams.isEmpty ? "No jams available" : "Select Jam Event",
      ),
      value: selectedJamId,
      onChanged: jams.isEmpty ? null : onChanged,
      items: _createJamMenuItems(context, jams),
    );
  }

  List<DropdownMenuItem<String>> _createJamMenuItems(
    BuildContext context,
    List<Document> jams,
  ) {
    return jams.map((doc) {
      final title = doc.data['title'] as String;
      final dateTime = DateTime.parse(doc.data['date']);
      final formattedDateTime = DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);

      return DropdownMenuItem<String>(
        value: doc.$id,
        child: _buildJamMenuItem(context, title, formattedDateTime),
      );
    }).toList();
  }

  Widget _buildJamMenuItem(
    BuildContext context,
    String title,
    String dateTime,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          dateTime,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
