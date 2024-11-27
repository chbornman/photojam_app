import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/database/providers/globals_provider.dart';
import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/core/utils/markdownviewer.dart';
import 'package:photojam_app/core/widgets/standard_button.dart';

class SnippetScreen extends ConsumerStatefulWidget {
  const SnippetScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SnippetScreen> createState() => _SnippetScreenState();
}

class _SnippetScreenState extends ConsumerState<SnippetScreen> {
  final PageController _pageController = PageController();

  Future<void> _viewLesson(
      BuildContext context, WidgetRef ref, String lessonUrl) async {
    final storageNotifier = ref.watch(lessonStorageProvider.notifier);

    try {
      // Retrieve lesson content from the storage provider
      final lessonData = await storageNotifier.downloadFile(lessonUrl);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarkdownViewer(content: lessonData),
        ),
      );
    } catch (error) {
      LogService.instance.error('lessonUrl: $lessonUrl');
      LogService.instance.error('Error loading lesson: $error');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading lesson: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the value of the global key "weekly_lesson_snippet"
    final snippetValue =
        ref.watch(globalValueByKeyProvider('weekly_lesson_snippet'));

    return Scaffold(
      body: PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Step 1: Show the weekly lesson with a "Submit to Community Board" button
        snippetValue.when(
        data: (value) {
          // If the value is null or empty, show a default message
          if (value == null || value.isEmpty) {
          return const Text(
            'No snippet available',
            style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          );
          }

          // If value is present, feed it into _viewLesson
          return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
            onPressed: () => _viewLesson(context, ref, value),
            child: const Text(
              'View Lesson',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            ),
            const SizedBox(height: 16),
            StandardButton(
            onPressed: () => _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
            label: const Text('Submit to Community Board'),
            ),
          ],
          );
        },
        loading: () => const CircularProgressIndicator(), // Show a loading spinner
        error: (error, stackTrace) => Text(
          'Error loading snippet: $error',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
        ),

          // Step 2: Empty page with "See Community Board" button
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Submit your work here!',
                style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              StandardButton(
                onPressed: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                label: const Text('See Community Board'),
              ),
            ],
          ),

          // Step 3: Community board page with a text box in the middle
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Community Board',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(16),
                ),
                maxLines: 10,
              ),
              const SizedBox(height: 16),
              StandardButton(
                onPressed: () => _pageController.jumpToPage(0),
                label: const Text('Back to Lesson'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}




