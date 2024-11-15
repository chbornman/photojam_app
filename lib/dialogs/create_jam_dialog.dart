import 'package:flutter/material.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/core/widgets/standard_dialog.dart';

class CreateJamDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onJamCreated;

  const CreateJamDialog({
    super.key,
    required this.onJamCreated,
  });

  @override
  _CreateJamDialogState createState() => _CreateJamDialogState();
}

class _CreateJamDialogState extends State<CreateJamDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _zoomLinkController = TextEditingController();
  DateTime? _jamDate;
  TimeOfDay? _jamTime;

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
      _showMessage("Please enter all required fields, including the Zoom link.", isError: true);
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
      "title": _titleController.text,
      "date": jamDateTime.toIso8601String(),
      "zoom_link": _zoomLinkController.text,
    };

    widget.onJamCreated(jamData);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return StandardDialog(
      title: "Create Jam",
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
                    initialDate: DateTime.now(),
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
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _jamTime = pickedTime;
                    });
                  }
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _zoomLinkController,
                      decoration: InputDecoration(labelText: "Zoom Link"),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.link),
                    tooltip: "Use default Zoom link",
                    onPressed: () {
                      setState(() {
                        _zoomLinkController.text = zoomLinkUrl;
                      });
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
      submitButtonLabel: "Create",
      submitButtonOnPressed: _submit,
    );
  }
}