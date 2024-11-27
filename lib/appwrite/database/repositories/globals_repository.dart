import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/appwrite/database/models/globals_model.dart';
import 'package:photojam_app/appwrite/database/repositories/base_repository.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/core/services/log_service.dart';

class GlobalsRepository {
  final DatabaseRepository _db;
  final String collectionId = AppConstants.collectionGlobals;

  GlobalsRepository(this._db);

  /// Create a global setting
  Future<Globals> createGlobal({
    required String key,
    required String value,
    required String description,
  }) async {
    try {
      LogService.instance.info('Creating global with key: $key');

      final now = DateTime.now().toIso8601String();

      final documentData = {
        'key': key,
        'value': value,
        'description': description,
        'date_updated': now,
      };

      final doc = await _db.createDocument(
        collectionId,
        documentData,
      );

      LogService.instance.info('Created global document: ${doc.$id}');
      return Globals.fromDocument(doc);
    } catch (e) {
      LogService.instance.error('Error creating global: $e');
      rethrow;
    }
  }

  /// Fetch a global setting by its key
  Future<Globals?> getGlobalByKey(String key) async {
    try {
      LogService.instance.info('Fetching global by key: $key');

      final docs = await _db.listDocuments(
        collectionId,
        queries: [
          Query.equal('key', key),
        ],
      );

      if (docs.documents.isEmpty) {
        LogService.instance.info('No global found with key: $key');
        return null;
      }

      LogService.instance.info('Found global: ${docs.documents.first.$id}');
      return Globals.fromDocument(docs.documents.first);
    } catch (e) {
      LogService.instance.error('Error fetching global by key: $e');
      rethrow;
    }
  }

  /// Update a global setting
  Future<Globals> updateGlobal(String documentId, String value) async {
    try {
      LogService.instance.info('Updating global with document ID: $documentId');

      final now = DateTime.now().toIso8601String();

      final updatedDoc = await _db.updateDocument(
        collectionId,
        documentId,
        {
          'value': value,
          'date_updated': now,
        },
      );

      LogService.instance.info('Updated global document: ${updatedDoc.$id}');
      return Globals.fromDocument(updatedDoc);
    } catch (e) {
      LogService.instance.error('Error updating global: $e');
      rethrow;
    }
  }

  /// List all global settings
  Future<List<Globals>> listGlobals() async {
    try {
      LogService.instance.info('Fetching all globals');

      final docs = await _db.listDocuments(collectionId);

      final globals =
          docs.documents.map((doc) => Globals.fromDocument(doc)).toList();
      LogService.instance.info('Found ${globals.length} globals');

      return globals;
    } catch (e) {
      LogService.instance.error('Error fetching globals: $e');
      rethrow;
    }
  }

  /// Delete a global setting
  Future<void> deleteGlobal(String documentId) async {
    try {
      LogService.instance.info('Deleting global with document ID: $documentId');

      await _db.deleteDocument(
        collectionId,
        documentId,
      );

      LogService.instance.info('Deleted global document: $documentId');
    } catch (e) {
      LogService.instance.error('Error deleting global: $e');
      rethrow;
    }
  }
}
