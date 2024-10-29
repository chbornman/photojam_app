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

  Future<DocumentList> getMessages() {
    return databases.listDocuments(
      databaseId: APPWRITE_DATABASE_ID,
      collectionId: COLLECTION_MESSAGES,
    );
  }

  Future<Document> addMessage({required String message}) {
    return databases.createDocument(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_MESSAGES,
        documentId: ID.unique(),
        data: {
          'text': message,
          'date': DateTime.now().toString(),
          'user_id': auth.userid
        });
  }

  Future<dynamic> deleteMessage({required String id}) {
    return databases.deleteDocument(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_MESSAGES,
        documentId: id);
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
      // This assumes that there's a field like 'participants' in each journey document
      // containing user IDs, and it checks if the current user is in this list.
      return await databases.listDocuments(
        databaseId: APPWRITE_DATABASE_ID,
        collectionId: COLLECTION_JOURNEYS,
        queries: [
          Query.equal('participants', auth.userid) // Adjust as per actual field name
        ],
      );
    } catch (e) {
      print('Error fetching past journeys: $e');
      rethrow;
    }
  }
}