import 'package:flutter/material.dart';
import 'package:photojam_app/core/widgets/standard_dialog.dart';

class UpdateDialogs {
  static void showUpdateNameDialog({
    required BuildContext context,
    required String currentName,
    required Future<void> Function(String) onUpdate,
  }) {
    final controller = TextEditingController(text: currentName);
    
    showDialog(
      context: context,
      builder: (context) => StandardDialog(
        title: 'Change Name',
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Name'),
        ),
        submitButtonLabel: "Save",
        submitButtonOnPressed: () async {
          try {
            await onUpdate(controller.text);
            if (!context.mounted) return;
            Navigator.of(context).pop();
            _showSuccessSnackBar(context, "Name updated successfully!");
          } catch (e) {
            if (!context.mounted) return;
            _showErrorSnackBar(context, "Failed to update name");
          }
        },
      ),
    );
  }

  static void showUpdateEmailDialog({
    required BuildContext context,
    required String currentEmail,
    required Future<void> Function({
      required String newEmail,
      required String password,
    }) onUpdate,
  }) {
    final emailController = TextEditingController(text: currentEmail);
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StandardDialog(
        title: 'Update Email',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'New Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
          ],
        ),
        submitButtonLabel: "Save",
        submitButtonOnPressed: () async {
          try {
            await onUpdate(
              newEmail: emailController.text,
              password: passwordController.text,
            );
            if (!context.mounted) return;
            Navigator.of(context).pop();
            _showSuccessSnackBar(context, "Email updated successfully!");
          } catch (e) {
            if (!context.mounted) return;
            _showErrorSnackBar(context, "Failed to update email");
          }
        },
      ),
    );
  }

  static void showUpdatePasswordDialog({
    required BuildContext context,
    required Future<void> Function({
      required String oldPassword,
      required String newPassword,
    }) onUpdate,
  }) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StandardDialog(
        title: 'Update Password',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Confirm New Password'),
              obscureText: true,
            ),
          ],
        ),
        submitButtonLabel: "Save",
        submitButtonOnPressed: () async {
          if (newPasswordController.text != confirmPasswordController.text) {
            _showErrorSnackBar(context, "Passwords do not match!");
            return;
          }

          try {
            await onUpdate(
              oldPassword: currentPasswordController.text,
              newPassword: newPasswordController.text,
            );
            if (!context.mounted) return;
            Navigator.of(context).pop();
            _showSuccessSnackBar(context, "Password updated successfully!");
          } catch (e) {
            if (!context.mounted) return;
            _showErrorSnackBar(context, "Failed to update password");
          }
        },
      ),
    );
  }

  static void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Add dispose methods to clean up controllers
  static void dispose(List<TextEditingController> controllers) {
    for (var controller in controllers) {
      controller.dispose();
    }
  }
}