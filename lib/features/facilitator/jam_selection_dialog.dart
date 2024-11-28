import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/database/models/jam_model.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/features/facilitator/photo_selection_screen.dart';
import './jam_selection_providers.dart';

class JamSelectionDialog extends ConsumerWidget {
  const JamSelectionDialog({super.key});

  void _selectJam(BuildContext context, Jam jam) {
    LogService.instance.info('Selected jam: ${jam.id}');
    Navigator.pop(context); // Close dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoSelectionScreen(jamId: jam.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jamsAsync = ref.watch(jamSelectionProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select a Jam',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            // Content
            jamsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) {
                LogService.instance.error('Error loading jams: $error\n$stackTrace');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'Failed to load jams: $error',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.refresh(jamSelectionProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              data: (jams) {
                if (jams.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('No upcoming jams found')),
                  );
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: jams.length,
                    itemBuilder: (context, index) {
                      final jam = jams[index];
                      final hasSelectedPhotos = jam.selectedPhotos.isNotEmpty;

                      return ListTile(
                        title: Text(jam.title),
                        subtitle: Text(
                          jam.eventDatetime.toString().split(' ')[0],
                        ),
                        trailing: hasSelectedPhotos ? Tooltip(
                          message: 'Photos already selected, you can edit them',
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                        ) : null,
                        onTap: () => _selectJam(context, jam),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}