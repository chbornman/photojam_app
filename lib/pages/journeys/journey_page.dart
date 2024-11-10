import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/log_service.dart';
import 'package:photojam_app/pages/journeys/journeycontainer.dart';
import 'package:photojam_app/utilities/markdown_utilities.dart';
import 'package:photojam_app/utilities/markdownviewer.dart';
import 'package:photojam_app/pages/journeys/myjourneys_page.dart';
import 'package:photojam_app/utilities/standard_card.dart';
import 'package:photojam_app/utilities/standard_dialog.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class JourneyPage extends StatefulWidget {
  const JourneyPage({super.key});

  @override
  _JourneyPageState createState() => _JourneyPageState();
}

class _JourneyPageState extends State<JourneyPage> {
  late DatabaseAPI databaseApi;
  late StorageAPI storageApi;
  late AuthAPI auth;
  String? currentJourneyId;
  String journeyTitle = "Journey";
  List<Map<String, dynamic>> lessons = [];
  bool dependenciesInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!dependenciesInitialized) {
      // Initialize the providers only once
      databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
      storageApi = Provider.of<StorageAPI>(context, listen: false);
      auth = Provider.of<AuthAPI>(context, listen: false);
      dependenciesInitialized = true;

      // Start fetching data after providers are initialized
      _fetchLatestJourney();
    }
  }

  Future<void> _fetchLatestJourney() async {
    try {
      final userId = auth.userid;

      if (userId != null) {
        final response = await databaseApi.getJourneysByUser(userId);

        if (response.documents.isNotEmpty) {
          response.documents.sort((a, b) {
            final dateA = DateTime.parse(a.data['start_date']);
            final dateB = DateTime.parse(b.data['start_date']);
            return dateB.compareTo(dateA); // Latest journey first
          });

          final latestJourney = response.documents.first;
          setState(() {
            currentJourneyId = latestJourney.$id;
            journeyTitle = latestJourney.data['title'] ?? "Journey";
          });

          final lessonUrls =
              latestJourney.data['lessons'] as List<dynamic>? ?? [];
          _fetchLessonsByURLs(lessonUrls);
        } else {
          LogService.instance.info("No journeys found for this user.");
        }
      }
    } catch (e) {
      LogService.instance.error('Error fetching the latest journey: $e');
    }
  }

  Future<void> _fetchLessonsByURLs(List<dynamic> lessonUrls) async {
    List<Map<String, dynamic>> fetchedLessons = [];

    for (String url in lessonUrls) {
      try {
        Uint8List? lessonData = await _getLessonFromCache(url);

        if (lessonData != null) {
          LogService.instance.info("Loaded lesson from cache: $url");
        } else {
          LogService.instance.info("Fetching lesson from network: $url");
          lessonData = await storageApi
              .getLessonByURL(url); // Fetch from network if not cached
          await _cacheLessonLocally(url, lessonData); // Cache it for future use
        }

        final title = extractTitleFromMarkdown(lessonData);
        fetchedLessons.add({'url': url, 'title': title});
      } catch (e) {
        LogService.instance.error("Error fetching lesson title: $e");
        fetchedLessons.add({'url': url, 'title': 'Untitled Lesson'});
      }
    }

    setState(() {
      lessons = fetchedLessons;
    });
  }

  Future<Uint8List?> _getLessonFromCache(String lessonUrl) async {
    final cacheDir = await getApplicationDocumentsDirectory();
    final fileName = _generateCacheFileName(lessonUrl);
    final filePath = File('${cacheDir.path}/$fileName');

    if (await filePath.exists()) {
      LogService.instance.info("Found cached lesson for URL: $lessonUrl");
      return await filePath.readAsBytes();
    } else {
      LogService.instance.info("No cached lesson found for URL: $lessonUrl");
    }
    return null; // Return null if lesson is not in cache
  }

  void _goToMyJourneys() {
    final auth = Provider.of<AuthAPI>(context, listen: false);
    final userId = auth.userid;

    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyJourneysPage(userId: userId),
        ),
      );
    } else {
      LogService.instance.info('User ID is not available');
    }
  }

  Future<void> _openSignUpForJourneyDialog() async {
    try {
      final userId = auth.userid;

      // Fetch all active journeys the user is not signed up for
      final allJourneys = await databaseApi.getAllActiveJourneys();
      final userJourneys = await databaseApi.getJourneysByUser(userId!);

      final userJourneyIds =
          userJourneys.documents.map((doc) => doc.$id).toSet();
      final availableJourneys = allJourneys.documents
          .where((journey) => !userJourneyIds.contains(journey.$id))
          .toList();

      if (availableJourneys.isEmpty) {
        _showMessage("No available journeys to sign up for.");
        return;
      }

      String? selectedJourneyId = availableJourneys.first.$id;

      showDialog(
        context: context,
        builder: (context) {
          return StandardDialog(
            title: "Sign Up for a Journey",
            content: StatefulBuilder(
              builder: (context, setState) {
                return DropdownButtonFormField<String>(
                  value: selectedJourneyId,
                  items: availableJourneys.map((journey) {
                    return DropdownMenuItem(
                      value: journey.$id,
                      child: Text(journey.data['title'] ?? "Untitled Journey"),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedJourneyId = value;
                    });
                  },
                  decoration: InputDecoration(labelText: "Select Journey"),
                );
              },
            ),
            submitButtonLabel: "Sign Up",
            submitButtonOnPressed: () async {
              if (!mounted) return; // Ensure widget is still mounted

              if (selectedJourneyId != null) {
                await databaseApi.addUserToJourney(selectedJourneyId!, userId);
                _showMessage("Successfully signed up for the journey!");

                // Fetch lessons for the selected journey and cache them
                final selectedJourney = availableJourneys
                    .firstWhere((journey) => journey.$id == selectedJourneyId);
                final lessonUrls =
                    selectedJourney.data['lessons'] as List<dynamic>? ?? [];
                await _cacheLessons(lessonUrls);

                // Close the dialog before making any state updates
                if (mounted) Navigator.of(context).pop();

                setState(() {
                  // Refresh the screen by resetting the journey data
                  dependenciesInitialized =
                      false; // Reset to re-trigger dependencies
                  currentJourneyId = null;
                  journeyTitle = "Journey";
                  lessons.clear();
                });

                // Trigger the dependencies to load the latest journey
                if (mounted) _fetchLatestJourney();
              }
            },
          );
        },
      );
    } catch (e) {
      LogService.instance.error('Error fetching available journeys: $e');
    }
  }

  Future<void> _cacheLessons(List<dynamic> lessonUrls) async {
    for (String url in lessonUrls) {
      try {
        LogService.instance.info("Downloading lesson to cache: $url");
        final lessonData =
            await storageApi.getLessonByURL(url); // Download lesson content
        await _cacheLessonLocally(url, lessonData); // Save to local cache
      } catch (e) {
        LogService.instance.error("Error caching lesson: $e");
      }
    }
  }

  Future<void> _cacheLessonLocally(
      String lessonUrl, Uint8List lessonData) async {
    final cacheDir = await getApplicationDocumentsDirectory();
    final fileName = _generateCacheFileName(lessonUrl);
    final filePath = File('${cacheDir.path}/$fileName');
    await filePath.writeAsBytes(lessonData); // Save lesson data locally
    LogService.instance.info("Lesson cached locally for URL: $lessonUrl");
  }

  // Helper function to generate a unique cache file name based on URL
  String _generateCacheFileName(String url) {
    return base64Url
        .encode(utf8.encode(url)); // Use a base64-encoded URL as file name
  }

  // Method to view a lesson, checks cache first
  void _viewLesson(String lessonUrl) async {
    try {
      Uint8List? lessonData = await _getLessonFromCache(lessonUrl);

      if (lessonData == null) {
        LogService.instance.info("Fetching lesson for viewing from network: $lessonUrl");
        lessonData =
            await storageApi.getLessonByURL(lessonUrl); // Fetch from network
        await _cacheLessonLocally(lessonUrl, lessonData); // Cache it
      } else {
        LogService.instance.info("Viewing lesson from cache: $lessonUrl");
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarkdownViewer(content: lessonData!),
        ),
      );
    } catch (e) {
      LogService.instance.error('Error viewing lesson: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Only show the JourneyContainer if there is a journey associated
                    if (currentJourneyId != null && lessons.isNotEmpty)
                      JourneyContainer(
                        title: journeyTitle,
                        lessons: lessons,
                        theme: theme,
                        onLessonTap: _viewLesson,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            StandardCard(
              icon: Icons.library_books,
              title: "View My Journeys",
              subtitle: "See all your journeys",
              onTap: _goToMyJourneys,
            ),
            const SizedBox(height: 10),
            StandardCard(
              icon: Icons.add_circle_outline,
              title: "Sign Up for a Journey",
              subtitle: "Join a new journey",
              onTap: _openSignUpForJourneyDialog,
            ),
          ],
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }
}
