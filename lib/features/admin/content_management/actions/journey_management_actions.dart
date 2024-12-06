// lib/features/content_management/domain/journey_management_actions.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/database/providers/journey_provider.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/dialogs/create_journey_dialog.dart';
import 'package:photojam_app/dialogs/update_journey_dialog.dart';
import 'package:photojam_app/dialogs/delete_journey_dialog.dart';

class JourneyManagementActions {
  static void openCreateJourneyDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) {
    showDialog(
      context: context,
      builder: (context) => CreateJourneyDialog(
        onJourneyCreated: (journeyData) async {
          try {
            onLoading(true);
            LogService.instance.info('Creating new journey with data: $journeyData');

            await ref.read(journeysProvider.notifier).createJourney(
                  title: journeyData['title'],
                  isActive: journeyData['active'],
                );
            onMessage("Journey created successfully");
            LogService.instance.info('Successfully created journey: ${journeyData['title']}');
          } catch (e) {
            LogService.instance.error('Error creating journey: $e');
            onMessage("Error creating journey: $e", isError: true);
          } finally {
            onLoading(false);
          }
        },
      ),
    );
  }

  static Future<void> fetchAndOpenUpdateJourneyDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) async {
    onLoading(true);
    try {
      LogService.instance.info('Fetching journeys for update dialog');
      final journeysAsync = ref.read(journeysProvider);

      journeysAsync.when(
        data: (journeys) {
          if (!context.mounted) return;

          final journeyMap = {
            for (var journey in journeys) journey.title: journey.id
          };
          LogService.instance.info('Found ${journeys.length} journeys');

          _openUpdateJourneySelectionDialog(
            context: context,
            ref: ref,
            journeyMap: journeyMap,
            onLoading: onLoading,
            onMessage: onMessage,
          );
        },
        loading: () => onLoading(true),
        error: (error, stack) {
          LogService.instance.error('Error fetching journeys: $error');
          onMessage("Error fetching journeys: $error", isError: true);
        },
      );
    } catch (e) {
      LogService.instance.error('Error in fetchAndOpenUpdateJourneyDialog: $e');
      onMessage("Error fetching journeys", isError: true);
    } finally {
      onLoading(false);
    }
  }

  static void _openUpdateJourneySelectionDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, String> journeyMap,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) {
    String? selectedTitle;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Journey to Update"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return DropdownButtonFormField<String>(
              value: selectedTitle,
              hint: const Text("Select Journey"),
              items: journeyMap.keys.map((title) {
                return DropdownMenuItem(
                  value: title,
                  child: Text(title),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedTitle = value),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (selectedTitle != null) {
                _handleJourneySelection(
                  context: context,
                  ref: ref,
                  journeyId: journeyMap[selectedTitle]!,
                  onLoading: onLoading,
                  onMessage: onMessage,
                );
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  static void _handleJourneySelection({
    required BuildContext context,
    required WidgetRef ref,
    required String journeyId,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) {
    Navigator.of(context).pop();

    ref.read(journeyByIdProvider(journeyId)).when(
          data: (journey) {
            if (journey == null) {
              LogService.instance.error('Journey not found: $journeyId');
              onMessage("Journey not found", isError: true);
              return;
            }

            showDialog(
              context: context,
              builder: (context) => UpdateJourneyDialog(
                journeyId: journeyId,
                initialData: {
                  'title': journey.title,
                  'active': journey.isActive,
                },
                onJourneyUpdated: (updatedData) async {
                  try {
                    LogService.instance.info('Updating journey with data: $updatedData');
                    await ref.read(journeysProvider.notifier).updateJourney(
                          journeyId,
                          title: updatedData['title'],
                          isActive: updatedData['active'],
                        );
                    onMessage("Journey updated successfully");
                  } catch (e) {
                    LogService.instance.error('Error updating journey: $e');
                    onMessage("Error updating journey: $e", isError: true);
                  }
                },
              ),
            );
          },
          loading: () => onLoading(true),
          error: (error, stack) {
            LogService.instance.error('Error fetching journey: $error');
            onMessage("Error fetching journey details", isError: true);
          },
        );
  }

  static Future<void> fetchAndOpenDeleteJourneyDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) async {
    onLoading(true);
    try {
      LogService.instance.info('Fetching journeys for delete dialog');
      final journeysAsync = ref.read(journeysProvider);

      journeysAsync.when(
        data: (journeys) {
          if (!context.mounted) return;

          final journeyMap = {
            for (var journey in journeys) journey.title: journey.id
          };
          LogService.instance.info('Found ${journeys.length} journeys');

          showDialog(
            context: context,
            builder: (context) => DeleteJourneyDialog(
              journeyMap: journeyMap,
              onJourneyDeleted: (journeyId) async {
                try {
                  LogService.instance.info('Deleting journey: $journeyId');
                  await ref.read(journeysProvider.notifier).deleteJourney(journeyId);
                  onMessage("Journey deleted successfully");
                } catch (e) {
                  LogService.instance.error('Error deleting journey: $e');
                  onMessage("Error deleting journey: $e", isError: true);
                }
              },
            ),
          );
        },
        loading: () => onLoading(true),
        error: (error, stack) {
          LogService.instance.error('Error fetching journeys: $error');
          onMessage("Error fetching journeys: $error", isError: true);
        },
      );
    } catch (e) {
      LogService.instance.error('Error in fetchAndOpenDeleteJourneyDialog: $e');
      onMessage("Error fetching journeys", isError: true);
    } finally {
      onLoading(false);
    }
  }
}