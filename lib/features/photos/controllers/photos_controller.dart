import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/core/services/photo_cache_service.dart';
import 'package:photojam_app/features/photos/widgets/submission.dart';

class PhotosController extends ChangeNotifier {
  final AuthAPI _authAPI;
  final DatabaseAPI _databaseAPI;
  final StorageAPI _storageAPI;
  final PhotoCacheService _cacheService;

  List<Submission> _submissions = [];
  bool _isLoading = true;
  String? _error;
  bool _disposed = false;

  PhotosController({
    required AuthAPI authAPI,
    required DatabaseAPI databaseAPI,
    required StorageAPI storageAPI,
    required PhotoCacheService cacheService,
  })  : _authAPI = authAPI,
        _databaseAPI = databaseAPI,
        _storageAPI = storageAPI,
        _cacheService = cacheService {
    fetchSubmissions();
  }

  bool get isLoading => _isLoading;
  List<Submission> get submissions => _submissions;
  String? get error => _error;
  bool get hasSubmissions => _submissions.isNotEmpty;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _setLoading(bool loading) {
    if (_disposed) return;
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    if (_disposed) return;
    _error = error;
    notifyListeners();
  }

  Future<void> fetchSubmissions() async {
    if (_disposed) return;
    
    try {
      _setLoading(true);
      _setError(null);

      if (!_authAPI.isAuthenticated) {
        throw Exception("User is not authenticated");
      }

      final userId = _authAPI.userId;
      if (userId == null) {
        throw Exception("User ID not available");
      }

      final sessionId = await _authAPI.getSessionId();
      if (sessionId == null) {
        throw Exception("No valid session found");
      }

      if (_disposed) return;

      final response = await _databaseAPI.getSubmissionsByUser(userId: userId);
      if (_disposed) return;

      final submissions = await _processSubmissions(response, sessionId);
      if (_disposed) return;

      _submissions = submissions;
      _setLoading(false);
    } catch (e) {
      LogService.instance.error('Error fetching submissions: $e');
      _setError('Failed to load photos');
      _setLoading(false);
    }
  }

  Future<List<Submission>> _processSubmissions(
    dynamic response,
    String sessionId,
  ) async {
    List<Submission> submissions = [];

    for (var doc in response) {
      if (_disposed) break;

      try {
        final submission = await _processSubmission(doc, sessionId);
        if (submission != null) {
          submissions.add(submission);
        }
      } catch (e) {
        LogService.instance.error('Error processing submission: $e');
      }
    }

    submissions.sort((a, b) => b.date.compareTo(a.date));
    return submissions;
  }

  Future<Submission?> _processSubmission(
    dynamic doc,
    String sessionId,
  ) async {
    final photoUrls = List<String>.from(doc.data['photos'] ?? [])
        .take(3)
        .toList();
    
    List<Uint8List?> photos = [];
    for (var photoUrl in photoUrls) {
      if (_disposed) return null;
      
      final imageData = await _cacheService.getImage(
        photoUrl,
        sessionId,
        () => _storageAPI.fetchAuthenticatedImage(photoUrl, sessionId),
      );
      photos.add(imageData);
    }

    return Submission(
      date: doc.data['date'] ?? 'Unknown Date',
      jamTitle: doc.data['jam']?['title'] ?? 'Untitled',
      photos: photos,
    );
  }
}