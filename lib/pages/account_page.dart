import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/pages/utilities/standard_card.dart';
import 'package:photojam_app/pages/utilities/standard_dialog.dart';
import 'package:photojam_app/pages/utilities/userdataprovider.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String? userRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchUserRole());
  }

  void showUpdateNameDialog() {
    final userData = context.read<UserDataProvider>();
    final nameController = TextEditingController(text: userData.username);

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
          await context.read<AuthAPI>().updateName(nameController.text);
          if (!mounted) return;
          Navigator.of(context).pop();
          setState(() {
            userData.username = nameController.text;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Name updated successfully!")),
          );
        },
      ),
    );
  }

  void showUpdateEmailDialog() {
    final userData = context.read<UserDataProvider>();
    final emailController = TextEditingController(text: userData.email);
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
          await context.read<AuthAPI>().updateEmail(emailController.text, passwordController.text);
          if (!mounted) return;
          Navigator.of(context).pop();
          setState(() {
            userData.email = emailController.text;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Email updated successfully!")),
          );
        },
      ),
    );
  }

  void showUpdatePasswordDialog() {
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Passwords do not match!")),
            );
            return;
          }

          await context.read<AuthAPI>().updatePassword(
              currentPasswordController.text, newPasswordController.text);

          if (!mounted) return;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Password updated successfully!")),
          );
        },
      ),
    );
  }

  void _fetchUserRole() async {
    final authAPI = Provider.of<AuthAPI>(context, listen: false);
    try {
      final role = await authAPI.getUserRole();
      if (mounted) {
        setState(() {
          userRole = role;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userRole = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<UserDataProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),  // Consistent padding around the page
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${userData.username}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '${userData.email}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 20),
            StandardCard(
              icon: Icons.person,
              title: "Change Name",
              subtitle: "Update your display name",
              onTap: showUpdateNameDialog,
            ),
            const SizedBox(height: 10), // Consistent spacing between cards
            userData.isOAuthUser
                ? Text(
                    "Email updates are managed through your OAuth provider.",
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                  )
                : StandardCard(
                    icon: Icons.email,
                    title: "Change Email",
                    subtitle: "Update your email address",
                    onTap: showUpdateEmailDialog,
                  ),
            const SizedBox(height: 10),
            StandardCard(
              icon: Icons.lock,
              title: "Change Password",
              subtitle: "Update your account password",
              onTap: showUpdatePasswordDialog,
            ),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
    );
  }
}