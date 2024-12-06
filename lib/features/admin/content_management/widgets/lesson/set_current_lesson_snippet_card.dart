// lib/features/content_management/presentation/widgets/lessons/set_lesson_snippet_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/core/widgets/standard_card.dart';
import 'package:photojam_app/features/admin/content_management/actions/lesson_management_actions.dart';

class SetCurrentLessonSnippetCard extends ConsumerWidget {
  final void Function(bool) onLoading;
  final void Function(String, {bool isError}) onMessage;

  const SetCurrentLessonSnippetCard({
    super.key,
    required this.onLoading,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StandardCard(
      icon: Icons.play_lesson,
      title: "Set Current Lesson Snippet",
      onTap: () => LessonManagementActions.openSetLessonSnippetDialog(
        context: context,
        ref: ref,
        onLoading: onLoading,
        onMessage: onMessage,
      ),
    );
  }
}