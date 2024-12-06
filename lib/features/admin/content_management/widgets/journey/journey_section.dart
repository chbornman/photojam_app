// lib/features/content_management/presentation/widgets/journeys/journey_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/features/admin/collapsable_section.dart';
import './create_journey_card.dart';
import './update_journey_card.dart';
import './delete_journey_card.dart';

class JourneySection extends ConsumerWidget {
  final void Function(bool) onLoading;
  final void Function(String, {bool isError}) onMessage;

  const JourneySection({
    super.key,
    required this.onLoading,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CollapsibleSection(
      title: "Journeys",
      color: AppConstants.photojamDarkPink,
      children: [
        CreateJourneyCard(
          onLoading: onLoading,
          onMessage: onMessage,
        ),
        UpdateJourneyCard(
          onLoading: onLoading,
          onMessage: onMessage,
        ),
        DeleteJourneyCard(
          onLoading: onLoading,
          onMessage: onMessage,
        ),
      ],
    );
  }
}
