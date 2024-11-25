// lib/features/journeys/widgets/journey_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../appwrite/database/providers/journey_provider.dart';
import 'journey_tile.dart';

class JourneyList extends ConsumerWidget {
  final String userId;
  final bool showAllJourneys;

  const JourneyList({
    super.key,
    required this.userId,
    required this.showAllJourneys,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine which provider to use based on the `showAllJourneys` flag
    final journeysAsyncValue = showAllJourneys
        ? ref.watch(journeysProvider)
        : ref.watch(userJourneysProvider(userId));

    return journeysAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          Center(child: Text('Error: ${error.toString()}')),
      data: (journeys) {
        if (journeys.isEmpty) {
          return const Center(
            child: Text('No journeys available'),
          );
        }
        return ListView.builder(
          itemCount: journeys.length,
          itemBuilder: (context, index) {
            return JourneyTile(journey: journeys[index]);
          },
        );
      },
    );
  }
}