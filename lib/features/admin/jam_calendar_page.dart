import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_state_provider.dart';
import 'package:photojam_app/appwrite/auth/providers/user_role_provider.dart';
import 'package:photojam_app/appwrite/database/providers/jam_provider.dart';
import 'package:photojam_app/appwrite/database/providers/submission_provider.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/features/admin/jam_event.dart';
import 'package:photojam_app/features/admin/jam_event_card.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

// Create a provider for events map
final jamEventsMapProvider =
    FutureProvider<Map<DateTime, List<JamEvent>>>((ref) async {
  // Watch the AsyncValue<List<Jam>> and handle it
  final jamsAsync = ref.watch(jamsProvider);

  return jamsAsync.when(
    data: (jams) async {
      final events = <DateTime, List<JamEvent>>{};

      for (final jam in jams) {
        final date = jam.eventDatetime.toLocal();
        final normalizedDate = DateTime(date.year, date.month, date.day);

        // Handle submissions AsyncValue
        final submissionsAsync = ref.watch(jamSubmissionsProvider(jam.id));
        final submissionCount = submissionsAsync.whenOrNull(
              data: (submissions) => submissions.length,
            ) ??
            0;

        final jamEvent = JamEvent(
          id: jam.id,
          title: jam.title,
          dateTime: date,
          facilitatorId: jam.facilitatorId,
          submissionCount: submissionCount,
          zoomLink: jam.zoomLink,
          selectedPhotosIds: jam.selectedPhotosIds,
        );

        events.putIfAbsent(normalizedDate, () => []).add(jamEvent);
      }

      return events;
    },
    loading: () => <DateTime, List<JamEvent>>{},
    error: (error, stack) {
      LogService.instance.error('Error loading jams: $error');
      throw error;
    },
  );
});

class JamCalendarPage extends ConsumerStatefulWidget {
  const JamCalendarPage({super.key});

  @override
  ConsumerState<JamCalendarPage> createState() => _JamCalendarPageState();
}

class _JamCalendarPageState extends ConsumerState<JamCalendarPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  final _dateFormatter = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    LogService.instance.info('JamCalendarPage initialized.');
  }

  List<JamEvent> _getEventsForDay(
      DateTime day, Map<DateTime, List<JamEvent>> events) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userRole = ref.watch(userRoleProvider).valueOrNull ?? 'nonmember';
    final eventsAsync = ref.watch(jamEventsMapProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jam Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(jamEventsMapProvider),
            tooltip: 'Refresh Calendar',
          ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading events: $error'),
        ),
        data: (events) => CustomScrollView(
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
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: CalendarFormat.month,
                    eventLoader: (day) => _getEventsForDay(day, events),
                    startingDayOfWeek: StartingDayOfWeek.sunday,
                    calendarStyle: CalendarStyle(
                      markersMaxCount: 3,
                      markerDecoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      todayDecoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      defaultTextStyle: theme.textTheme.bodyMedium!,
                      weekendTextStyle: theme.textTheme.bodyMedium!.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                      outsideTextStyle: theme.textTheme.bodyMedium!.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
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
                  final dayEvents = _getEventsForDay(_selectedDay, events);
                  if (dayEvents.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No events scheduled for this day'),
                      ),
                    );
                  }
                  return JamEventCard(
                    event: dayEvents[index],
                    userRole: userRole,
                    onTap: () async {
                      final container = ProviderScope.containerOf(context,
                          listen:
                              false); // Get a non-widget-tied ProviderContainer
                      final currentUser = container
                          .read(authStateProvider)
                          .user; // Fetch user directly
                      final currentUserId = currentUser?.id;

                      if (currentUserId != null) {
                        try {
                          final newFacilitatorId =
                              dayEvents[index].facilitatorId == currentUserId
                                  ? null
                                  : currentUserId;

                          await container
                              .read(jamsProvider.notifier)
                              .updateFacilitator(
                                dayEvents[index].id,
                                newFacilitatorId,
                              );

                          container.refresh(jamEventsMapProvider);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(newFacilitatorId == null
                                  ? 'Facilitator role removed successfully!'
                                  : 'You are now the facilitator!'),
                            ),
                          );
                        } catch (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Error updating facilitator: $error')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'You must be logged in to toggle facilitator role.')),
                        );
                      }
                    },
                  );
                },
                childCount: _getEventsForDay(_selectedDay, events).isEmpty
                    ? 1
                    : _getEventsForDay(_selectedDay, events).length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
