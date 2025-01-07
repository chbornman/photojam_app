import 'package:flutter/material.dart';
import 'package:photojam_app/core/utils/snackbar_util.dart';
import 'package:photojam_app/core/widgets/standard_button.dart';
import 'package:photojam_app/core/widgets/standard_dialog.dart';

class DeleteJourneyDialog extends StatefulWidget {
  final Map<String, String> journeyMap;
  final Function(String) onJourneyDeleted;

  const DeleteJourneyDialog({
    super.key,
    required this.journeyMap,
    required this.onJourneyDeleted,
  });

  @override
  _DeleteJourneyDialogState createState() => _DeleteJourneyDialogState();
}

class _DeleteJourneyDialogState extends State<DeleteJourneyDialog> {
  String? _selectedJourneyId;
  String? _selectedJourneyTitle;
  DateTime? _journeyStartDate;

  void _loadJourneyDetails(String journeyId) {
    // Fetch journey details based on journey ID
    // Here we assume that the journey title and start date are provided in widget.journeyMap.
    setState(() {
      _selectedJourneyTitle = widget.journeyMap.keys
          .firstWhere((key) => widget.journeyMap[key] == journeyId);
      // Set a dummy start date for now (or fetch it from the database if needed)
      _journeyStartDate = DateTime.now(); // Replace with actual date if available
    });
  }

  void _confirmDeletion() {
    if (_selectedJourneyId == null) {
      SnackbarUtil.showCustomSnackBar(context, 'Please select a journey to delete.', Colors.blue);
      return;
    }

    // Show confirmation dialog before deletion
    final dateStr = _journeyStartDate != null
        ? _journeyStartDate!.toLocal().toString().split(' ')[0]
        : "N/A";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirm Deletion"),
          content: Text(
            "Are you sure you want to delete the journey?\n\n"
            "Title: $_selectedJourneyTitle\n"
            "Date: $dateStr",
          ),
          actions: [
            StandardButton(
              onPressed: () => Navigator.of(context).pop(),
              label: Text("Cancel"),
            ),
            StandardButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close confirmation dialog
                Navigator.of(context).pop(); // Close delete journey dialog
                widget.onJourneyDeleted(_selectedJourneyId!);
              },
              label: Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StandardDialog(
      title: "Delete Journey",
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedJourneyId,
                hint: Text("Select Journey"),
                items: widget.journeyMap.keys.map((title) {
                  return DropdownMenuItem(
                    value: widget.journeyMap[title],
                    child: Text(title),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedJourneyId = value;
                      _loadJourneyDetails(value);
                    });
                  }
                },
                decoration: InputDecoration(labelText: "Select Journey"),
              ),
            ],
          );
        },
      ),
      submitButtonLabel: "Delete",
      submitButtonOnPressed: _confirmDeletion,
    );
  }
}