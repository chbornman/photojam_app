import 'package:flutter/material.dart';

class NavigationControls extends StatelessWidget {
  final int currentIndex;
  final int totalSubmissions;
  final int selectedPhotosCount;
  final bool isSaving;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onSave;

  const NavigationControls({
    super.key,
    required this.currentIndex,
    required this.totalSubmissions,
    required this.selectedPhotosCount,
    required this.isSaving,
    this.onPrevious,
    this.onNext,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: onPrevious,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
          ),
          if (selectedPhotosCount == totalSubmissions)
            ElevatedButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: Icon(isSaving ? Icons.hourglass_empty : Icons.save),
              label: Text(isSaving ? 'Saving...' : 'Save Selections'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            )
          else
            TextButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
            ),
        ],
      ),
    );
  }
}