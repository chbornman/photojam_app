// lib/features/content_management/presentation/widgets/lessons/update_journey_lessons_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/core/widgets/standard_card.dart';
import 'package:photojam_app/features/admin/content_management/actions/lesson_management_actions.dart';

class UpdateJourneyLessonsCard extends ConsumerWidget {
  final void Function(bool) onLoading;
  final void Function(String, {bool isError}) onMessage;

  const UpdateJourneyLessonsCard({
    super.key,
    required this.onLoading,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StandardCard(
      icon: Icons.list,
      title: "Update Journey Lessons",
      onTap: () => LessonManagementActions.fetchAndOpenUpdateJourneyPage(
        context: context,
        ref: ref,
        onLoading: onLoading,
        onMessage: onMessage,
      ),
    );
  }
}