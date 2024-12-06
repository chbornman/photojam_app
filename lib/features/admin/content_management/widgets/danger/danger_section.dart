// lib/features/content_management/presentation/widgets/danger/danger_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/features/admin/collapsable_section.dart';
import './danger_cards.dart';

class DangerSection extends ConsumerWidget {
  final void Function(bool) onLoading;
  final void Function(String, {bool isError}) onMessage;

  const DangerSection({
    super.key,
    required this.onLoading,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CollapsibleSection(
      title: "Danger Zone",
      color: AppConstants.photojamPurple,
      children: [
        DeleteAllLessonsCard(
          onLoading: onLoading,
          onMessage: onMessage,
        ),
        DeleteLessonFilesCard(
          onLoading: onLoading,
          onMessage: onMessage,
        ),
        DeleteAllSubmissionsCard(
          onLoading: onLoading,
          onMessage: onMessage,
        ),
        DeleteAllPhotosCard(
          onLoading: onLoading,
          onMessage: onMessage,
        ),
      ],
    );
  }
}