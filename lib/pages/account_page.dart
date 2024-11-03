import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:photojam_app/standard_button.dart';
import 'package:photojam_app/standard_dialog.dart';
import 'package:photojam_app/userdataprovider.dart';
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

// Method to show dialog for updating name
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
          if (!mounted) return; // Ensure widget is still mounted
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

  // Method to show dialog for updating email
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
          await context
              .read<AuthAPI>()
              .updateEmail(emailController.text, passwordController.text);
          if (!mounted) return; // Ensure widget is still mounted
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

  // Method to show dialog for updating password
  void showUpdatePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
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
          ],
        ),
        submitButtonLabel: "Save",
        submitButtonOnPressed: () async {
          await context.read<AuthAPI>().updatePassword(
              currentPasswordController.text, newPasswordController.text);
          if (!mounted) return; // Ensure widget is still mounted
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Password updated successfully!")));
        },
      ),
    );
  }

  signOut() {
    context.read<AuthAPI>().signOut();
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
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: PHOTOJAM_YELLOW,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: signOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Welcome back, ${userData.username}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '${userData.email}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            StandardButton(
                label: Text("Change Name"), onPressed: showUpdateNameDialog),
            userData.isOAuthUser
                ? const Text(
                    "Email updates are managed through your OAuth provider.",
                    style: TextStyle(color: Colors.grey),
                  )
                : StandardButton(
                    label: Text("Change Email"),
                    onPressed: showUpdateEmailDialog),
            StandardButton(
                label: Text("Change Password"),
                onPressed: showUpdatePasswordDialog),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}
