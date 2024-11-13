import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:photojam_app/log_service.dart';

class DatabaseAPI {
  final Client client;
  final Databases databases;

  DatabaseAPI(this.client) : databases = Databases(client);

/////////////// Journey API calls ////////////////
  /// Creates a new journey
  Future<Document> createJourney(Map<String, dynamic> data) async {
    try {
      return await databases.createDocument(
        databaseId: appwriteDatabaseId,
        collectionId: collectionJourneys,
        documentId: 'unique()',
        data: data,
      );
    } catch (e) {
      LogService.instance.error('Error creating journey: $e');
      rethrow;
    }
  }

  /// Retrieve a specific journey by its ID.
  Future<Document> getJourneyById(String journeyId) async {
    try {
      return await databases.getDocument(
        databaseId: appwriteDatabaseId,
        collectionId: collectionJourneys,
        documentId: journeyId,
      );
    } catch (e) {
      LogService.instance.error('Error fetching journey: $e');
      rethrow;
    }
  }

  /// Retrieve a List of all journeys
  Future<DocumentList> getJourneys() async {
    try {
      return await databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: collectionJourneys,
      );
    } catch (e) {
      LogService.instance.error('Error fetching All journeys: $e');
      rethrow;
    }
  }

  /// Retrieves a list of all active journeys
  Future<DocumentList> getAllActiveJourneys() async {
    try {
      return await databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: collectionJourneys,
        queries: [Query.equal('active', true)],
      );
    } catch (e) {
      LogService.instance.error('Error fetching active journeys: $e');
      rethrow;
    }
  }

  /// Get all journeys and filter by participant_ids in code
  Future<DocumentList> getJourneysByUser(String userId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: collectionJourneys,
      );
      final filteredDocuments = response.documents.where((doc) {
        return (doc.data['participant_ids'] ?? []).contains(userId);
      }).toList();
      return DocumentList(
        documents: filteredDocuments,
        total: filteredDocuments.length,
      );
    } catch (e) {
      LogService.instance.error('Error fetching journeys for user $userId: $e');
      rethrow;
    }
  }

  /// Update a journey with a participant
  Future<void> addUserToJourney(String journeyId, String userId) async {
    try {
      final journey = await getJourneyById(journeyId);
      List participants = journey.data['participant_ids'] ?? [];
      participants.add(userId);
      await databases.updateDocument(
        databaseId: appwriteDatabaseId,
        collectionId: collectionJourneys,
        documentId: journeyId,
        data: {'participant_ids': participants},
      );
    } catch (e) {
      LogService.instance.error('Error adding user to journey: $e');
      rethrow;
    }
  }

/////////////// Jam API calls ////////////////
  /// Create new jam
  Future<Document> createJam(Map<String, dynamic> data) async {
    try {
      return await databases.createDocument(
        databaseId: appwriteDatabaseId,
        collectionId: collectionJams,
        documentId: 'unique()',
        data: data,
      );
    } catch (e) {
      LogService.instance.error('Error creating jam: $e');
      rethrow;
    }
  }

  /// Updates a specific jam by its ID
  Future<void> updateJam(Map<String, dynamic> data) async {
    try {
      await databases.updateDocument(
        databaseId: appwriteDatabaseId,
        collectionId: collectionJams,
        documentId: data['jamId'],
        data: {
          'title': data['title'],
          'date': data['date'],
          'zoom_link': data['zoom_link'],
        },
      );
    } catch (e) {
      LogService.instance.error('Error updating jam: $e');
      rethrow;
    }
  }

  /// Deletes a specific jam by ID
  Future<void> deleteJam(Map<String, dynamic> data) async {
    try {
      await databases.deleteDocument(
        databaseId: appwriteDatabaseId,
        collectionId: collectionJams,
        documentId: data['jamId'],
      );
    } catch (e) {
      LogService.instance.error('Error deleting jam: $e');
      rethrow;
    }
  }

  /// Retrieve a List of all jams
  Future<DocumentList> getJams() {
    return databases.listDocuments(
      databaseId: appwriteDatabaseId,
      collectionId: collectionJams,
    );
  }

  Future<DocumentList> getJamsByUser(String userId) async {
    try {
      // Step 1: Get all submissions for the specified user
      final submissionsResponse = await databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: collectionSubmissions,
        queries: [
          Query.equal('user_id', userId),
        ],
      );

      // Extract unique jam IDs from the submissions
      final jamIds = submissionsResponse.documents
          .map((doc) =>
              doc.data['jam']['\$id']) // Access the document ID of the jam
          .toSet()
          .toList();

      // Step 2: Fetch each jam by ID and accumulate results
      List<Document> jamDocuments = [];
      for (String jamId in jamIds) {
        final jamResponse = await databases.getDocument(
          databaseId: appwriteDatabaseId,
          collectionId: collectionJams,
          documentId: jamId,
        );
        jamDocuments.add(jamResponse);
      }

      return DocumentList(
        documents: jamDocuments,
        total: jamDocuments.length,
      );
    } catch (e) {
      LogService.instance.error('Error fetching jams for user $userId: $e');
      rethrow;
    }
  }

  Future<DocumentList> getUpcomingJamsByUser(String userId) async {
    try {
      // Step 1: Fetch jams the user is a part of
      final userJamDocuments = await getJamsByUser(userId);

      // Step 2: Filter out jams that are in the past
      final now = DateTime.now();
      final upcomingJams = userJamDocuments.documents.where((doc) {
        // Check if 'date' exists and is a String, then parse it
        final dateValue = doc.data['date'];
        if (dateValue is String) {
          final jamDate = DateTime.parse(dateValue);
          return jamDate.isAfter(now); // Keep only future jams
        } else {
          LogService.instance.info("Warning: date is not a String for document ID ${doc.$id}");
          return false;
        }
      }).toList();

      // Step 3: Return the filtered list as a DocumentList
      return DocumentList(
        documents: upcomingJams,
        total: upcomingJams.length,
      );
    } catch (e) {
      LogService.instance.error('Error fetching upcoming jams for user $userId: $e');
      rethrow;
    }
  }

  /// Retrieve a specific jam by its ID.
  Future<Document> getJamById(String jamId) async {
    try {
      return await databases.getDocument(
        databaseId: appwriteDatabaseId,
        collectionId: collectionJams, // Use the correct collection ID for jams
        documentId: jamId,
      );
    } catch (e) {
      LogService.instance.error('Error fetching jam: $e');
      rethrow;
    }
  }

  /// Update jam with new submission
  Future<void> addSubmissionToJam(String jamId, String submissionId) async {
    try {
      final jam = await getJamById(jamId);
      List submissions = jam.data['submissions'] ?? [];
      submissions.add(submissionId);
      await databases.updateDocument(
        databaseId: appwriteDatabaseId,
        collectionId: collectionJams,
        documentId: jamId,
        data: {'submissions': submissions},
      );
    } catch (e) {
      LogService.instance.error('Error adding submission to jam: $e');
      rethrow;
    }
  }

  Future<List<Document>> getUserJamsWithSubmissions(String userId) async {
    try {
      // Step 1: Retrieve all submissions made by the user
      final userSubmissions = await databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: collectionSubmissions,
        queries: [
          Query.equal('user_id', userId), // Filter by userId in submissions
        ],
      );

      return userSubmissions.documents;
    } catch (e) {
      LogService.instance.error("Error fetching jams with submissions for user $userId: $e");
      return []; // Return an empty list if the query fails
    }
  }

/////////////// Submission API calls ////////////////

  /// Retrieve a List of submissions by a user_id in order of date
  Future<List<Document>> getSubmissionsByUser({required String userId}) async {
    try {
      // Query submissions for the specified user ID and order by date
      final submissionsResult = await databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: collectionSubmissions,
        queries: [
          Query.equal('user_id', userId), // Use the provided userId
          Query.orderDesc('date'), // Order by date in descending order
        ],
      );

      return submissionsResult.documents;
    } catch (e) {
      LogService.instance.error('Error fetching all submissions: $e');
      rethrow;
    }
  }

  /// Deletes a submission by its ID
  Future<void> deleteSubmission(String submissionId) async {
    try {
      await databases.deleteDocument(
        databaseId: appwriteDatabaseId,
        collectionId: collectionSubmissions,
        documentId: submissionId,
      );
      LogService.instance.info("Submission with ID $submissionId deleted successfully.");
    } catch (e) {
      LogService.instance.error("Error deleting submission with ID $submissionId: $e");
      rethrow;
    }
  }

  /// Retrieve a List of submissions by associated jam
  Future<DocumentList> getSubmissionsByJam(String jamId) async {
    try {
      return await databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: collectionSubmissions,
        queries: [Query.equal('jam', jamId)],
      );
    } catch (e) {
      LogService.instance.error('Error fetching submissions for jam $jamId: $e');
      rethrow;
    }
  }

  /// Retrieve a single submission by associated jam and user
  Future<Document> getSubmissionByJamAndUser(String jamId, String userId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: collectionSubmissions,
        queries: [
          Query.equal('jam', jamId),
          Query.equal('user_id', userId),
        ],
      );

      if (response.documents.isNotEmpty) {
        return response.documents.first;
      } else {
        throw Exception('No submission found for jam $jamId and user $userId');
      }
    } catch (e) {
      LogService.instance.error('Error fetching submission for jam $jamId and user $userId: $e');
      rethrow;
    }
  }

  // Updates an existing submission with new photos and date
  Future<void> updateSubmission(
      String submissionId, List<String> photoUrls, String date, String comment) async {
    try {
      await databases.updateDocument(
        databaseId: appwriteDatabaseId,
        collectionId: collectionSubmissions,
        documentId: submissionId,
        data: {'photos': photoUrls, 'date': date, 'comment': comment},
      );
    } catch (e) {
      LogService.instance.error("Error updating submission: $e");
      rethrow;
    }
  }

// Updated createSubmission to include user_id
  Future<Document> createSubmission(
      String jam, List<String> photos, String userId, String comment) async {
    try {
      return await databases.createDocument(
        databaseId: appwriteDatabaseId,
        collectionId: collectionSubmissions,
        documentId: 'unique()',
        data: {
          'user_id': userId, // Ensure user_id matches your schema
          'jam': jam, // Make sure jam matches the schema field
          'photos': photos,
          'date': DateTime.now().toIso8601String(),
          'comment': comment,
        },
      );
    } catch (e) {
      LogService.instance.error('Error creating submission: $e');
      rethrow;
    }
  }

// Updated getUserSubmissionForJam to query based on jam and user_id
  Future<Document?> getUserSubmissionForJam(String jam, String userId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: collectionSubmissions,
        queries: [
          Query.equal('jam', jam), // Correct field name as per schema
          Query.equal(
              'user_id', userId) // Check submission by both jam and user
        ],
      );
      return response.documents.isNotEmpty ? response.documents.first : null;
    } catch (e) {
      LogService.instance.error("Error fetching submission: $e");
      return null;
    }
  }

  /// Retrieves a list of all jams
  Future<DocumentList> listJams() async {
    try {
      return await databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: collectionJams,
      );
    } catch (e) {
      LogService.instance.error('Error fetching all jams: $e');
      rethrow;
    }
  }

  /// Retrieves a list of all journeys
  Future<DocumentList> listJourneys() async {
    try {
      return await databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: collectionJourneys,
      );
    } catch (e) {
      LogService.instance.error('Error fetching all journeys: $e');
      rethrow;
    }
  }

  /// Updates a specific journey by its ID
  Future<void> updateJourney(Map<String, dynamic> data) async {
    try {
      await databases.updateDocument(
        databaseId: appwriteDatabaseId,
        collectionId: collectionJourneys,
        documentId: data['journeyId'],
        data: {
          'title': data['title'],
          'start_date': data['start_date'],
          'active': data['active'],
        },
      );
    } catch (e) {
      LogService.instance.error('Error updating journey: $e');
      rethrow;
    }
  }

  /// Deletes a specific journey by ID
  Future<void> deleteJourney(Map<String, dynamic> data) async {
    try {
      await databases.deleteDocument(
        databaseId: appwriteDatabaseId,
        collectionId: collectionJourneys,
        documentId: data['journeyId'],
      );
    } catch (e) {
      LogService.instance.error('Error deleting journey: $e');
      rethrow;
    }
  }

  /// Updates the lesson URLs of a specified journey
  Future<void> updateJourneyLessons(
      String journeyId, List<String> lessonUrls) async {
    try {
      // Fetch the current journey document to ensure other attributes are retained
      final journey = await databases.getDocument(
        databaseId: appwriteDatabaseId,
        collectionId: collectionJourneys,
        documentId: journeyId,
      );

      // Retrieve the 'active' attribute (or any other required attributes) from the existing journey
      bool isActive = journey.data['active'] ?? true;
      String title = journey.data['title'] ?? 'Untitled Journey';
      String startDate =
          journey.data['start_date'] ?? DateTime.now().toIso8601String();

      // Update the journey document with the new list of lessons, while keeping other attributes intact
      await databases.updateDocument(
        databaseId: appwriteDatabaseId,
        collectionId: collectionJourneys,
        documentId: journeyId,
        data: {
          'lessons': lessonUrls, // Replace with the new list of lesson URLs
          'active': isActive, // Keep other attributes unchanged
          'title': title,
          'start_date': startDate,
        },
      );
    } catch (e) {
      LogService.instance.error('Error updating journey lessons: $e');
      rethrow;
    }
  }

  /// Adds a lesson URL to a specified journey
  Future<void> addLessonToJourney(String journeyId, String lessonURL) async {
    try {
      // Fetch the current journey document to get all existing attributes
      final journey = await databases.getDocument(
        databaseId: appwriteDatabaseId,
        collectionId: collectionJourneys,
        documentId: journeyId,
      );

      // Get the current list of lessons, or initialize it if it's null
      List<dynamic> lessons = journey.data['lessons'] ?? [];
      lessons.add(lessonURL);

      // Retrieve the 'active' attribute (or any other required attributes) from the existing journey
      bool isActive = journey.data['active'];

      // Update the journey document, including the required 'active' attribute
      await databases.updateDocument(
        databaseId: appwriteDatabaseId,
        collectionId: collectionJourneys,
        documentId: journeyId,
        data: {
          'lessons': lessons,
          'active': isActive, // Include the required 'active' attribute
        },
      );
    } catch (e) {
      LogService.instance.error('Error adding lesson to journey: $e');
      rethrow;
    }
  }
}
