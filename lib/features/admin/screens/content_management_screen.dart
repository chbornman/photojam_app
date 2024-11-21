// import 'package:appwrite/models.dart';
// import 'package:flutter/material.dart';
// import 'package:photojam_app/dialogs/create_jam_dialog.dart';
// import 'package:photojam_app/dialogs/delete_jam_dialog.dart';
// import 'package:photojam_app/dialogs/delete_journey_dialog.dart';
// import 'package:photojam_app/dialogs/update_jam_dialog.dart';
// import 'package:photojam_app/dialogs/update_journey_dialog.dart';
// import 'package:photojam_app/core/services/log_service.dart';
// import 'package:photojam_app/features/admin/screens/journey_lessons_edit.dart';
// import 'package:photojam_app/core/widgets/standard_button.dart';
// import 'package:photojam_app/core/widgets/standard_card.dart';
// import 'package:photojam_app/core/widgets/standard_dialog.dart';
// import 'package:provider/provider.dart';
// import 'dart:typed_data';
// import 'package:file_picker/file_picker.dart';
// import 'package:photojam_app/dialogs/create_journey_dialog.dart'; // Import the new dialog

// class ContentManagementPage extends StatefulWidget {
//   const ContentManagementPage({super.key});

//   @override
//   _ContentManagementPageState createState() => _ContentManagementPageState();
// }

// class _ContentManagementPageState extends State<ContentManagementPage> {
//   late DatabaseAPI database;
//   late StorageAPI storage;
//   bool isLoading = false;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     database = Provider.of<DatabaseAPI>(context, listen: false);
//     storage = Provider.of<StorageAPI>(context, listen: false);
//   }

//   void _showMessage(String message, {bool isError = false}) {
//     final snackBar = SnackBar(
//       content: Text(message),
//       backgroundColor: isError ? Colors.red : Colors.green,
//     );
//     ScaffoldMessenger.of(context).showSnackBar(snackBar);
//   }

//   Future<void> _executeAction(
//       Future<void> Function(Map<String, dynamic>) action,
//       Map<String, dynamic> data,
//       String successMessage) async {
//     setState(() => isLoading = true);
//     try {
//       await action(data);
//       _showMessage(successMessage);
//     } catch (e) {
//       _showMessage("Error: $e", isError: true);
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   void _fetchAndOpenUpdateJourneyDialog() async {
//     setState(() => isLoading = true);
//     try {
//       DocumentList journeyList = await database.listJourneys();
//       Map<String, String> journeyMap = {
//         for (var doc in journeyList.documents) doc.data['title']: doc.$id
//       };
//       _openUpdateJourneyDialog(journeyMap);
//     } catch (e) {
//       _showMessage("Error fetching journeys: $e", isError: true);
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   void _fetchAndOpenDeleteJourneyDialog() async {
//     setState(() => isLoading = true);
//     try {
//       DocumentList journeyList = await database.listJourneys();
//       Map<String, String> journeyMap = {
//         for (var doc in journeyList.documents) doc.data['title']: doc.$id
//       };

//       showDialog(
//         context: context,
//         builder: (context) => DeleteJourneyDialog(
//           journeyMap: journeyMap,
//           onJourneyDeleted: (journeyId) async {
//             await _executeAction(
//               database.deleteJourney,
//               {"journeyId": journeyId},
//               "Journey deleted successfully",
//             );
//           },
//         ),
//       );
//     } catch (e) {
//       _showMessage("Error fetching journeys: $e", isError: true);
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   void _fetchAndOpenUpdateJamDialog() async {
//     // Capture the stable parent context
//     final parentContext = context;

//     setState(() => isLoading = true);
//     try {
//       DocumentList jamList = await database.listJams();
//       Map<String, String> jamMap = {
//         for (var doc in jamList.documents) doc.data['title']: doc.$id
//       };

//       showDialog(
//         context: parentContext, // Use parentContext here
//         builder: (context) {
//           String? selectedJamTitle;

//           return AlertDialog(
//             title: Text("Select Jam to Update"),
//             content: StatefulBuilder(
//               builder: (context, setState) {
//                 return DropdownButtonFormField<String>(
//                   value: selectedJamTitle,
//                   hint: Text("Select Jam"),
//                   items: jamMap.keys.map((title) {
//                     return DropdownMenuItem(
//                       value: title,
//                       child: Text(title),
//                     );
//                   }).toList(),
//                   onChanged: (value) {
//                     setState(() {
//                       selectedJamTitle = value;
//                     });
//                   },
//                   decoration: InputDecoration(labelText: "Select Jam"),
//                 );
//               },
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () =>
//                     Navigator.of(parentContext).pop(), // Use parentContext
//                 child: Text("Cancel"),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   if (selectedJamTitle != null) {
//                     final jamId = jamMap[selectedJamTitle]!;
//                     Navigator.of(parentContext).pop(); // Close selection dialog

//                     try {
//                       final jamDoc = await database.getJamById(jamId);
//                       Map<String, dynamic> initialData = {
//                         "title": jamDoc.data['title'] ?? '',
//                         "date": jamDoc.data['date'] ?? '',
//                         "zoom_link": jamDoc.data['zoom_link'] ?? '',
//                       };

//                       // Use parentContext for the next dialog
//                       showDialog(
//                         context: parentContext,
//                         builder: (context) => UpdateJamDialog(
//                           jamId: jamId,
//                           initialData: initialData,
//                           onJamUpdated: (updatedData) async {
//                             await _executeAction(
//                               database.updateJam,
//                               updatedData,
//                               "Jam updated successfully",
//                             );
//                           },
//                         ),
//                       );
//                     } catch (e) {
//                       _showMessage("Error fetching jam details: $e",
//                           isError: true);
//                     }
//                   }
//                 },
//                 child: Text("Update"),
//               ),
//             ],
//           );
//         },
//       );
//     } catch (e) {
//       _showMessage("Error fetching jams: $e", isError: true);
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   void _fetchAndOpenDeleteJamDialog() async {
//     setState(() => isLoading = true);
//     try {
//       DocumentList jamList = await database.listJams();
//       Map<String, String> jamMap = {
//         for (var doc in jamList.documents) doc.data['title']: doc.$id
//       };

//       showDialog(
//         context: context,
//         builder: (context) => DeleteJamDialog(
//           jamMap: jamMap,
//           onJamDeleted: (jamId) async {
//             await _executeAction(
//               database.deleteJam,
//               {"jamId": jamId},
//               "Jam deleted successfully",
//             );
//           },
//         ),
//       );
//     } catch (e) {
//       _showMessage("Error fetching jams: $e", isError: true);
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   void _fetchAndOpenAddLessonDialog(String journeyTitle) async {
//     setState(() => isLoading = true);
//     try {
//       // Get the journey ID for the provided journey title
//       DocumentList journeyList = await database.listJourneys();
//       final journeyDoc = journeyList.documents.firstWhere(
//         (doc) => doc.data['title'] == journeyTitle,
//         orElse: () => throw Exception("Journey not found"),
//       );

//       final journeyId = journeyDoc.$id;
//       _openAddLessonDialog(journeyId, journeyTitle);
//     } catch (e) {
//       _showMessage("Error fetching journey: $e", isError: true);
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   void _openAddLessonDialog(String journeyId, String journeyTitle) {
//     Uint8List? selectedFileBytes;
//     String? selectedFileName;

//     showDialog(
//       context: context,
//       builder: (context) {
//         return StandardDialog(
//           title: "Add Lesson to $journeyTitle",
//           content: StatefulBuilder(
//             builder: (context, setState) {
//               return Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   StandardButton(
//                     label: Text(selectedFileName ?? "Select Lesson File"),
//                     onPressed: () async {
//                       FilePickerResult? result =
//                           await FilePicker.platform.pickFiles(
//                         type: FileType.custom,
//                         allowedExtensions: ['md'], // Allow only markdown files
//                         withData: true, // Load file data directly into memory
//                       );

//                       if (result != null && result.files.single.bytes != null) {
//                         setState(() {
//                           selectedFileName = result.files.single.name;
//                           selectedFileBytes = result.files.single.bytes;
//                         });
//                         LogService.instance.info(
//                             "File selected: $selectedFileName - ${selectedFileBytes?.lengthInBytes ?? 0} bytes");
//                       } else {
//                         LogService.instance
//                             .error("No file selected or file has no bytes.");
//                       }
//                     },
//                   ),
//                 ],
//               );
//             },
//           ),
//           submitButtonLabel: "Upload",
//           submitButtonOnPressed: () async {
//             if (!mounted) return; // Ensure widget is still mounted
//             if (selectedFileBytes == null) {
//               _showMessage("Please select a lesson file.", isError: true);
//               return;
//             }

//             try {
//               // Step 1: Upload file using the Storage API
//               LogService.instance.info(
//                   "Uploading file: $selectedFileName with ${selectedFileBytes!.lengthInBytes} bytes");
//               final fileUrl = await storage.uploadLesson(
//                   selectedFileBytes!, selectedFileName!);

//               // Step 2: Add the uploaded file URL to the journey
//               LogService.instance.info("File uploaded. URL: $fileUrl");
//               await database.addLessonToJourney(journeyId, fileUrl);

//               Navigator.of(context).pop();
//               _showMessage("Lesson uploaded successfully");
//             } catch (e) {
//               LogService.instance.error("Error uploading lesson: $e");
//               _showMessage("Error uploading lesson: $e", isError: true);
//             }
//           },
//         );
//       },
//     );
//   }

//   void _openUpdateJourneyDialog(Map<String, String> journeyMap) {
//     String? selectedTitle;

//     // Capture the parent context
//     final parentContext = context;

//     showDialog(
//       context: parentContext, // Use parentContext here
//       builder: (context) {
//         return AlertDialog(
//           title: Text("Select Journey to Update"),
//           content: StatefulBuilder(
//             builder: (context, setState) {
//               return DropdownButtonFormField<String>(
//                 value: selectedTitle,
//                 hint: Text("Select Journey"),
//                 items: journeyMap.keys.map((title) {
//                   return DropdownMenuItem(
//                     value: title,
//                     child: Text(title),
//                   );
//                 }).toList(),
//                 onChanged: (value) async {
//                   setState(() {
//                     selectedTitle = value;
//                   });
//                 },
//               );
//             },
//           ),
//           actions: [
//             TextButton(
//               onPressed: () =>
//                   Navigator.of(parentContext).pop(), // Close dialog
//               child: Text("Cancel"),
//             ),
//             TextButton(
//               onPressed: () async {
//                 if (selectedTitle != null) {
//                   final journeyId = journeyMap[selectedTitle]!;
//                   Navigator.of(parentContext).pop(); // Close selection dialog

//                   try {
//                     final journeyDoc = await database.getJourneyById(journeyId);
//                     Map<String, dynamic> initialData = {
//                       "title": journeyDoc.data['title'] ?? '',
//                       "start_date": journeyDoc.data['start_date'] ?? '',
//                       "active": journeyDoc.data['active'] ?? false,
//                     };

//                     // Use parentContext when showing the next dialog
//                     showDialog(
//                       context: parentContext,
//                       builder: (context) => UpdateJourneyDialog(
//                         journeyId: journeyId,
//                         initialData: initialData,
//                         onJourneyUpdated: (updatedData) async {
//                           await _executeAction(
//                             database.updateJourney,
//                             updatedData,
//                             "Journey updated successfully",
//                           );
//                         },
//                       ),
//                     );
//                   } catch (e) {
//                     LogService.instance
//                         .error("Error fetching journey details: $e");
//                     _showMessage("Error fetching journey details: $e",
//                         isError: true);
//                   }
//                 }
//               },
//               child: Text("Update"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _openCreateJourneyDialog() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return CreateJourneyDialog(
//           onJourneyCreated: (journeyData) async {
//             // Call the `createJourney` method on the database API
//             await _executeAction(
//               database.createJourney,
//               journeyData,
//               "Journey created successfully",
//             );
//           },
//         );
//       },
//     );
//   }

//   void _openCreateJamDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => CreateJamDialog(
//         onJamCreated: (jamData) async {
//           await _executeAction(
//             database.createJam,
//             jamData,
//             "Jam created successfully",
//           );
//         },
//       ),
//     );
//   }

//   void _fetchAndOpenUpdateJourneyPage() async {
//     setState(() => isLoading = true);
//     try {
//       // Fetch the list of journeys
//       DocumentList journeyList = await database.listJourneys();
//       Map<String, String> journeyMap = {
//         for (var doc in journeyList.documents) doc.data['title']: doc.$id
//       };

//       // Show a dialog to select the journey
//       _openJourneySelectionDialog(journeyMap);
//     } catch (e) {
//       _showMessage("Error fetching journeys: $e", isError: true);
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   void _openJourneySelectionDialog(Map<String, String> journeyMap) {
//     String? selectedTitle;

//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text("Select Journey"),
//           content: StatefulBuilder(
//             builder: (context, setState) {
//               return DropdownButtonFormField<String>(
//                 value: selectedTitle,
//                 hint: Text("Select Journey"),
//                 items: journeyMap.keys.map((title) {
//                   return DropdownMenuItem(
//                     value: title,
//                     child: Text(title),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     selectedTitle = value;
//                   });
//                 },
//               );
//             },
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(), // Close dialog
//               child: Text("Cancel"),
//             ),
//             TextButton(
//               onPressed: () {
//                 if (selectedTitle != null) {
//                   // Get the journeyId from the selectedTitle
//                   final journeyId = journeyMap[selectedTitle]!;
//                   Navigator.of(context).pop(); // Close dialog
//                   _openUpdateJourneyPage(journeyId, selectedTitle!);
//                 }
//               },
//               child: Text("Open"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _openUpdateJourneyPage(String journeyId, String journeyTitle) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) => JourneyPage(
//           journeyId: journeyId,
//           journeyTitle: journeyTitle,
//           database: database,
//           storage: storage,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Content Management"),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: GridView.count(
//           crossAxisCount: 1, // Set to single column for better readability
//           crossAxisSpacing: 8.0,
//           mainAxisSpacing: 8.0,
//           childAspectRatio: 6,
//           shrinkWrap: true,
//           children: [
//             StandardCard(
//               icon: Icons.add,
//               title: "Create Journey",
//               onTap: _openCreateJourneyDialog,
//             ),
//             StandardCard(
//               icon: Icons.edit,
//               title: "Update Journey",
//               onTap: _fetchAndOpenUpdateJourneyDialog,
//             ),
//             StandardCard(
//               icon: Icons.list,
//               title: "Update Journey Lessons",
//               onTap: _fetchAndOpenUpdateJourneyPage,
//             ),
//             StandardCard(
//               icon: Icons.delete,
//               title: "Delete Journey",
//               onTap: _fetchAndOpenDeleteJourneyDialog,
//             ),
//             StandardCard(
//               icon: Icons.add,
//               title: "Create Jam",
//               onTap: _openCreateJamDialog,
//             ),
//             StandardCard(
//               icon: Icons.edit,
//               title: "Update Jam",
//               onTap: _fetchAndOpenUpdateJamDialog,
//             ),
//             StandardCard(
//               icon: Icons.delete,
//               title: "Delete Jam",
//               onTap: _fetchAndOpenDeleteJamDialog,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
