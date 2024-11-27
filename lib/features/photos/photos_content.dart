import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/database/models/submission_model.dart';
import 'package:photojam_app/features/photos/photos_screen.dart';
import 'package:photojam_app/features/photos/submission_list.dart';

class PhotosContent extends ConsumerWidget {
  final List<Submission> submissions;

  const PhotosContent({
    super.key,
    required this.submissions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(photosControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () => controller.fetchSubmissions(),
        child: submissions.isEmpty
          ? Center(
              child: Text(
                "No submitted photos yet!",
                style: TextStyle(
                  fontSize: 18.0,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            )
          : SubmissionList(submissions: submissions),
      ),
    );
  }
}



class PhotosPage extends ConsumerWidget {
  const PhotosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosState = ref.watch(photosControllerProvider);

    return photosState.when(
      data: (submissions) => PhotosContent(submissions: submissions),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Text(
            error.toString(),
            style: TextStyle(
              fontSize: 18.0,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }
}