// lib/features/content_management/domain/jam_management_actions.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/database/models/jam_model.dart';
import 'package:photojam_app/appwrite/database/providers/jam_provider.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/dialogs/create_jam_dialog.dart';
import 'package:photojam_app/dialogs/update_jam_dialog.dart';
import 'package:photojam_app/dialogs/delete_jam_dialog.dart';

class JamManagementActions {
  static void openCreateJamDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) {
    showDialog(
      context: context,
      builder: (context) => CreateJamDialog(
        onJamCreated: (jamData) async {
          try {
            onLoading(true);
            LogService.instance.info('Creating new jam with data: $jamData');
            
            final jam = Jam(
              id: 'temp',
              submissionIds: const [],
              title: jamData['title'],
              eventDatetime: DateTime.parse(jamData['date']),
              zoomLink: jamData['zoom_link'],
              selectedPhotos: const [],
              dateCreated: DateTime.now(),
              dateUpdated: DateTime.now(),
              isActive: true,
            );

            await ref.read(jamsProvider.notifier).createJam(jam);
            onMessage("Jam created successfully");
            LogService.instance.info('Successfully created jam: ${jam.title}');
          } catch (e) {
            LogService.instance.error('Error creating jam: $e');
            onMessage("Error creating jam: $e", isError: true);
          } finally {
            onLoading(false);
          }
        },
      ),
    );
  }

  static Future<void> fetchAndOpenUpdateJamDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) async {
    onLoading(true);
    try {
      LogService.instance.info('Fetching jams for update dialog');
      final jamsAsync = ref.read(jamsProvider);

      jamsAsync.when(
        data: (jams) async {
          if (!context.mounted) return;

          if (jams.isEmpty) {
            onMessage("No jams available", isError: true);
            return;
          }

          final jamMap = {for (var jam in jams) jam.title: jam.id};
          LogService.instance.info('Found ${jams.length} jams');

          await showDialog(
            context: context,
            builder: (context) => UpdateJamDialog(
              jamId: jamMap.values.first,
              initialData: {
                'title': jams.first.title,
                'date': jams.first.eventDatetime.toIso8601String(),
                'zoom_link': jams.first.zoomLink,
              },
              onJamUpdated: (updatedData) async {
                try {
                  LogService.instance.info('Updating jam with data: $updatedData');
                  await ref.read(jamsProvider.notifier).updateJam(
                    jamMap.values.first,
                    title: updatedData['title'],
                    eventDatetime: DateTime.parse(updatedData['date']),
                    zoomLink: updatedData['zoom_link'],
                  );
                  onMessage("Jam updated successfully");
                } catch (e) {
                  LogService.instance.error('Error updating jam: $e');
                  onMessage("Error updating jam: $e", isError: true);
                }
              },
            ),
          );
        },
        loading: () => onLoading(true),
        error: (error, stack) {
          LogService.instance.error('Error fetching jams: $error');
          onMessage("Error fetching jams: $error", isError: true);
        },
      );
    } catch (e) {
      LogService.instance.error('Error in fetchAndOpenUpdateJamDialog: $e');
      onMessage("Error fetching jams", isError: true);
    } finally {
      onLoading(false);
    }
  }

  static Future<void> fetchAndOpenDeleteJamDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) onLoading,
    required Function(String, {bool isError}) onMessage,
  }) async {
    onLoading(true);
    try {
      LogService.instance.info('Fetching jams for delete dialog');
      final jamsAsync = ref.read(jamsProvider);

      jamsAsync.when(
        data: (jams) {
          if (!context.mounted) return;

          final jamMap = {for (var jam in jams) jam.title: jam.id};
          LogService.instance.info('Found ${jams.length} jams');

          showDialog(
            context: context,
            builder: (context) => DeleteJamDialog(
              jamMap: jamMap,
              onJamDeleted: (jamId) async {
                try {
                  LogService.instance.info('Deleting jam: $jamId');
                  await ref.read(jamsProvider.notifier).deleteJam(jamId);
                  onMessage("Jam deleted successfully");
                } catch (e) {
                  LogService.instance.error('Error deleting jam: $e');
                  onMessage("Error deleting jam: $e", isError: true);
                }
              },
            ),
          );
        },
        loading: () => onLoading(true),
        error: (error, stack) {
          LogService.instance.error('Error fetching jams: $error');
          onMessage("Error fetching jams: $error", isError: true);
        },
      );
    } catch (e) {
      LogService.instance.error('Error in fetchAndOpenDeleteJamDialog: $e');
      onMessage("Error fetching jams", isError: true);
    } finally {
      onLoading(false);
    }
  }

  // Additional action methods for journeys, lessons, etc. would go here
}