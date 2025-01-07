import 'package:flutter/material.dart';
import 'package:photojam_app/core/utils/snackbar_util.dart';
import 'package:photojam_app/core/widgets/standard_dialog.dart';

class CreateJourneyDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onJourneyCreated;

  const CreateJourneyDialog({
    super.key,
    required this.onJourneyCreated,
  });

  @override
  _CreateJourneyDialogState createState() => _CreateJourneyDialogState();
}

class _CreateJourneyDialogState extends State<CreateJourneyDialog> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _startDate;
  TimeOfDay? _startTime;
  bool _isActive = false;

  void _submit() {
    if (_titleController.text.isEmpty ||
        _startDate == null ||
        _startTime == null) {
      SnackbarUtil.showErrorSnackBar(
          context, 'Please enter a title, start date, and time.');
      return;
    }

    DateTime journeyDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    Map<String, dynamic> journeyData = {
      "title": _titleController.text,
      "start_date": journeyDateTime.toIso8601String(),
      "active": _isActive,
    };

    widget.onJourneyCreated(journeyData);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return StandardDialog(
      title: "Create Journey",
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Journey Title"),
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text(
                  _startDate == null
                      ? "Select Start Date"
                      : "Start Date: ${_startDate?.toLocal().toString().split(' ')[0]}",
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
                      _startDate = pickedDate;
                    });
                  }
                },
              ),
              ListTile(
                title: Text(
                  _startTime == null
                      ? "Select Start Time"
                      : "Start Time: ${_startTime?.format(context)}",
                ),
                trailing: Icon(Icons.access_time),
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _startTime = pickedTime;
                    });
                  }
                },
              ),
              SwitchListTile(
                title: Text("Active"),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
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
