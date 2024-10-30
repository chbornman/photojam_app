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

Future<List<Document>> getAllSubmissions({required String userId}) async {
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

  /// Retrieves a specific jam by its ID.
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
}
