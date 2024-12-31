// lib/features/admin/content_management/widgets/submission/create_submission_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/core/widgets/standard_card.dart';
import 'package:photojam_app/features/jams/jamsignup_page.dart';

class CreateSubmissionCard extends ConsumerWidget {
  final void Function(bool) onLoading;
  final void Function(String, {bool isError}) onMessage;

  const CreateSubmissionCard({
    super.key,
    required this.onLoading,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StandardCard(
      icon: Icons.add,
      title: "Create Submission",
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const JamSignupPage()),
      ),
    );
  }
}