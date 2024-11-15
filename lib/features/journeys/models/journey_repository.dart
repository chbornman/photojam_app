
// lib/features/journeys/repositories/journey_repository.dart
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/features/journeys/models/journeys.dart';

class JourneyRepository {
  final DatabaseAPI _databaseApi;

  JourneyRepository(this._databaseApi);

  Future<List<Journey>> getUserJourneys(String userId) async {
    final response = await _databaseApi.getJourneysByUser(userId);
    return response.documents
        .map((doc) => Journey.fromMap(doc.data))
        .toList();
  }

  Future<List<Journey>> getAllJourneys() async {
    final response = await _databaseApi.getAllActiveJourneys();
    return response.documents
        .map((doc) => Journey.fromMap(doc.data))
        .toList();
  }
}
