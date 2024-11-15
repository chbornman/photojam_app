
// lib/features/journeys/providers/journey_provider.dart
import 'package:flutter/foundation.dart';
import 'package:photojam_app/features/journeys/models/journey_repository.dart';
import 'package:photojam_app/features/journeys/models/journeys.dart';

class JourneyProvider extends ChangeNotifier {
  final JourneyRepository _repository;
  List<Journey>? _journeys;
  bool _loading = false;
  String? _error;

  JourneyProvider(this._repository);

  List<Journey>? get journeys => _journeys;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> loadUserJourneys(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _journeys = await _repository.getUserJourneys(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllJourneys() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _journeys = await _repository.getAllJourneys();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
