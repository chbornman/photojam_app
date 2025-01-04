// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:photojam_app/appwrite/database/providers/globals_provider.dart';
// import 'package:photojam_app/appwrite/database/providers/lesson_provider.dart';
// import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
// import 'package:photojam_app/core/services/log_service.dart';
// import 'package:photojam_app/core/utils/markdownviewer.dart';
// import 'package:photojam_app/core/widgets/standard_button.dart';

// class SnippetScreen extends ConsumerWidget {
//   const SnippetScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Scaffold(
//       body: ref.watch(globalValueByKeyProvider('current_lesson_snippet')).when(
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (error, stack) => _ErrorView(error: error.toString()),
//         data: (lessonId) => lessonId != null 
//             ? _LessonContent(lessonId: lessonId)
//             : const Center(
//                 child: Text(
//                   'No snippet available',
//                   style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//       ),
//     );
//   }
// }

// class _ErrorView extends StatelessWidget {
//   final String error;

//   const _ErrorView({required this.error});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             'Error loading lesson: $error',
//             style: const TextStyle(color: Colors.red),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           StandardButton(
//             onPressed: () {
//               // Force a refresh of the provider
//               // This will trigger a new load attempt
//             },
//             label: const Text('Retry'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _LessonContent extends ConsumerStatefulWidget {
//   final String lessonId;

//   const _LessonContent({required this.lessonId});

//   @override
//   _LessonContentState createState() => _LessonContentState();
// }

// class _LessonContentState extends ConsumerState<_LessonContent> {
//   final PageController _pageController = PageController();
//   Uint8List? _lessonData;
//   String? _error;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadLessonContent();
//   }

//   Future<void> _loadLessonContent() async {
//     if (!mounted) return;

//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     try {
//       LogService.instance.info('Fetching lesson content for ID: ${widget.lessonId}');
      
//       final lesson = await ref.read(lessonsProvider.notifier)
//           .getLessonByID(widget.lessonId);
      
//       if (lesson == null) {
//         throw Exception('Lesson data not found');
//       }

//       final fileContent = await ref.read(lessonStorageProvider.notifier)
//           .downloadFile(lesson.contentFileId);

//       if (!mounted) return;

//       setState(() {
//         _lessonData = fileContent;
//         _isLoading = false;
//       });
//     } catch (error) {
//       LogService.instance.error('Error loading lesson content: $error');
//       if (!mounted) return;
      
//       setState(() {
//         _error = error.toString();
//         _isLoading = false;
//       });
//     }
//   }

//   Widget _buildLessonView() {
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (_error != null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'Error loading lesson: $_error',
//               style: const TextStyle(color: Colors.red),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 16),
//             StandardButton(
//               onPressed: _loadLessonContent,
//               label: const Text('Retry'),
//             ),
//           ],
//         ),
//       );
//     }

//     if (_lessonData == null) {
//       return const Center(
//         child: Text(
//           'No content available',
//           style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
//           textAlign: TextAlign.center,
//         ),
//       );
//     }

//     return Column(
//       children: [
//         Expanded(
//           child: MarkdownViewer(markdownBytes: _lessonData!),
//         ),
//         Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: StandardButton(
//             onPressed: () => _pageController.nextPage(
//               duration: const Duration(milliseconds: 300),
//               curve: Curves.easeInOut,
//             ),
//             label: const Text('Submit to Community Board'),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSubmissionView() {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         const Text(
//           'Submit your work here!',
//           style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
//           textAlign: TextAlign.center,
//         ),
//         const SizedBox(height: 16),
//         StandardButton(
//           onPressed: () => _pageController.nextPage(
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeInOut,
//           ),
//           label: const Text('See Community Board'),
//         ),
//       ],
//     );
//   }

//   Widget _buildCommunityBoardView() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         children: [
//           const Expanded(
//             child: TextField(
//               decoration: InputDecoration(
//                 hintText: 'Community Board',
//                 border: OutlineInputBorder(),
//                 contentPadding: EdgeInsets.all(16),
//               ),
//               maxLines: null,
//               expands: true,
//             ),
//           ),
//           const SizedBox(height: 16),
//           StandardButton(
//             onPressed: () => _pageController.jumpToPage(0),
//             label: const Text('Back to Lesson'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PageView(
//       controller: _pageController,
//       physics: const NeverScrollableScrollPhysics(),
//       children: [
//         _buildLessonView(),
//         _buildSubmissionView(),
//         _buildCommunityBoardView(),
//       ],
//     );
//   }
// }


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
  const SnippetScreen({Key? key}) : super(key: key);

  @override
  _SnippetScreenState createState() => _SnippetScreenState();
}

class _SnippetScreenState extends ConsumerState<SnippetScreen> {
  Uint8List? _lessonData;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLessonIdAndContent();
  }

  Future<void> _loadLessonIdAndContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // final lessonId = ref.read(globalValueByKeyProvider('current_lesson_snippet')).value;
      // if (lessonId == null) {
      //   throw Exception('No snippet available');
      // }

      // LogService.instance.info('Fetching lesson content for ID: $lessonId');

      final lesson = await ref.read(lessonsProvider.notifier).getLessonByID("67786f8765313416ae59");
      if (lesson == null) {
        throw Exception('Lesson data not found');
      }

      final fileContent = await ref.read(lessonStorageProvider.notifier).downloadFile(
        lesson.contentFileId,
      );

      setState(() {
        _lessonData = fileContent;
        _isLoading = false;
      });
    } catch (e) {
      LogService.instance.error('Error loading snippet: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading snippet: $_error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              StandardButton(
                onPressed: _loadLessonIdAndContent,
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_lessonData == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No snippet available',
            style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Finally, display the Markdown snippet
    return Scaffold(
      body: SafeArea(
        child: MarkdownViewer(content: _lessonData!),
      ),
    );
  }
}
