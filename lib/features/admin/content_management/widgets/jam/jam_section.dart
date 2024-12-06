// lib/features/content_management/presentation/widgets/jams/jam_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/features/admin/collapsable_section.dart';
import 'create_jam_card.dart';
import 'update_jam_card.dart';
import 'delete_jam_card.dart';

class JamSection extends ConsumerWidget {
  final void Function(bool) onLoading;
  final void Function(String, {bool isError}) onMessage;

  const JamSection({
    super.key,
    required this.onLoading,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CollapsibleSection(
      title: "Jams",
      color: AppConstants.photojamPink,
      children: [
        CreateJamCard(
          onLoading: onLoading,
          onMessage: onMessage,
        ),
        UpdateJamCard(
          onLoading: onLoading,
          onMessage: onMessage,
        ),
        DeleteJamCard(
          onLoading: onLoading,
          onMessage: onMessage,
        ),
      ],
    );
  }
}