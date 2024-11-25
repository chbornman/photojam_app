// lib/features/journeys/widgets/journey_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/database/models/journey_model.dart';
import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
import 'package:photojam_app/core/utils/markdownviewer.dart';
import 'package:photojam_app/features/journeys/widgets/journeycontainer.dart';

class JourneyTile extends ConsumerWidget {
  final Journey journey;

  const JourneyTile({
    super.key,
    required this.journey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ExpansionTile(
      title: Text(
        journey.title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
      children: [
        JourneyContainer(
          title: journey.title,
          lessons: journey.lessonIds.map((lessonId) => {'url': lessonId}).toList(),
          theme: theme,
          onLessonTap: (lessonUrl) => _viewLesson(context, ref, lessonUrl),
        ),
      ],
    );
  }

  Future<void> _viewLesson(BuildContext context, WidgetRef ref, String lessonUrl) async {
    final storageNotifier = ref.watch(lessonStorageProvider.notifier);

    try {
      // Retrieve lesson content from the storage provider
      final lessonData = await storageNotifier.downloadFile(lessonUrl);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarkdownViewer(content: lessonData),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading lesson: $error')),
      );
    }
  }
}