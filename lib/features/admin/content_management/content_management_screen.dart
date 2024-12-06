// lib/features/content_management/presentation/screens/content_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/features/admin/content_management/widgets/danger/danger_section.dart';
import 'package:photojam_app/features/admin/content_management/widgets/jam/jam_section.dart';
import 'package:photojam_app/features/admin/content_management/widgets/journey/journey_section.dart';
import 'package:photojam_app/features/admin/content_management/widgets/lesson/lesson_section.dart';

class ContentManagementScreen extends ConsumerStatefulWidget {
  const ContentManagementScreen({super.key});

  @override
  ConsumerState<ContentManagementScreen> createState() => _ContentManagementScreenState();
}

class _ContentManagementScreenState extends ConsumerState<ContentManagementScreen> {
  bool _isLoading = false;

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() => _isLoading = loading);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Content Management"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  JamSection(
                    onLoading: _setLoading,
                    onMessage: _showMessage,
                  ),
                  JourneySection(
                    onLoading: _setLoading,
                    onMessage: _showMessage,
                  ),
                  LessonSection(
                    onLoading: _setLoading,
                    onMessage: _showMessage,
                  ),
                  DangerSection(
                    onLoading: _setLoading,
                    onMessage: _showMessage,
                  ),
                ],
              ),
            ),
    );
  }
}