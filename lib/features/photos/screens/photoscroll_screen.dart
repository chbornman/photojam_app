// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:intl/intl.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:photojam_app/appwrite/database/models/submission_model.dart';
// import 'package:photojam_app/core/services/log_service.dart';
// import 'package:share_plus/share_plus.dart';

// class PhotoScrollPage extends StatefulWidget {
//   final List<Submission> submissions;

//   const PhotoScrollPage({
//     super.key,
//     required this.submissions,
//   });

//   @override
//   _PhotoScrollPageState createState() => _PhotoScrollPageState();
// }

// class _PhotoScrollPageState extends State<PhotoScrollPage>
//     with AutomaticKeepAliveClientMixin {
//   bool isLoading = true;
//   List<Submission> loadedSubmissions = [];
//   Uint8List? activePhotoData;

//   @override
//   bool get wantKeepAlive => true;

//   @override
//   void initState() {
//     super.initState();
//     _loadAllPhotos();
//   }

//   Future<void> _loadAllPhotos() async {
//     try {
//       // Sort submissions by date (most recent first)
//       loadedSubmissions = List.from(widget.submissions)
//         ..sort((a, b) => DateTime.parse(b.dateCreation as String).compareTo(DateTime.parse(a.dateCreation as String)));
      
//       setState(() {
//         isLoading = false;
//       });
//     } catch (e) {
//       LogService.instance.error("Error loading photos: $e");
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> _shareImage(Uint8List photoData) async {
//     try {
//       HapticFeedback.mediumImpact();
//       LogService.instance.info("Sharing photo...");
      
//       final tempDir = await getTemporaryDirectory();
//       final filePath = '${tempDir.path}/shared_image.png';
//       final file = await File(filePath).writeAsBytes(photoData);

//       await Share.shareXFiles([XFile(file.path)], text: 'Check out my PhotoJam submission!');
//     } catch (e) {
//       LogService.instance.error("Error sharing photo: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Error sharing photo.')),
//         );
//       }
//     }
//   }

//   String formatDate(String dateString) {
//     try {
//       DateTime date = DateTime.parse(dateString);
//       return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
//     } catch (e) {
//       LogService.instance.error("Error formatting date: $e");
//       return "Invalid Date";
//     }
//   }

//   Widget _buildPhotoCard(Uint8List? photoData) {
//     return GestureDetector(
//       onLongPressStart: (_) {
//         setState(() {
//           activePhotoData = photoData;
//         });
//       },
//       onLongPressEnd: (_) async {
//         setState(() {
//           activePhotoData = null;
//         });
//         if (photoData != null) {
//           await _shareImage(photoData);
//         }
//       },
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 16.0,
//               vertical: 8.0,
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(8.0),
//               child: photoData != null
//                   ? Image.memory(
//                       photoData,
//                       width: double.infinity,
//                       fit: BoxFit.contain,
//                     )
//                   : Container(
//                       width: double.infinity,
//                       height: 200,
//                       color: const Color.fromARGB(255, 16, 104, 82),
//                       child: const Center(
//                         child: Icon(
//                           Icons.image_not_supported,
//                           color: Color.fromARGB(255, 228, 224, 224),
//                           size: 50,
//                         ),
//                       ),
//                     ),
//             ),
//           ),
//           if (activePhotoData == photoData)
//             Positioned.fill(
//               child: Container(
//                 color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     super.build(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("All Photos"),
//         backgroundColor: Theme.of(context).colorScheme.primary,
//         foregroundColor: Theme.of(context).colorScheme.onPrimary,
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : loadedSubmissions.isEmpty
//               ? Center(
//                   child: Text(
//                     'No photos yet',
//                     style: Theme.of(context).textTheme.bodyLarge,
//                   ),
//                 )
//               : ListView.builder(
//                   key: const PageStorageKey('photoScrollPageListView'),
//                   itemCount: loadedSubmissions.length,
//                   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
//                   itemBuilder: (context, index) {
//                     final submission = loadedSubmissions[index];
                    
//                     return Card(
//                       elevation: 10,
//                       color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
//                       shadowColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
//                       margin: const EdgeInsets.only(bottom: 16.0),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8.0),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(16.0),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'todo', //submission.jamTitle,
//                                   style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                                     fontWeight: FontWeight.bold,
//                                     color: Theme.of(context).colorScheme.onSurface,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   formatDate(submission.dateCreation as String),
//                                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                                     color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Column(
//                             children: submission.photos
//                                 .map((photoData) => _buildPhotoCard(photoData as Uint8List?))
//                                 .toList(),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//       backgroundColor: Theme.of(context).colorScheme.surface,
//     );
//   }
// }