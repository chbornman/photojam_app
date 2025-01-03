import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/core/utils/snackbar_util.dart';
import 'package:photojam_app/core/widgets/standard_button.dart';
import 'package:photojam_app/core/widgets/standard_dialog.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/features/account/account_provider.dart';

class AccountActions extends ConsumerWidget {
  final bool isMember;
  final bool isFacilitator;

  const AccountActions({
    super.key,
    required this.isMember,
    required this.isFacilitator,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildActionButton(
          context,
          'Update Name',
          Icons.person,
          () => _showUpdateNameDialog(context, ref),
        ),
        _buildActionButton(
          context,
          'Update Email',
          Icons.email,
          () => _showUpdateEmailDialog(context, ref),
        ),
        _buildActionButton(
          context,
          'Update Password',
          Icons.lock,
          () => _showUpdatePasswordDialog(context, ref),
        ),
        if (!isMember) ...[
          _buildActionButton(
            context,
            'Become a Member',
            Icons.person_add,
            () => _handleRoleRequest(context, ref, 'member'),
          ),
        ] else if (!isFacilitator) ...[
          _buildActionButton(
            context,
            'Become a Facilitator',
            Icons.school,
            () => _handleRoleRequest(context, ref, 'facilitator'),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return StandardButton(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  void _showUpdateNameDialog(BuildContext context, WidgetRef ref) {
    // Create the controller
    final controller = TextEditingController(
      text: ref.read(accountProvider).name,
    );

    showDialog(
      context: context,
      builder: (context) => StandardDialog(
        title: 'Update Name',
        content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'New Name'),
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) async {
              // Handle the update
              await _handleNameUpdate(context, ref, controller.text);
            // Dispose controller after handling the update
            controller.dispose();
            },
        ),
        submitButtonLabel: 'Save',
        submitButtonOnPressed: () async {
          // Handle the update
          await _handleNameUpdate(context, ref, controller.text);
          // Dispose controller after handling the update
          controller.dispose();
        },
      ),
    );
  }

  void _showUpdateEmailDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController(
      text: ref.read(accountProvider).email,
    );
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
              textInputAction: TextInputAction.next,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleEmailUpdate(
                context,
                ref,
                emailController.text,
                passwordController.text,
              ),
            ),
          ],
        ),
        submitButtonLabel: 'Save',
        submitButtonOnPressed: () => _handleEmailUpdate(
          context,
          ref,
          emailController.text,
          passwordController.text,
        ),
      ),
    ).then((_) {
      emailController.dispose();
      passwordController.dispose();
    });
  }

  void _showUpdatePasswordDialog(BuildContext context, WidgetRef ref) {
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
              textInputAction: TextInputAction.next,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration:
                  const InputDecoration(labelText: 'Confirm New Password'),
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handlePasswordUpdate(
                context,
                ref,
                currentPasswordController.text,
                newPasswordController.text,
                confirmPasswordController.text,
              ),
            ),
          ],
        ),
        submitButtonLabel: 'Save',
        submitButtonOnPressed: () => _handlePasswordUpdate(
          context,
          ref,
          currentPasswordController.text,
          newPasswordController.text,
          confirmPasswordController.text,
        ),
      ),
    ).then((_) {
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    });
  }

  Future<void> _handleNameUpdate(
    BuildContext context,
    WidgetRef ref,
    String newName,
  ) async {
    if (newName.trim().isEmpty) {
      SnackbarUtil.showErrorSnackBar(context, 'Name cannot be empty');
      return;
    }

    try {
      await ref.read(accountProvider.notifier).updateName(newName.trim());
      if (context.mounted) {
        Navigator.of(context).pop();
        SnackbarUtil.showSuccessSnackBar(context, 'Name updated successfully');
      }
    } catch (e) {
      LogService.instance.error('Failed to update name: $e');
      if (context.mounted) {
        SnackbarUtil.showErrorSnackBar(context, 'Failed to update name');
      }
    }
  }

  Future<void> _handleEmailUpdate(
    BuildContext context,
    WidgetRef ref,
    String newEmail,
    String password,
  ) async {
    if (newEmail.trim().isEmpty || password.isEmpty) {
      SnackbarUtil.showErrorSnackBar(context, 'Please fill in all fields');
      return;
    }

    try {
      await ref.read(accountProvider.notifier).updateEmail(
            newEmail.trim(),
            password,
          );
      if (context.mounted) {
        Navigator.of(context).pop();
        SnackbarUtil.showSuccessSnackBar(context, 'Email updated successfully');
      }
    } catch (e) {
      LogService.instance.error('Failed to update email: $e');
      if (context.mounted) {
        SnackbarUtil.showErrorSnackBar(context, 'Failed to update email');
      }
    }
  }

  Future<void> _handlePasswordUpdate(
    BuildContext context,
    WidgetRef ref,
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      SnackbarUtil.showErrorSnackBar(context, 'Please fill in all fields');
      return;
    }

    if (newPassword != confirmPassword) {
      SnackbarUtil.showErrorSnackBar(context, 'New passwords do not match');
      return;
    }

    try {
      await ref.read(accountProvider.notifier).updatePassword(
            currentPassword,
            newPassword,
          );
      if (context.mounted) {
        Navigator.of(context).pop();
        SnackbarUtil.showSuccessSnackBar(context, 'Password updated successfully');
      }
    } catch (e) {
      LogService.instance.error('Failed to update password: $e');
      if (context.mounted) {
        SnackbarUtil.showErrorSnackBar(context, 'Failed to update password');
      }
    }
  }

  Future<void> _handleRoleRequest(
    BuildContext context,
    WidgetRef ref,
    String role,
  ) async {
    try {
      await ref.read(accountProvider.notifier).requestRole(role);
      if (context.mounted) {
        SnackbarUtil.showSuccessSnackBar(
          context,
          'Successfully requested ${role.toLowerCase()} role',
        );
      }
    } catch (e) {
      LogService.instance.error('Failed to request $role role: $e');
      if (context.mounted) {
        SnackbarUtil.showErrorSnackBar(context, 'Failed to request role');
      }
    }
  }

}
