import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_state_provider.dart';
import 'package:photojam_app/appwrite/database/models/jam_model.dart';
import 'package:photojam_app/appwrite/database/models/submission_model.dart';
import 'package:photojam_app/appwrite/database/providers/jam_provider.dart';
import 'package:photojam_app/appwrite/database/providers/submission_provider.dart';
import 'package:photojam_app/appwrite/storage/models/storage_types.dart';
import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/core/widgets/standard_dialog.dart';
import 'package:photojam_app/core/widgets/standard_button.dart';
import 'package:photojam_app/features/jams/photo_upload_service.dart';
import 'package:photojam_app/features/jams/photo_selector.dart';

class JamSignupPage extends ConsumerStatefulWidget {
  const JamSignupPage({super.key});

  @override
  ConsumerState<JamSignupPage> createState() => _JamSignupPageState();
}

class _JamSignupPageState extends ConsumerState<JamSignupPage> {
  static const int _maxPhotos = 3;

  final List<io.File?> _photos = List.filled(_maxPhotos, null);
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedJamId;
  List<Jam> _jams = [];
  bool _isLoading = false;

  late final PhotoUploadService _photoUploadService;
  late final authState = ref.read(authStateProvider);

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
    final storageRepository = ref.read(storageRepositoryProvider);
    _photoUploadService = PhotoUploadService(storageRepository);
    _fetchJams();
  }

  Future<void> _fetchJams() async {
    try {
      final jamRepository = ref.read(jamRepositoryProvider);
      final jams = await jamRepository.getAllJams(activeOnly: true);

      if (!mounted) return;
      setState(() => _jams = jams);
    } catch (e) {
      LogService.instance.error('Error fetching jams: $e');
      _showErrorSnackBar('Failed to load jams');
    }
  }

  Future<void> _selectPhoto(int index) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      final file = io.File(pickedFile.path);
      final storageRepository = ref.read(storageRepositoryProvider);

      if (file.lengthSync() >
          storageRepository.getMaxFileSizeForBucket(StorageBucket.photos)) {
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

  Future<void> _processSubmission() async {
    if (!_validateSubmission()) return;

    setState(() => _isLoading = true);

    try {
      final userId = authState.user?.id;
      if (userId == null) throw Exception('User not authenticated');

      final submissionRepository = ref.read(submissionRepositoryProvider);
      final existingSubmission =
          await submissionRepository.getUserSubmissionForJam(
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
      LogService.instance.error("Error during submission: $e");
      if (!mounted) return;
      _showErrorSnackBar('Failed to submit photos');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitPhotos(
      String userId, Submission? existingSubmission) async {
    final selectedJam = _jams.firstWhere((jam) => jam.id == _selectedJamId);

    final photoUrls = await _photoUploadService.uploadPhotos(
      photos: _photos,
      jamName: selectedJam.title,
      username: authState.user?.name ?? 'unknown',
      existingSubmission: existingSubmission, // Pass Submission directly
    );

    final submissionRepository = ref.read(submissionRepositoryProvider);
    final jamRepository = ref.read(jamRepositoryProvider);

    if (existingSubmission != null) {
      await submissionRepository.updateSubmission(
        submissionId: existingSubmission.id,
        photos: photoUrls,
        comment: _commentController.text,
      );
    } else {
      final newSubmission = await submissionRepository.createSubmission(
        userId: authState.user!.id,
        jamId: selectedJam.id,
        photos: photoUrls,
        comment: _commentController.text,
      );

      await jamRepository.addSubmissionToJam(selectedJam.id, newSubmission.id);
    }
  }

  Future<void> _handleEmptySubmission() async {
    final shouldDelete = await _showDeleteConfirmationDialog();
    if (shouldDelete) {
      await _deleteExistingSubmission();
    }
  }

  Future<void> _deleteExistingSubmission() async {
    if (_selectedJamId == null) return;

    try {
      final userId = authState.user?.id;
      if (userId == null) throw Exception('User not authenticated');

      final submissionRepository = ref.read(submissionRepositoryProvider);
      final existingSubmission =
          await submissionRepository.getUserSubmissionForJam(
        _selectedJamId!,
        userId,
      );

      if (existingSubmission != null) {
        // Pass Submission directly, no need for toDocument()
        await _photoUploadService.deleteSubmissionPhotos(existingSubmission);
        await submissionRepository.deleteSubmission(existingSubmission.id);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      LogService.instance.error('Error deleting submission: $e');
      _showErrorSnackBar('Failed to delete submission');
    }
  }

  bool _validateSubmission() {
    if (!authState.isAuthenticated || authState.user?.id == null) {
      _showErrorSnackBar('User not authenticated');
      return false;
    }

    if (_selectedJamId == null) {
      _showErrorSnackBar('Please select a jam event');
      return false;
    }

    return true;
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
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

  Future<void> _showFileSizeWarningDialog() {
    return _showDialog(
      title: "File Size Warning",
      content:
          "Selected photo exceeds the maximum size limit. Please choose a smaller photo.",
    );
  }

  Future<void> _showNoJamSelectedDialog() {
    return _showDialog(
      title: "Select a Jam",
      content: "Please select a Jam event before submitting photos.",
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
        submitButtonOnPressed: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
        showCancelButton: false,
      ),
    );
  }

  Widget _buildJamDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedJamId,
      hint: const Text('Select a Jam'),
      items: _jams.map((jam) {
        return DropdownMenuItem(
          value: jam.id,
          child: Text(jam.title),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedJamId = value),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
    );
  }

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
                _buildJamDropdown(),
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
