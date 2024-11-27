import 'package:appwrite/models.dart';

abstract class DatabaseRepository {
  Future<Document> createDocument(
    String collectionId, 
    Map<String, dynamic> data, );
  
  Future<Document> getDocument(String collectionId, String documentId);
  
  Future<DocumentList> listDocuments(
    String collectionId, {
    List<String>? queries,
    List<String>? orderField,
  });
  
  Future<Document> updateDocument(
    String collectionId,
    String documentId,
    Map<String, dynamic> data,);
  
  Future<void> deleteDocument(String collectionId, String documentId);
}