import 'package:flutter/material.dart';
import 'package:photojam_app/utilities/standard_dialog.dart';

class UpdateJamDialog extends StatefulWidget {
  final String jamId;
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onJamUpdated;

  const UpdateJamDialog({
    super.key,
    required this.jamId,
    required this.initialData,
    required this.onJamUpdated,
  });

  @override
  _UpdateJamDialogState createState() => _UpdateJamDialogState();
}

class _UpdateJamDialogState extends State<UpdateJamDialog> {
  late TextEditingController _titleController;
  late TextEditingController _zoomLinkController;
  DateTime? _jamDate;
  TimeOfDay? _jamTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialData['title'] ?? '');
    _zoomLinkController = TextEditingController(text: widget.initialData['zoom_link'] ?? '');

    if (widget.initialData['date'] != null) {
      final jamDateTime = DateTime.parse(widget.initialData['date']);
      _jamDate = jamDateTime;
      _jamTime = TimeOfDay.fromDateTime(jamDateTime);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _submit() {
    if (_titleController.text.isEmpty ||
        _jamDate == null ||
        _jamTime == null ||
        _zoomLinkController.text.isEmpty) {
      _showMessage("Please enter all fields, including the Zoom link.", isError: true);
      return;
    }

    DateTime jamDateTime = DateTime(
      _jamDate!.year,
      _jamDate!.month,
      _jamDate!.day,
      _jamTime!.hour,
      _jamTime!.minute,
    );

    Map<String, dynamic> jamData = {
      "jamId": widget.jamId,
      "title": _titleController.text,
      "date": jamDateTime.toIso8601String(),
      "zoom_link": _zoomLinkController.text,
    };

    widget.onJamUpdated(jamData);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return StandardDialog(
      title: "Update Jam",
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Jam Title"),
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text(
                  _jamDate == null
                      ? "Select Jam Date"
                      : "Jam Date: ${_jamDate?.toLocal().toString().split(' ')[0]}",
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _jamDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _jamDate = pickedDate;
                    });
                  }
                },
              ),
              ListTile(
                title: Text(
                  _jamTime == null
                      ? "Select Jam Time"
                      : "Jam Time: ${_jamTime?.format(context)}",
                ),
                trailing: Icon(Icons.access_time),
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: _jamTime ?? TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _jamTime = pickedTime;
                    });
                  }
                },
              ),
              TextField(
                controller: _zoomLinkController,
                decoration: InputDecoration(labelText: "Zoom Link"),
              ),
            ],
          );
        },
      ),
      submitButtonLabel: "Update",
      submitButtonOnPressed: _submit,
    );
  }
}