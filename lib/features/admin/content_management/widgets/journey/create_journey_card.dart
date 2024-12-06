// lib/features/content_management/presentation/widgets/journeys/create_journey_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/core/widgets/standard_card.dart';
import 'package:photojam_app/features/admin/content_management/actions/journey_management_actions.dart';

class CreateJourneyCard extends ConsumerWidget {
  final void Function(bool) onLoading;
  final void Function(String, {bool isError}) onMessage;

  const CreateJourneyCard({
    super.key,
    required this.onLoading,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StandardCard(
      icon: Icons.add,
      title: "Create Journey",
      onTap: () => JourneyManagementActions.openCreateJourneyDialog(
        context: context,
        ref: ref,
        onLoading: onLoading,
        onMessage: onMessage,
      ),
    );
  }
}