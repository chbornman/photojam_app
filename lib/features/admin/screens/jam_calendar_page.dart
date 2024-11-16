import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/features/admin/screens/jam_event.dart';
import 'package:photojam_app/features/admin/screens/jam_event_card.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class JamCalendarPage extends StatefulWidget {
  const JamCalendarPage({super.key});

  @override
  State<JamCalendarPage> createState() => _JamCalendarPageState();
}

class _JamCalendarPageState extends State<JamCalendarPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  Map<DateTime, List<JamEvent>> _jamEvents = {};
  bool _isLoading = true;
  final _dateFormatter = DateFormat('yyyy-MM-dd');
  List<Membership> _availableFacilitators = [];

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    LogService.instance.info('JamCalendarPage initialized.');
    _initialize();
  }

  Future<void> _initialize() async {
    await _fetchJams();
    final authAPI = context.read<AuthAPI>();
    if (await authAPI.roleService.hasPermission('admin')) {
      await _fetchAvailableFacilitators();
    }
  }

  Future<void> _fetchAvailableFacilitators() async {
    try {
      final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
      final teams = Teams(databaseApi.client);

      final facilitators = await databaseApi.getAvailableFacilitators(teams);
      setState(() {
        _availableFacilitators = facilitators;
      });

      LogService.instance.info(
        'Fetched ${facilitators.length} available facilitators',
      );
    } catch (e) {
      LogService.instance.error('Error fetching facilitators: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load facilitators'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<int> _getSubmissionCount(String jamId, DatabaseAPI databaseApi) async {
    try {
      final submissions = await databaseApi.getSubmissionsByJam(jamId);
      final count = submissions.documents.length;
      LogService.instance.info('Found $count submissions for jam $jamId');
      return count;
    } catch (e) {
      LogService.instance
          .error('Error fetching submission count for jam $jamId: $e');
      return 0;
    }
  }

  Future<void> _assignFacilitator(String jamId, String facilitatorId) async {
    try {
      final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
      await databaseApi.updateJamFacilitator(jamId, facilitatorId);

      LogService.instance
          .info('Assigned facilitator $facilitatorId to jam $jamId');
      await _fetchJams(); // Refresh the jams list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully assigned facilitator'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      LogService.instance.error('Error assigning facilitator: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to assign facilitator. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeFacilitator(String jamId) async {
    try {
      final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
      await databaseApi.updateJamFacilitator(jamId, null);

      LogService.instance.info('Removed facilitator from jam $jamId');
      await _fetchJams(); // Refresh the jams list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully removed facilitator'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      LogService.instance.error('Error removing facilitator: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove facilitator. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchJams() async {
    try {
      LogService.instance.info('Fetching jams from the database...');
      final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
      final response = await databaseApi.getJams();

      final events = <DateTime, List<JamEvent>>{};

      for (var doc in response.documents) {
        if (!doc.data.containsKey('date') || !doc.data.containsKey('title')) {
          LogService.instance.error(
            'Invalid jam document found: Missing required fields. ID: ${doc.$id}',
          );
          continue;
        }

        final submissionCount = await _getSubmissionCount(doc.$id, databaseApi);

        final date = DateTime.parse(doc.data['date']).toLocal();
        final normalizedDate = DateTime(date.year, date.month, date.day);

        final jamEvent = JamEvent(
          id: doc.$id,
          title: doc.data['title'] as String,
          dateTime: date,
          facilitatorId: doc.data['facilitator_id'] as String?,
          submissionCount: submissionCount,
          zoomLink: doc.data['zoom_link'] as String?,
          selectedPhotos:
              (doc.data['selected_photos'] as List?)?.cast<String>() ?? [],
        );

        events.putIfAbsent(normalizedDate, () => []).add(jamEvent);

        LogService.instance.info(
          'Jam fetched: ${jamEvent.title} on ${_dateFormatter.format(normalizedDate)} with $submissionCount submissions',
        );
      }

      setState(() {
        _jamEvents = events;
        _isLoading = false;
      });

      LogService.instance
          .info('Total unique jam dates fetched: ${events.length}');
    } catch (e) {
      LogService.instance.error('Error fetching jams: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load jams. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<JamEvent> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _jamEvents[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authAPI = context.watch<AuthAPI>();
    final roleService = authAPI.roleService;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jam Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchJams,
            tooltip: 'Refresh Calendar',
          ),
        ],
      ),
      // In the build method, update the CustomScrollView:

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TableCalendar<JamEvent>(
                        firstDay:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        calendarFormat: CalendarFormat.month,
                        eventLoader: _getEventsForDay,
                        startingDayOfWeek: StartingDayOfWeek.sunday,
                        calendarStyle: CalendarStyle(
                          markersMaxCount: 3,
                          markerDecoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                        onDaySelected: (selectedDay, focusedDay) {
                          LogService.instance.info(
                            'User selected day: ${_dateFormatter.format(selectedDay)}',
                          );
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Events for ${_dateFormatter.format(_selectedDay)}',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final events = _getEventsForDay(_selectedDay);
                      if (events.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No events scheduled for this day'),
                          ),
                        );
                      }
                      final event = events[index];
                      return JamEventCard(
                        event: event,
                        isUserFacilitator: roleService.isFacilitator,
                        isUserAdmin: roleService.isAdmin,
                        currentUserId: authAPI.userId ?? '',
                        availableFacilitators: _availableFacilitators,
                        onAssignFacilitator: _assignFacilitator,
                      );
                    },
                    childCount: _getEventsForDay(_selectedDay).isEmpty
                        ? 1
                        : _getEventsForDay(_selectedDay).length,
                  ),
                ),
              ],
            ),
    );
  }
}
