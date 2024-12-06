// lib/features/content_management/presentation/widgets/danger/danger_cards.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/features/admin/content_management/actions/danger_management_actions.dart';
import 'package:photojam_app/features/admin/danger_action_card.dart';

class DeleteAllLessonsCard extends ConsumerWidget {
  final void Function(bool) onLoading;
  final void Function(String, {bool isError}) onMessage;

  const DeleteAllLessonsCard({
    super.key,
    required this.onLoading,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DangerActionCard(
      icon: Icons.delete_forever,
      title: "Delete All Lessons and Files",
      onTap: () => DangerManagementActions.deleteLessonsAndFiles(
        context: context,
        ref: ref,
        onLoading: onLoading,
        onMessage: onMessage,
      ),
    );
  }
}

class DeleteLessonFilesCard extends ConsumerWidget {
  final void Function(bool) onLoading;
  final void Function(String, {bool isError}) onMessage;

  const DeleteLessonFilesCard({
    super.key,
    required this.onLoading,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DangerActionCard(
      icon: Icons.folder_delete_outlined,
      title: "Delete All Lesson Files from Storage",
      onTap: () => DangerManagementActions.deleteAllLessonsFromStorage(
        context: context,
        ref: ref,
        onLoading: onLoading,
        onMessage: onMessage,
      ),
    );
  }
}

class DeleteAllSubmissionsCard extends ConsumerWidget {
  final void Function(bool) onLoading;
  final void Function(String, {bool isError}) onMessage;

  const DeleteAllSubmissionsCard({
    super.key,
    required this.onLoading,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DangerActionCard(
      icon: Icons.delete_sweep,
      title: "Delete All Submissions and Photos",
      onTap: () => DangerManagementActions.deleteSubmissionsAndPhotos(
        context: context,
        ref: ref,
        onLoading: onLoading,
        onMessage: onMessage,
      ),
    );
  }
}

class DeleteAllPhotosCard extends ConsumerWidget {
  final void Function(bool) onLoading;
  final void Function(String, {bool isError}) onMessage;

  const DeleteAllPhotosCard({
    super.key,
    required this.onLoading,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DangerActionCard(
      icon: Icons.photo_library_outlined,
      title: "Delete All Photos from Storage",
      onTap: () => DangerManagementActions.deleteAllPhotosFromStorage(
        context: context,
        ref: ref,
        onLoading: onLoading,
        onMessage: onMessage,
      ),
    );
  }
}