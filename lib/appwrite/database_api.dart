import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:photojam_app/constants/constants.dart';

class DatabaseAPI {
  final Client client;
  final Databases databases;

  DatabaseAPI(this.client) : databases = Databases(client);

/////////////// Journey API calls ////////////////
  /// Creates a new journey
  Future<Document> createJourney(Map<String, dynamic> data) async {
    try {
      return await databases.createDocument(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JOURNEYS,
        documentId: 'unique()',
        data: data,
      );
    } catch (e) {
      print('Error creating journey: $e');
      rethrow;
    }
  }

  /// Retrieve a specific journey by its ID.
  Future<Document> getJourneyById(String journeyId) async {
    try {
      return await databases.getDocument(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JOURNEYS,
        documentId: journeyId,
      );
    } catch (e) {
      print('Error fetching journey: $e');
      rethrow;
    }
  }

  /// Retrieve a List of all journeys
  Future<DocumentList> getJourneys() async {
    try {
      return await databases.listDocuments(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JOURNEYS,
      );
    } catch (e) {
      print('Error fetching All journeys: $e');
      rethrow;
    }
  }

  /// Retrieves a list of all active journeys
  Future<DocumentList> getAllActiveJourneys() async {
    try {
      return await databases.listDocuments(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JOURNEYS,
        queries: [Query.equal('active', true)],
      );
    } catch (e) {
      print('Error fetching active journeys: $e');
      rethrow;
    }
  }

  /// Get all journeys and filter by participant_ids in code
  Future<DocumentList> getJourneysByUser(String userId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JOURNEYS,
      );
      final filteredDocuments = response.documents.where((doc) {
        return (doc.data['participant_ids'] ?? []).contains(userId);
      }).toList();
      return DocumentList(
        documents: filteredDocuments,
        total: filteredDocuments.length,
      );
    } catch (e) {
      print('Error fetching journeys for user $userId: $e');
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
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JOURNEYS,
        documentId: journeyId,
        data: {'participant_ids': participants},
      );
    } catch (e) {
      print('Error adding user to journey: $e');
      rethrow;
    }
  }

/////////////// Jam API calls ////////////////
  /// Create new jam
  Future<Document> createJam(Map<String, dynamic> data) async {
    try {
      return await databases.createDocument(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JAMS,
        documentId: 'unique()',
        data: data,
      );
    } catch (e) {
      print('Error creating jam: $e');
      rethrow;
    }
  }

  /// Updates a specific jam by its ID
  Future<void> updateJam(Map<String, dynamic> data) async {
    try {
      await databases.updateDocument(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JAMS,
        documentId: data['jamId'],
        data: {'title': data['title']}, // Update fields as necessary
      );
    } catch (e) {
      print('Error updating jam: $e');
      rethrow;
    }
  }

  /// Deletes a specific jam by ID
  Future<void> deleteJam(Map<String, dynamic> data) async {
    try {
      await databases.deleteDocument(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JAMS,
        documentId: data['jamId'],
      );
    } catch (e) {
      print('Error deleting jam: $e');
      rethrow;
    }
  }

  /// Retrieve a List of all jams
  Future<DocumentList> getJams() {
    return databases.listDocuments(
      databaseId: APPWRITE_DATABASE_ID,
      collectionId: COLLECTION_JAMS,
    );
  }

  /// Retrieve a specific jam by its ID.
  Future<Document> getJamById(String jamId) async {
    try {
      return await databases.getDocument(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JAMS, // Use the correct collection ID for jams
        documentId: jamId,
      );
    } catch (e) {
      print('Error fetching jam: $e');
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
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JAMS,
        documentId: jamId,
        data: {'submissions': submissions},
      );
    } catch (e) {
      print('Error adding submission to jam: $e');
      rethrow;
    }
  }

  Future<List<Document>> getUserJamsWithSubmissions(String userId) async {
    try {
      // Step 1: Retrieve all submissions made by the user
      final userSubmissions = await databases.listDocuments(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_SUBMISSIONS,
        queries: [
          Query.equal('user_id', userId), // Filter by userId in submissions
        ],
      );

      return userSubmissions.documents;
    } catch (e) {
      print("Error fetching jams with submissions for user $userId: $e");
      return []; // Return an empty list if the query fails
    }
  }

/////////////// Submission API calls ////////////////

  /// Retrieve a List of submissions by a user_id in order of date
  Future<List<Document>> getSubmissionsByUser({required String userId}) async {
    try {
      // Query submissions for the specified user ID and order by date
      final submissionsResult = await databases.listDocuments(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_SUBMISSIONS,
        queries: [
          Query.equal('user_id', userId), // Use the provided userId
          Query.orderDesc('date'), // Order by date in descending order
        ],
      );

      return submissionsResult.documents;
    } catch (e) {
      print('Error fetching all submissions: $e');
      rethrow;
    }
  }

  /// Deletes a submission by its ID
  Future<void> deleteSubmission(String submissionId) async {
    try {
      await databases.deleteDocument(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_SUBMISSIONS,
        documentId: submissionId,
      );
      print("Submission with ID $submissionId deleted successfully.");
    } catch (e) {
      print("Error deleting submission with ID $submissionId: $e");
      rethrow;
    }
  }

  /// Retrieve a List of submissions by associated jam
  Future<DocumentList> getSubmissionsByJam(String jamId) async {
    try {
      return await databases.listDocuments(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_SUBMISSIONS,
        queries: [Query.equal('jam', jamId)],
      );
    } catch (e) {
      print('Error fetching submissions for jam $jamId: $e');
      rethrow;
    }
  }

  // Updates an existing submission with new photos and date
  Future<void> updateSubmission(
      String submissionId, List<String> photoUrls, String date) async {
    try {
      await databases.updateDocument(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_SUBMISSIONS,
        documentId: submissionId,
        data: {'photos': photoUrls, 'date': date},
      );
    } catch (e) {
      print("Error updating submission: $e");
      rethrow;
    }
  }

// Updated createSubmission to include user_id
  Future<Document> createSubmission(
      String jam, List<String> photos, String userId) async {
    try {
      return await databases.createDocument(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_SUBMISSIONS,
        documentId: 'unique()',
        data: {
          'user_id': userId, // Ensure user_id matches your schema
          'jam': jam, // Make sure jam matches the schema field
          'photos': photos,
          'date': DateTime.now().toIso8601String()
        },
      );
    } catch (e) {
      print('Error creating submission: $e');
      rethrow;
    }
  }

// Updated getUserSubmissionForJam to query based on jam and user_id
  Future<Document?> getUserSubmissionForJam(String jam, String userId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_SUBMISSIONS,
        queries: [
          Query.equal('jam', jam), // Correct field name as per schema
          Query.equal(
              'user_id', userId) // Check submission by both jam and user
        ],
      );
      return response.documents.isNotEmpty ? response.documents.first : null;
    } catch (e) {
      print("Error fetching submission: $e");
      return null;
    }
  }

  /// Retrieves a list of all jams
  Future<DocumentList> listJams() async {
    try {
      return await databases.listDocuments(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JAMS,
      );
    } catch (e) {
      print('Error fetching all jams: $e');
      rethrow;
    }
  }

  /// Retrieves a list of all journeys
  Future<DocumentList> listJourneys() async {
    try {
      return await databases.listDocuments(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JOURNEYS,
      );
    } catch (e) {
      print('Error fetching all journeys: $e');
      rethrow;
    }
  }

  /// Updates a specific journey by its ID
  Future<void> updateJourney(Map<String, dynamic> data) async {
    try {
      await databases.updateDocument(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JOURNEYS,
        documentId: data['journeyId'],
        data: {'name': data['name']}, // Update fields as necessary
      );
    } catch (e) {
      print('Error updating journey: $e');
      rethrow;
    }
  }

  /// Deletes a specific journey by ID
  Future<void> deleteJourney(Map<String, dynamic> data) async {
    try {
      await databases.deleteDocument(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JOURNEYS,
        documentId: data['journeyId'],
      );
    } catch (e) {
      print('Error deleting journey: $e');
      rethrow;
    }
  }

  /// Adds a lesson URL to a specified journey
  Future<void> addLessonToJourney(String journeyId, String lessonURL) async {
    try {
      // Fetch the current journey document to get all existing attributes
      final journey = await databases.getDocument(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JOURNEYS,
        documentId: journeyId,
      );

      // Get the current list of lessons, or initialize it if it's null
      List<dynamic> lessons = journey.data['lessons'] ?? [];
      lessons.add(lessonURL);

      // Retrieve the 'active' attribute (or any other required attributes) from the existing journey
      bool isActive = journey.data['active'];

      // Update the journey document, including the required 'active' attribute
      await databases.updateDocument(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JOURNEYS,
        documentId: journeyId,
        data: {
          'lessons': lessons,
          'active': isActive, // Include the required 'active' attribute
        },
      );
    } catch (e) {
      print('Error adding lesson to journey: $e');
      rethrow;
    }
  }
}
