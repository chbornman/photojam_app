import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/database/providers/globals_provider.dart';
import 'package:photojam_app/appwrite/database/providers/lesson_provider.dart';
import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/core/utils/markdownviewer.dart';
import 'package:photojam_app/core/widgets/standard_button.dart';

class SnippetScreen extends ConsumerStatefulWidget {
  const SnippetScreen({super.key});

  @override
  ConsumerState<SnippetScreen> createState() => _SnippetScreenState();
}

class _SnippetScreenState extends ConsumerState<SnippetScreen> {
  final PageController _pageController = PageController();
  Uint8List? _lessonData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialLesson();
  }

Future<void> _loadInitialLesson() async {
  try {
    LogService.instance.info('Loading initial lesson');
    final snippetValueAsync = ref.read(globalValueByKeyProvider('current_lesson_snippet'));
    
    final lessonId = snippetValueAsync.value;
    if (lessonId == null) {
      throw Exception('No lesson ID available');
    }

    await _loadLessonContent(lessonId);
  } catch (e) {
    LogService.instance.error('Failed to load initial lesson: $e');
    if (mounted) {
      setState(() {
        _error = e.toString();
      });
    }
  }
}

Future<void> _loadLessonContent(String lessonId) async {
  final lessonNotifier = ref.read(lessonsProvider.notifier);
  final storageNotifier = ref.read(lessonStorageProvider.notifier);

  try {
    LogService.instance.info('Fetching lesson content for ID: $lessonId');
    final lesson = await lessonNotifier.getLessonByID(lessonId);
    if (lesson == null) {
      throw Exception('Lesson data not found for ID: $lessonId');
    }

    final contentFileId = lesson.contentFileId; // Retrieve the contentFileId from the lesson
    if (contentFileId == null || contentFileId.isEmpty) {
      throw Exception('Content file ID is missing for lesson ID: $lessonId');
    }

    // Fetch the file content from storage
    final fileContent = await storageNotifier.downloadFile(contentFileId);

    if (mounted) {
      setState(() {
        _lessonData = fileContent;
        _error = null;
      });
    }
  } catch (error) {
    LogService.instance.error('Error loading lesson content: $error');
    if (mounted) {
      setState(() {
        _error = error.toString();
      });
    }
  }
}




  Widget _buildLessonView() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading lesson: $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            StandardButton(
              onPressed: _loadInitialLesson,
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ref.watch(globalValueByKeyProvider('current_lesson_snippet')).when(
      data: (value) {
        if (value == null || value.isEmpty) {
          return const Center(
            child: Text(
              'No snippet available',
              style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: _lessonData != null
                  ? MarkdownViewer(content: _lessonData!)
                  : const Center(child: CircularProgressIndicator()),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: StandardButton(
                onPressed: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                label: const Text('Submit to Community Board'),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            StandardButton(
              onPressed: _loadInitialLesson,
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSubmissionView() {
    return Column(
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
    );
  }

  Widget _buildCommunityBoardView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Community Board',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
              maxLines: null,
              expands: true,
            ),
          ),
          const SizedBox(height: 16),
          StandardButton(
            onPressed: () => _pageController.jumpToPage(0),
            label: const Text('Back to Lesson'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildLessonView(),
          _buildSubmissionView(),
          _buildCommunityBoardView(),
        ],
      ),
    );
  }
}