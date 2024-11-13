import 'package:flutter/material.dart';
import 'package:photojam_app/utilities/standard_button.dart';
import 'package:photojam_app/utilities/standard_dialog.dart';

class DeleteJamDialog extends StatefulWidget {
  final Map<String, String> jamMap;
  final Function(String) onJamDeleted;

  const DeleteJamDialog({
    Key? key,
    required this.jamMap,
    required this.onJamDeleted,
  }) : super(key: key);

  @override
  _DeleteJamDialogState createState() => _DeleteJamDialogState();
}

class _DeleteJamDialogState extends State<DeleteJamDialog> {
  String? _selectedJamId;
  String? _selectedJamTitle;
  DateTime? _jamDate;

  void _loadJamDetails(String jamId) {
    setState(() {
      _selectedJamTitle = widget.jamMap.keys
          .firstWhere((key) => widget.jamMap[key] == jamId);
      // Optionally set a dummy date for now (or fetch it from the database if available)
      _jamDate = DateTime.now(); // Replace with actual date if available
    });
  }

  void _confirmDeletion() {
    if (_selectedJamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a jam to delete.")),
      );
      return;
    }

    // Show confirmation dialog before deletion
    final dateStr = _jamDate != null
        ? _jamDate!.toLocal().toString().split(' ')[0]
        : "N/A";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirm Deletion"),
          content: Text(
            "Are you sure you want to delete the following jam?\n\n"
            "Title: $_selectedJamTitle\n"
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
                Navigator.of(context).pop(); // Close delete jam dialog
                widget.onJamDeleted(_selectedJamId!);
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
      title: "Delete Jam",
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedJamId,
                hint: Text("Select Jam"),
                items: widget.jamMap.keys.map((title) {
                  return DropdownMenuItem(
                    value: widget.jamMap[title],
                    child: Text(title),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedJamId = value;
                      _loadJamDetails(value);
                    });
                  }
                },
                decoration: InputDecoration(labelText: "Select Jam"),
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