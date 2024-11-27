import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/appwrite_config.dart';
import 'package:photojam_app/appwrite/database/repositories/base_repository.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/core/services/log_service.dart';

/// Database repository implementation
class AppwriteDatabaseRepository implements DatabaseRepository {
  final Databases _databases;
  final String databaseId;

  AppwriteDatabaseRepository(this._databases, {required this.databaseId});

  @override
  Future<Document> createDocument(
    String collectionId,
    Map<String, dynamic> data,
  ) async {
    try {
      LogService.instance
          .info('Creating document in collection: $collectionId');
      LogService.instance.info('Document data: $data');

      final doc = await _databases.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: ID.unique(),
        data: data,
      );

      LogService.instance.info('Created document with ID: ${doc.$id}');
      return doc;
    } catch (e) {
      LogService.instance.error('Error creating document: $e');
      rethrow;
    }
  }

  @override
  Future<Document> getDocument(String collectionId, String documentId) async {
    try {
      LogService.instance.info(
          'Fetching document: $documentId from collection: $collectionId');

      final doc = await _databases.getDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
      );

      LogService.instance.info('Retrieved document: ${doc.$id}');
      return doc;
    } catch (e) {
      LogService.instance.error('Error fetching document: $e');
      rethrow;
    }
  }

  @override
  Future<DocumentList> listDocuments(
    String collectionId, {
    List<String>? queries,
    List<String>? orderField,
  }) async {
    try {
      LogService.instance
          .info('Listing documents in collection: $collectionId');
      if (queries != null) {
        LogService.instance.info('With queries: $queries');
      }

      final docs = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: queries,
      );

      LogService.instance.info('Retrieved ${docs.documents.length} documents');
      return docs;
    } catch (e) {
      LogService.instance.error('Error listing documents: $e');
      rethrow;
    }
  }

  @override
  Future<Document> updateDocument(
    String collectionId,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      LogService.instance
          .info('Updating document: $documentId in collection: $collectionId');
      LogService.instance.info('Update data: $data');

      final doc = await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
        data: data,
      );

      LogService.instance.info('Updated document: ${doc.$id}');
      return doc;
    } catch (e) {
      LogService.instance.error('Error updating document: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteDocument(String collectionId, String documentId) async {
    try {
      LogService.instance.info(
          'Deleting document: $documentId from collection: $collectionId');

      await _databases.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
      );

      LogService.instance.info('Deleted document: $documentId');
    } catch (e) {
      LogService.instance.error('Error deleting document: $e');
      rethrow;
    }
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
