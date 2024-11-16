import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:appwrite/models.dart';
import 'package:photojam_app/app.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/core/widgets/standard_dialog.dart';
import 'package:photojam_app/core/widgets/standard_button.dart';
import 'package:photojam_app/features/jams/models/photo_submission.dart';
import 'package:photojam_app/features/jams/services/photo_upload_service.dart';
import 'package:photojam_app/features/jams/widgets/photo_selector.dart';
import 'package:photojam_app/features/jams/widgets/jam_dropdown.dart';

class JamSignupPage extends StatefulWidget {
  const JamSignupPage({super.key});

  @override
  State<JamSignupPage> createState() => _JamSignupPageState();
}

class _JamSignupPageState extends State<JamSignupPage> {
  static const int _maxPhotos = 3;

  final List<io.File?> _photos = List.filled(_maxPhotos, null);
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedJamId;
  String? _selectedJamName;
  List<Document> _jams = [];
  bool _isLoading = false;

  late final DatabaseAPI _databaseApi;
  late final PhotoUploadService _photoUploadService;
  late final AuthAPI _authApi;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _initializeServices() {
    _databaseApi = context.read<DatabaseAPI>();
    final storageApi = context.read<StorageAPI>();
    _photoUploadService = PhotoUploadService(storageApi);
    _authApi = context.read<AuthAPI>();
    _fetchJamEvents();
  }

  // Event Handlers
  Future<void> _onJamSelected(String? jamId) async {
    if (jamId == null) return;

    setState(() {
      _selectedJamId = jamId;
    });

    try {
      final jamData = await _databaseApi.getJamById(jamId);
      if (!mounted) return;

      setState(() {
        _selectedJamName = jamData.data['title'] as String? ?? "Unknown Jam";
      });
    } catch (e) {
      LogService.instance.error('Error fetching jam details: $e');
      _showErrorSnackBar('Failed to load jam details');
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedJamId == null) {
      await _showNoJamSelectedDialog();
      return;
    }

    if (_photos.every((photo) => photo == null)) {
      await _handleEmptySubmission();
      return;
    }

    await _processSubmission();
  }

  // Data Fetching
  Future<void> _fetchJamEvents() async {
    if (!mounted) return;

    try {
      final response = await _databaseApi.getJams();
      if (!mounted) return;

      setState(() {
        _jams = response.documents;
      });
    } catch (e) {
      LogService.instance.error('Error fetching jam events: $e');
      _showErrorSnackBar('Failed to load jam events');
    }
  }

  // Photo Management
  Future<void> _selectPhoto(int index) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      final file = io.File(pickedFile.path);

      if (!_photoUploadService.isPhotoSizeValid(file)) {
        await _showFileSizeWarningDialog();
        return;
      }

      setState(() => _photos[index] = file);
    } catch (e) {
      LogService.instance.error('Error selecting photo: $e');
      _showErrorSnackBar('Failed to select photo');
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos[index] = null);
  }

  // Submission Processing
  Future<void> _processSubmission() async {
    if (!_validateSubmission()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _authApi.userId!;
      final existingSubmission = await _databaseApi.getUserSubmissionForJam(
        _selectedJamId!,
        userId,
      );

      if (existingSubmission != null) {
        final shouldOverwrite = await _showOverwriteConfirmationDialog();
        if (!shouldOverwrite) {
          setState(() => _isLoading = false);
          return;
        }
      }

      await _submitPhotos(userId, existingSubmission);

      if (!mounted) return;
      await _showSuccessAndNavigate();
    } catch (e) {
      LogService.instance.error("Error during photo submission: $e");
      if (!mounted) return;
      _showErrorSnackBar('Failed to submit photos');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitPhotos(
      String userId, Document? existingSubmission) async {
    final photoUrls = await _photoUploadService.uploadPhotos(
      photos: _photos,
      jamName: _selectedJamName!,
      username: _authApi.username ?? 'unknown',
      existingSubmission: existingSubmission,
    );

    final submission = PhotoSubmission(
      jamId: _selectedJamId!,
      photoUrls: photoUrls,
      userId: userId,
      comment: _commentController.text,
    );

    if (existingSubmission != null) {
      await _databaseApi.updateSubmission(
        existingSubmission.$id,
        submission.photoUrls,
        submission.submissionDate.toIso8601String(),
        submission.comment ?? '',
      );
    } else {
      await _databaseApi.createSubmission(
        submission.jamId,
        submission.photoUrls,
        submission.userId,
        submission.comment ?? '',
      );
    }
  }

  Future<void> _handleEmptySubmission() async {
    final shouldDelete = await _showDeleteConfirmationDialog();
    if (shouldDelete) {
      await _deleteExistingSubmission();
    }
  }

  Future<void> _deleteExistingSubmission() async {
    if (_selectedJamId == null || !_authApi.isAuthenticated) return;

    try {
      final existingSubmission = await _databaseApi.getUserSubmissionForJam(
        _selectedJamId!,
        _authApi.userId!,
      );

      if (existingSubmission != null) {
        await _photoUploadService.deleteSubmissionPhotos(existingSubmission);
        await _databaseApi.deleteSubmission(existingSubmission.$id);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      LogService.instance.error('Error deleting submission: $e');
      _showErrorSnackBar('Failed to delete submission');
    }
  }

  // Validation
  bool _validateSubmission() {
    if (!_authApi.isAuthenticated || _authApi.userId == null) {
      _showErrorSnackBar('User not authenticated');
      return false;
    }

    if (_selectedJamId == null || _selectedJamName == null) {
      _showErrorSnackBar('Please select a jam event');
      return false;
    }

    return true;
  }

  // UI Feedback
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  // Dialog Methods
  Future<void> _showFileSizeWarningDialog() {
    return _showDialog(
      title: "File Size Warning",
      content:
          "Selected photo exceeds the 50MB size limit. Please choose a smaller photo.",
    );
  }

  Future<void> _showNoJamSelectedDialog() {
    return _showDialog(
      title: "Select a Jam",
      content: "Please select a Jam event before submitting photos.",
    );
  }

  Future<void> _showDialog({
    required String title,
    required String content,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => StandardDialog(
        title: "No Photos Selected",
        content: const Text("You have not selected any photos. "
            "Submitting will delete your existing submission and its photos. "
            "Do you want to proceed?"),
        submitButtonLabel: "Delete Submission",
        submitButtonOnPressed: () => Navigator.pop(context, true),
      ),
    ).then((value) => value ?? false);
  }

  Future<bool> _showOverwriteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => StandardDialog(
        title: "Existing Submission",
        content: const Text("You have already submitted photos for this Jam. "
            "Submitting again will overwrite your previous submission. "
            "Do you want to proceed?"),
        submitButtonLabel: "Overwrite",
        submitButtonOnPressed: () => Navigator.pop(context, true),
      ),
    ).then((value) => value ?? false);
  }

  Future<void> _showSuccessAndNavigate() async {
    await showDialog(
      context: context,
      builder: (context) => StandardDialog(
        title: "Submission Successful",
        content: const Text("Your photos have been submitted successfully."),
        submitButtonLabel: "OK",
        submitButtonOnPressed: () async {
          Navigator.pop(context);
          if (!mounted) return;

          final userRole = await _authApi.roleService.getCurrentUserRole();
          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => App(userRole: userRole),
            ),
            (route) => false,
          );
        },
        showCancelButton: false,
      ),
    );
  }

  // UI Components
  Widget _buildCommentField() {
    return TextField(
      controller: _commentController,
      decoration: InputDecoration(
        labelText: 'Note to facilitator (optional)',
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      maxLines: 3,
    );
  }

  Widget _buildSubmitButton() {
    final bool isDisabled = _selectedJamId == null ||
        _jams.isEmpty ||
        _photos.every((photo) => photo == null);

    return StandardButton(
      label: const Text("Submit Photos"),
      onPressed: isDisabled ? null : _handleSubmit,
    );
  }

  // Build Method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Jam Signup"),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                JamDropdown(
                  jams: _jams,
                  selectedJamId: _selectedJamId,
                  onChanged: _onJamSelected,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _maxPhotos,
                    (index) => PhotoSelector(
                      photo: _photos[index],
                      onSelect: () => _selectPhoto(index),
                      onRemove: () => _removePhoto(index),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildCommentField(),
                const SizedBox(height: 20),
                _buildSubmitButton(),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
