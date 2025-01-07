// lib/features/content_management/presentation/widgets/lessons/lesson_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/features/admin/collapsable_section.dart';
import 'package:photojam_app/features/admin/content_management/widgets/lesson/set_current_lesson_card.dart';
import 'package:photojam_app/features/admin/content_management/widgets/lesson/set_current_lesson_snippet_card.dart';
import './add_lesson_card.dart';
import './delete_lesson_card.dart';

class LessonSection extends ConsumerWidget {
  final void Function(bool) onLoading;
  final void Function(String, {bool isError}) onMessage;

  const LessonSection({
    super.key,
    required this.onLoading,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CollapsibleSection(
      title: "Lessons",
      color: AppConstants.photojamDarkGreen,
      children: [
        AddLessonCard(
          onLoading: onLoading,
          onMessage: onMessage,
        ),
        DeleteLessonCard(
          onLoading: onLoading,
          onMessage: onMessage,
        ),
        // UpdateJourneyLessonsCard(
        //   onLoading: onLoading,
        //   onMessage: onMessage,
        // ),
        SetCurrentLessonSnippetCard(
          onLoading: onLoading,
          onMessage: onMessage,
        ),
        SetCurrentLessonCard(
          onLoading: onLoading,
          onMessage: onMessage,
        ),
      ],
    );
  }
}