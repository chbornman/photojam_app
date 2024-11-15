import 'package:flutter/material.dart';
import 'package:photojam_app/core/widgets/standard_dialog.dart';

class UpdateJourneyDialog extends StatefulWidget {
  final String journeyId;
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onJourneyUpdated;

  const UpdateJourneyDialog({
    super.key,
    required this.journeyId,
    required this.initialData,
    required this.onJourneyUpdated,
  });

  @override
  _UpdateJourneyDialogState createState() => _UpdateJourneyDialogState();
}

class _UpdateJourneyDialogState extends State<UpdateJourneyDialog> {
  late TextEditingController _titleController;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialData['title'] ?? '');
    _isActive = widget.initialData['active'] ?? false;

    if (widget.initialData['start_date'] != null) {
      final journeyDateTime = DateTime.parse(widget.initialData['start_date']);
      _startDate = journeyDateTime;
      _startTime = TimeOfDay.fromDateTime(journeyDateTime);
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
    if (_titleController.text.isEmpty || _startDate == null || _startTime == null) {
      _showMessage("Please enter a title, start date, and time.", isError: true);
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
      "journeyId": widget.journeyId,
      "title": _titleController.text,
      "start_date": journeyDateTime.toIso8601String(),
      "active": _isActive,
    };

    widget.onJourneyUpdated(journeyData);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return StandardDialog(
      title: "Update Journey",
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
                    initialDate: _startDate ?? DateTime.now(),
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
                    initialTime: _startTime ?? TimeOfDay.now(),
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
      submitButtonLabel: "Update",
      submitButtonOnPressed: _submit,
    );
  }
}