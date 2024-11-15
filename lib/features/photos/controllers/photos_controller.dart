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
        _cacheService = cacheService;

  bool get isLoading => _isLoading;
  List<Submission> get submissions => _submissions;
  String? get error => _error;
  bool get hasSubmissions => _submissions.isNotEmpty;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  Future<void> fetchSubmissions() async {
    if (_disposed) return;
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _authAPI.userid;
      final authToken = await _authAPI.getToken();

      if (_disposed) return;

      if (userId == null || userId.isEmpty || authToken == null) {
        throw Exception("User ID or auth token is not available.");
      }

      final response = await _databaseAPI.getSubmissionsByUser(userId: userId);
      if (_disposed) return;

      List<Submission> submissions = [];

      for (var doc in response) {
        if (_disposed) return;

        final photoUrls = List<String>.from(doc.data['photos'] ?? []).take(3).toList();
        List<Uint8List?> photos = [];

        for (var photoUrl in photoUrls) {
          if (_disposed) return;
          
          final imageData = await _cacheService.getImage(
            photoUrl,
            authToken,
            () => _storageAPI.fetchAuthenticatedImage(photoUrl, authToken),
          );
          photos.add(imageData);
        }

        submissions.add(
          Submission(
            date: doc.data['date'] ?? 'Unknown Date',
            jamTitle: doc.data['jam']?['title'] ?? 'Untitled',
            photos: photos,
          ),
        );
      }

      if (_disposed) return;

      submissions.sort((a, b) => b.date.compareTo(a.date));
      
      _submissions = submissions;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (_disposed) return;
      
      LogService.instance.error('Error fetching submissions: $e');
      _error = 'Failed to load photos';
      _isLoading = false;
      notifyListeners();
    }
  }
}