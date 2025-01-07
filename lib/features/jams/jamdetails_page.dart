import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_providers.dart';
import 'package:photojam_app/appwrite/auth/providers/user_role_provider.dart';
import 'package:photojam_app/appwrite/database/models/submission_model.dart';
import 'package:photojam_app/core/utils/snackbar_util.dart';
import 'package:photojam_app/features/photos/photos_screen.dart';
import 'package:photojam_app/features/photos/photoscroll_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_state_provider.dart';
import 'package:photojam_app/appwrite/database/models/jam_model.dart';
import 'package:photojam_app/appwrite/database/providers/submission_provider.dart';
import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/core/widgets/standard_submissioncard.dart';

class JamDetailsPage extends ConsumerStatefulWidget {
  final Jam jam;

  const JamDetailsPage({
    super.key,
    required this.jam,
  });

  @override
  ConsumerState<JamDetailsPage> createState() => _JamDetailsPageState();
}

class _JamDetailsPageState extends ConsumerState<JamDetailsPage> {
  bool _isLoading = true;
  List<Uint8List?> _photos = [];
  List<Uint8List?> _selectedPhotos = [];
  Submission? _submission;

  @override
  void initState() {
    super.initState();
    _loadSubmissionPhotos();
    _loadSelectedPhotos();
  }

  Future<void> _loadSubmissionPhotos() async {
    if (!mounted) return;

    try {
      setState(() => _isLoading = true);

      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;

      if (userId == null) {
        throw Exception("User not authenticated");
      }

      LogService.instance.info(
          'Fetching submission for user: $userId and jam: ${widget.jam.id}');

      final submissionAsync = ref.read(userJamSubmissionProvider(
        (userId: userId, jamId: widget.jam.id),
      ));

      final submission = submissionAsync.when(
        data: (submission) => submission,
        loading: () => null,
        error: (error, stack) {
          LogService.instance.error('Error fetching submission: $error');
          throw error;
        },
      );

      if (!mounted) return;

      if (submission == null) {
        LogService.instance.info('No submission found');
        return;
      }

      final photoCache = ref.read(photoCacheServiceProvider);
      final storageNotifier = ref.read(photoStorageProvider.notifier);
      final authRepository = ref.read(authRepositoryProvider);
      final session = await authRepository.getCurrentSession();

      List<Uint8List?> loadedPhotos = [];
      for (final photoId in submission.photos) {
        if (!mounted) return;

        try {
          LogService.instance.info('Fetching photo with ID: $photoId');
          final photoData = await photoCache.getImage(
            photoId,
            session.$id,
            () => storageNotifier.downloadFile(photoId),
          );
          loadedPhotos.add(photoData);
        } catch (e) {
          LogService.instance.error('Error loading photo $photoId: $e');
          loadedPhotos.add(null);
        }
      }

      if (mounted) {
        setState(() {
          _photos = loadedPhotos;
          _isLoading = false;
        });
      }

      _submission = submission;
    } catch (e) {
      LogService.instance.error('Error loading submission photos: $e');
      if (mounted) {
        SnackbarUtil.showErrorSnackBar(context, 'Failed to load photos');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSelectedPhotos() async {
    if (!mounted) return;

    try {
      // Watch the userRole asynchronously
      final userRoleAsync = ref.read(userRoleProvider);

      // Check if the userRole is still loading or has an error
      final userRole = await userRoleAsync.when(
        data: (role) => role,
        loading: () async {
          LogService.instance.info('Waiting for user role to load...');
          await Future.delayed(
              const Duration(milliseconds: 100)); // Optional delay
          throw Exception('User role is still loading.');
        },
        error: (error, stack) {
          LogService.instance.error('Error fetching user role: $error');
          throw Exception('Failed to fetch user role.');
        },
      );

      // Only proceed for 'facilitator' or 'admin' roles
      if (!["facilitator", "admin"].contains(userRole)) return;

      final storageNotifier = ref.read(photoStorageProvider.notifier);

      List<Uint8List?> loadedPhotos = [];
      for (final photoId in widget.jam.selectedPhotosIds) {
        try {
          LogService.instance.info('Fetching selected photo with ID: $photoId');
          final photoData = await storageNotifier.downloadFile(photoId);
          loadedPhotos.add(photoData);
        } catch (e) {
          LogService.instance
              .error('Error loading selected photo $photoId: $e');
          loadedPhotos.add(null); // Add null if loading fails
        }
      }

      if (mounted) {
        setState(() {
          _selectedPhotos = loadedPhotos;
        });
      }
    } catch (e) {
      LogService.instance.error('Error loading selected photos: $e');
      if (mounted) {
        SnackbarUtil.showErrorSnackBar(
            context, 'Failed to load selected photos');
      }
    }
  }

  Future<void> _openZoomLink() async {
    final uri = Uri.parse(widget.jam.zoomLink);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showErrorSnackBar('Could not open the Zoom link');
      }
    } catch (e) {
      LogService.instance.error('Error launching Zoom link: $e');
      _showErrorSnackBar('Failed to open Zoom link');
    }
  }

  Future<void> _addToGoogleCalendar() async {
    final startDate = widget.jam.eventDatetime
        .toUtc()
        .toIso8601String()
        .replaceAll('-', '')
        .replaceAll(':', '')
        .split('.')[0];

    final endDate = widget.jam.eventDatetime
        .add(const Duration(hours: 1))
        .toUtc()
        .toIso8601String()
        .replaceAll('-', '')
        .replaceAll(':', '')
        .split('.')[0];

    final uri = Uri.parse(
      'https://www.google.com/calendar/render'
      '?action=TEMPLATE'
      '&text=${Uri.encodeComponent(widget.jam.title)}'
      '&details=${Uri.encodeComponent("PhotoJam Session")}'
      '&dates=$startDate/$endDate',
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showErrorSnackBar('Could not open Google Calendar');
      }
    } catch (e) {
      LogService.instance.error('Error launching calendar: $e');
      _showErrorSnackBar('Failed to open calendar');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate =
        DateFormat('MMM dd, yyyy - hh:mm a').format(widget.jam.eventDatetime);

    // Watch userRole provider
    final userRoleAsync = ref.watch(userRoleProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.jam.title)),
      backgroundColor: theme.colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Date: $formattedDate',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Handle loading, error, and data states for userRole
            userRoleAsync.when(
              data: (userRole) {
                if (_isLoading)
                  return const Center(child: CircularProgressIndicator());

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_photos.isNotEmpty && _submission != null)
                      SubmissionCard(
                        title: "Your Submitted Photos",
                        photoWidgets: [
                          Row(
                            children: _photos.map((photoData) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    if (_submission != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PhotoScrollPage(
                                            submission: _submission!,
                                          ),
                                        ),
                                      );
                                    } else {
                                      SnackbarUtil.showErrorSnackBar(context,
                                          'Submission data is missing.');
                                    }
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: photoData != null
                                        ? Image.memory(
                                            photoData,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 100,
                                            height: 100,
                                            color: theme.colorScheme.error,
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color: theme.colorScheme.onError,
                                            ),
                                          ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      )
                    else
                      Center(
                        child: Text(
                          'No photos submitted yet',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Selected Photos Section
                    if (["facilitator", "admin"].contains(userRole))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Selected Photos",
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          _selectedPhotos.isEmpty
                              ? const Center(
                                  child: Text('No selected photos available'),
                                )
                              : GridView.builder(
                                  shrinkWrap: true,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 1,
                                  ),
                                  itemCount: _selectedPhotos.length,
                                  itemBuilder: (context, index) {
                                    final photoData = _selectedPhotos[index];
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: photoData != null
                                          ? Image.memory(
                                              photoData,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: theme.colorScheme.error,
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color:
                                                    theme.colorScheme.onError,
                                              ),
                                            ),
                                    );
                                  },
                                ),
                        ],
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading user role: $error'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'joinZoom',
            icon: const Icon(Icons.link),
            label: const Text("Join Zoom"),
            onPressed: _openZoomLink,
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'addToCalendar',
            icon: const Icon(Icons.calendar_today),
            label: const Text("Add to Calendar"),
            onPressed: _addToGoogleCalendar,
          ),
        ],
      ),
    );
  }
}
