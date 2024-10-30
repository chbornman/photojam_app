import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/constants/constants.dart';

class DatabaseAPI {
  Client client = Client();
  late final Account account;
  late final Databases databases;
  late final Storage storage;
  final AuthAPI auth = AuthAPI();

  DatabaseAPI() {
    init();
  }

  init() {
    client
        .setEndpoint(APPWRITE_URL)
        .setProject(APPWRITE_PROJECT_ID)
        .setSelfSigned();
    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
  }

  Future<DocumentList> getJams() {
    return databases.listDocuments(
      databaseId: APPWRITE_DATABASE_ID,
      collectionId: COLLECTION_JAMS,
    );
  }

  /// Retrieves a specific journey by its ID.
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

  Future<DocumentList> getAllJourneys() async {
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

  Future<List<Document>> getAllSubmissions() async {
    try {
      // Query submissions where user_id matches the authenticated user's ID and order by date
      final submissionsResult = await databases.listDocuments(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId:
            COLLECTION_SUBMISSIONS, // Use the correct collection ID for submissions
        queries: [
          Query.equal('user_id', auth.userid), // Match user ID
          Query.orderDesc('date') // Order by date in descending order
        ],
      );

      // Return the list of submissions directly
      return submissionsResult.documents;
    } catch (e) {
      print('Error fetching All submissions: $e');
      rethrow;
    }
  }

}
