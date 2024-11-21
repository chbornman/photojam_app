
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/appwrite_config.dart';
import 'package:photojam_app/appwrite/database/repositories/base_repository.dart';
import 'package:photojam_app/config/app_constants.dart';

/// Database repository implementation
class AppwriteDatabaseRepository implements DatabaseRepository {
  final Databases _databases;
  final String databaseId;

  AppwriteDatabaseRepository(this._databases, {required this.databaseId});

  @override
  Future<Document> createDocument(
      String collectionId, Map<String, dynamic> data) async {
    return await _databases.createDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      data: data,
      documentId: ID.unique(),
    );
  }

  @override
  Future<Document> getDocument(String collectionId, String documentId) async {
    return await _databases.getDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      documentId: documentId,
    );
  }

  @override
  Future<DocumentList> listDocuments(
    String collectionId, {
    List<String>? queries,
    List<String>? orderField,
  }) async {
    return await _databases.listDocuments(
      databaseId: databaseId,
      collectionId: collectionId,
      queries: queries,
    );
  }

  @override
  Future<Document> updateDocument(
    String collectionId,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    return await _databases.updateDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      documentId: documentId,
      data: data,
    );
  }

  @override
  Future<void> deleteDocument(String collectionId, String documentId) async {
    await _databases.deleteDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      documentId: documentId,
    );
  }
}

/// Main database repository provider
final databaseRepositoryProvider = Provider<DatabaseRepository>((ref) {
  final databases = ref.watch(appwriteDatabasesProvider);
  return AppwriteDatabaseRepository(
    databases,
    databaseId: AppConstants.appwriteDatabaseId,
  );
});


