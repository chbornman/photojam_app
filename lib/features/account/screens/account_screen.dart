import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/core/widgets/standard_card.dart';
import 'package:photojam_app/core/widgets/standard_dialog.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late Future<Map<String, dynamic>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserData();
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    final authAPI = Provider.of<AuthAPI>(context, listen: false);
    final roleService = authAPI.roleService;
    try {
      // Use the new getters from AuthAPI
      return {
        'username': authAPI.username ?? 'Unknown User',
        'email': authAPI.email ?? 'No email available',
        'role': await roleService.getCurrentUserRole(),
        'isOAuthUser': authAPI.isOAuthUser
      };
    } catch (e) {
      LogService.instance.error("Error loading user data: $e");
      rethrow;
    }
  }

  void _reloadUserData() {
    setState(() {
      _userDataFuture = _loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Rest of the build method remains the same
    return FutureBuilder<Map<String, dynamic>>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error loading user data: ${snapshot.error}'),
            ),
          );
        }

        final userData = snapshot.data!;
        return Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserInfo(context, userData),
                  const SizedBox(height: 20),
                  _buildAccountManagementCards(userData),
                  const SizedBox(height: 10),
                  _buildRoleBasedCards(context, userData),
                ],
              ),
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
        );
      },
    );
  }

  Widget _buildUserInfo(BuildContext context, Map<String, dynamic> userData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, ${userData['username']}!',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          userData['email'] ?? 'No email available',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildAccountManagementCards(Map<String, dynamic> userData) {
    return Column(
      children: [
        StandardCard(
          icon: Icons.person,
          title: "Change Name",
          onTap: () => _showUpdateNameDialog(userData),
        ),
        const SizedBox(height: 10),
        StandardCard(
          icon: Icons.email,
          title: "Change Email",
          onTap: () => _showUpdateEmailDialog(userData),
        ),
        const SizedBox(height: 10),
        if (!userData['isOAuthUser'])
          StandardCard(
            icon: Icons.lock,
            title: "Change Password",
            onTap: () => _showUpdatePasswordDialog(),
          ),
      ],
    );
  }

  Widget _buildRoleBasedCards(
      BuildContext context, Map<String, dynamic> userData) {
    return Column(
      children: [
        if (userData['role'] == 'nonmember')
          StandardCard(
            icon: Icons.person_add,
            title: "Become a Member",
            subtitle: "Join our community and enjoy exclusive benefits",
            onTap: () async {
              try {
                // await roleService.requestMemberRole(); TODO
                _reloadUserData(); // Use reload instead of direct load
                if (!mounted) return;
                _showSuccessSnackBar("Successfully became a member!");
              } catch (e) {
                LogService.instance.error("Error requesting member role: $e");
                if (!mounted) return;
                _showErrorSnackBar("Failed to become a member");
              }
            },
          )
        else if (userData['role'] == 'member')
          StandardCard(
            icon: Icons.person_add,
            title: "Become a Facilitator",
            subtitle: "Lead Jams and share your photography passion",
            onTap: () async {
              try {
                // await roleService.requestFacilitatorRole(); TODO
                if (!mounted) return;
                _showSuccessSnackBar("Facilitator request submitted!");
              } catch (e) {
                LogService.instance
                    .error("Error requesting facilitator role: $e");
                if (!mounted) return;
                _showErrorSnackBar("Failed to submit facilitator request");
              }
            },
          ),
        if (userData['role'] != 'nonmember') ...[
          StandardCard(
            icon: Icons.chat,
            title: "Go to the Signal Chat",
            onTap: () => _goToExternalLink(signalGroupUrl),
          ),
        ],
      ],
    );
  }

  void _showUpdateNameDialog(Map<String, dynamic> userData) {
    final nameController = TextEditingController(text: userData['username']);

    showDialog(
      context: context,
      builder: (context) => StandardDialog(
        title: 'Change Name',
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'New Name'),
        ),
        submitButtonLabel: "Save",
        submitButtonOnPressed: () async {
          try {
            await context.read<AuthAPI>().updateName(nameController.text);
            _reloadUserData(); // Use reload instead of direct load
            if (!mounted) return;
            Navigator.of(context).pop();
            _showSuccessSnackBar("Name updated successfully!");
          } catch (e) {
            LogService.instance.error("Error updating name: $e");
            if (!mounted) return;
            _showErrorSnackBar("Failed to update name");
          }
        },
      ),
    );
  }

  void _showUpdateEmailDialog(Map<String, dynamic> userData) {
    final emailController = TextEditingController(text: userData['email']);
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
            await context.read<AuthAPI>().updateEmail(
                  newEmail: emailController.text,
                  password: passwordController.text,
                );
            _reloadUserData(); // Use reload instead of direct load
            if (!mounted) return;
            Navigator.of(context).pop();
            _showSuccessSnackBar("Email updated successfully!");
          } catch (e) {
            LogService.instance.error("Error updating email: $e");
            if (!mounted) return;
            _showErrorSnackBar("Failed to update email");
          }
        },
      ),
    );
  }

  void _showUpdatePasswordDialog() {
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
              decoration:
                  const InputDecoration(labelText: 'Confirm New Password'),
              obscureText: true,
            ),
          ],
        ),
        submitButtonLabel: "Save",
        submitButtonOnPressed: () async {
          if (newPasswordController.text != confirmPasswordController.text) {
            _showErrorSnackBar("Passwords do not match!");
            return;
          }

          try {
            await context.read<AuthAPI>().updatePassword(
                  oldPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                );
            if (!mounted) return;
            Navigator.of(context).pop();
            _showSuccessSnackBar("Password updated successfully!");
          } catch (e) {
            LogService.instance.error("Error updating password: $e");
            if (!mounted) return;
            _showErrorSnackBar("Failed to update password");
          }
        },
      ),
    );
  }

  Future<void> _goToExternalLink(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        LogService.instance.error("Could not launch URL: $url");
        if (!mounted) return;
        _showErrorSnackBar("Could not open the link");
      }
    } catch (e) {
      LogService.instance.error("Error launching URL: $e");
      if (!mounted) return;
      _showErrorSnackBar("Error opening the link");
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
