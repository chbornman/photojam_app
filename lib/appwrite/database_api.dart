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

  /// Updates a journey with a new lesson
  Future<void> addLessonToJourney(String journeyId, String lessonUrl) async {
    try {
      final journey = await getJourneyById(journeyId);
      List lessons = journey.data['lessons'] ?? [];
      lessons.add(lessonUrl);
      await databases.updateDocument(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JOURNEYS,
        documentId: journeyId,
        data: {'lessons': lessons},
      );
    } catch (e) {
      print('Error adding lesson to journey: $e');
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

/////////////// Submission API calls ////////////////
  /// Create new submission
  Future<Document> createSubmission(Map<String, dynamic> data) async {
    try {
      return await databases.createDocument(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_SUBMISSIONS,
        documentId: 'unique()',
        data: data,
      );
    } catch (e) {
      print('Error creating submission: $e');
      rethrow;
    }
  }

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
}
