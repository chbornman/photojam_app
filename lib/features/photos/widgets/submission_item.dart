// import 'package:flutter/material.dart';
// import 'package:photojam_app/appwrite/database/models/submission_model.dart';
// import 'package:photojam_app/core/widgets/standard_submissioncard.dart';
// import 'package:photojam_app/features/photos/screens/photoscroll_screen.dart';
// import 'package:photojam_app/features/photos/controllers/photos_controller.dart';

// class SubmissionItem extends StatelessWidget {
//   final Submission submission;
//   final int index;

//   const SubmissionItem({
//     super.key,
//     required this.submission,
//     required this.index,
//   });

//   void _navigateToPhotoScrollPage(BuildContext context, int photoIndex) {
//     // Get all submissions from the PhotosController
//     final allSubmissions = context.read<PhotosController>().submissions;
    
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => PhotoScrollPage(
//           submissions: allSubmissions,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final photoWidgets = [
//       Row(
//         children: submission.photos.asMap().entries.map((entry) {
//           final photoIndex = entry.key;
//           final photoData = entry.value;

//           return GestureDetector(
//             onTap: () => _navigateToPhotoScrollPage(context, photoIndex),
//             child: Padding(
//               padding: const EdgeInsets.only(right: 8.0),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(8.0),
//                 child: photoData != null
//                     ? Image.memory(
//                         photoData,
//                         width: 100,
//                         height: 100,
//                         fit: BoxFit.cover,
//                       )
//                     : Container(
//                         width: 100,
//                         height: 100,
//                         color: const Color.fromARGB(255, 106, 35, 35),
//                         child: const Icon(
//                           Icons.image_not_supported,
//                           color: Colors.white,
//                         ),
//                       ),
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     ];

//     return SubmissionCard(
//       title: submission.jamTitle,
//       date: submission.date,
//       photoWidgets: photoWidgets,
//     );
//   }
// }