import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/constants/constants.dart';

class DatabaseAPI {
  Client client = Client();
  late final Account account;
  late final Databases databases;
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

  /// Retrieves a list of past journeys that the user has participated in.
  Future<DocumentList> getPastJourneys() async {
    try {
      return await databases.listDocuments(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JOURNEYS,
        queries: [
          Query.equal(
              'participants', auth.userid) // Adjust as per actual field name
        ],
      );
    } catch (e) {
      print('Error fetching past journeys: $e');
      rethrow;
    }
  }

  /// Retrieves a list of past jams that the user has participated in.
  Future<List<Document>> getPastJams() async {
    try {
      // Fetch documents where the user is listed as a participant
      final result = await databases.listDocuments(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JAMS,
        queries: [
          Query.equal('participants', auth.userid) // Adjust field as per your schema
        ],
      );

      // Sort documents by date in descending order (most recent first)
      List<Document> sortedDocuments = result.documents;
      sortedDocuments.sort((a, b) {
        final dateA = DateTime.parse(a.data['date']);
        final dateB = DateTime.parse(b.data['date']);
        return dateB.compareTo(dateA); // Descending order
      });

      return sortedDocuments;
    } catch (e) {
      print('Error fetching past jams: $e');
      rethrow;
    }
  }
}
