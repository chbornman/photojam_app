import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/appwrite/database_api.dart';

class JamCalendar extends StatefulWidget {
  const JamCalendar({super.key});

  @override
  _JamCalendarState createState() => _JamCalendarState();
}

class _JamCalendarState extends State<JamCalendar> {
  late Map<DateTime, List<Map<String, dynamic>>> _jamEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _jamEvents = {};
    _loadJamEvents();
  }

  Future<void> _loadJamEvents() async {
    final databaseAPI = Provider.of<DatabaseAPI>(context, listen: false);
    try {
      final jams = await databaseAPI.getJams();
      final Map<DateTime, List<Map<String, dynamic>>> events = {};

      for (var jam in jams.documents) {
        DateTime jamDate = DateTime.parse(jam.data['date']);
        int submissionCount = jam.data['submission']?.length ?? 0;
        String title = jam.data['title'];

        if (events.containsKey(jamDate)) {
          events[jamDate]!.add({
            'title': title,
            'submission': submissionCount,
            'date': jamDate, // Include the date directly here
          });
        } else {
          events[jamDate] = [
            {
              'title': title,
              'submission': submissionCount,
              'date': jamDate, // Include the date directly here
            }
          ];
        }
      }

      setState(() {
        _jamEvents = events;
      });
    } catch (e) {
      LogService.instance.error('Error loading jam events: $e');
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _jamEvents[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jam Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: theme.colorScheme.onSurface,
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekendStyle: TextStyle(color: theme.colorScheme.secondary),
            ),
            headerStyle: HeaderStyle(
              titleTextStyle: TextStyle(color: theme.colorScheme.onSurface),
              formatButtonTextStyle:
                  TextStyle(color: theme.colorScheme.onPrimary),
              formatButtonDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView(
              children:
                  _getEventsForDay(_selectedDay ?? _focusedDay).map((event) {
                final eventTime = DateFormat('h:mm a').format(event['date']);
                return ListTile(
                  title: Text('${event['title']} - $eventTime'),
                  subtitle: Text('Submissions: ${event['submission']}'),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
