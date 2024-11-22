
// // lib/features/journeys/widgets/journey_tile.dart
// import 'package:flutter/material.dart';
// import 'package:photojam_app/appwrite/database/models/journey_model.dart';
// import 'package:photojam_app/core/utils/markdownviewer.dart';
// import 'package:photojam_app/features/journeys/widgets/journeycontainer.dart';

// class JourneyTile extends StatelessWidget {
//   final Journey journey;

//   const JourneyTile({
//     super.key,
//     required this.journey,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
    
//     return ExpansionTile(
//       title: Text(
//         journey.title,
//         style: theme.textTheme.bodyLarge?.copyWith(
//           color: theme.colorScheme.onSurface,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
//       children: [
//         JourneyContainer(
//           title: journey.title,
//           lessons: journey.lessons.map((lesson) => {'url': lesson}).toList(),
//           theme: theme,
//           onLessonTap: (lessonUrl) => _viewLesson(context, lessonUrl),
//         ),
//       ],
//     );
//   }

//   void _viewLesson(BuildContext context, String lessonUrl) async {
//     final storageApi = Provider.of<StorageAPI>(context, listen: false);
//     try {
//       final lessonData = await storageApi.getLessonByURL(lessonUrl);
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => MarkdownViewer(content: lessonData),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading lesson: $e')),
//       );
//     }
//   }
// }