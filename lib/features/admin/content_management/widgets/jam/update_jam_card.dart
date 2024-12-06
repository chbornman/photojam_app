// lib/features/content_management/presentation/widgets/jams/update_jam_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/core/widgets/standard_card.dart';
import 'package:photojam_app/features/admin/content_management/actions/jam_management_actions.dart';

class UpdateJamCard extends ConsumerWidget {
  final void Function(bool) onLoading;
  final void Function(String, {bool isError}) onMessage;

  const UpdateJamCard({
    super.key,
    required this.onLoading,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StandardCard(
      icon: Icons.edit,
      title: "Update Jam",
      onTap: () => JamManagementActions.fetchAndOpenUpdateJamDialog(
        context: context,
        ref: ref,
        onLoading: onLoading,
        onMessage: onMessage,
      ),
    );
  }
}