import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_state_provider.dart';
import 'package:photojam_app/appwrite/database/models/jam_model.dart';
import 'package:photojam_app/appwrite/database/providers/submission_provider.dart';
import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/core/services/photo_cache_service.dart';
import 'package:photojam_app/core/widgets/standard_submissioncard.dart';

// Provider for photo cache service
final photoCacheServiceProvider = Provider<PhotoCacheService>((ref) {
  return PhotoCacheService();
});

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

  @override
  void initState() {
    super.initState();
    _loadSubmissionPhotos();
  }

  Future<void> _loadSubmissionPhotos() async {
    if (!mounted) return;

    try {
      setState(() => _isLoading = true);

      // Get current user from auth state
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;

      if (userId == null) {
        throw Exception("User not authenticated");
      }

      LogService.instance.info('Fetching submission for user: $userId and jam: ${widget.jam.id}');

      // Get user's submission for this jam
      final submissionAsync = ref.read(userJamSubmissionProvider(
        (userId: userId, jamId: widget.jam.id)
      ));

      // Handle the AsyncValue state
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

      // Get the photo cache service
      final photoCache = ref.read(photoCacheServiceProvider);
      final storageNotifier = ref.read(photoStorageProvider.notifier);
      // Get auth repository to access session
      final authRepository = ref.read(authRepositoryProvider);
      final session = await authRepository.getCurrentSession();

      // Load photos from storage using their IDs
      List<Uint8List?> loadedPhotos = [];
      for (final photoId in submission.photos) {
        if (!mounted) return;

        try {
          LogService.instance.info('Fetching photo with ID: $photoId');
          
          // Get photo data from storage
          final photoData = await storageNotifier.downloadFile(photoId);
          
          // Cache the photo data
          if (photoData != null) {
            await photoCache.getImage(
              photoId,
              session.$id,
              () => Future.value(photoData),
            );
          }
          
          loadedPhotos.add(photoData);
        } catch (e) {
          LogService.instance.error('Error loading photo $photoId: $e');
          loadedPhotos.add(null); // Add null for failed photos
        }
      }

      if (mounted) {
        setState(() {
          _photos = loadedPhotos;
          _isLoading = false;
        });
      }

    } catch (e) {
      LogService.instance.error('Error loading submission photos: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to load photos');
        setState(() => _isLoading = false);
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
    final startDate = widget.jam.eventDatetime.toUtc().toIso8601String()
        .replaceAll('-', '')
        .replaceAll(':', '')
        .split('.')[0];
    
    final endDate = widget.jam.eventDatetime.add(const Duration(hours: 1)).toUtc()
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
    final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a')
        .format(widget.jam.eventDatetime);

    return Scaffold(
      appBar: AppBar(title: Text(widget.jam.title)),
      backgroundColor: theme.colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.jam.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
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
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_photos.isNotEmpty)
              SubmissionCard(
                title: "Your submitted photos",
                photoWidgets: [
                  Row(
                    children: _photos.map((photoData) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
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