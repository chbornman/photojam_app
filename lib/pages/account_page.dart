import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String? email;
  String? username;
  bool isOAuthUser = false;

  TextEditingController bioTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final AuthAPI appwrite = context.read<AuthAPI>();

    // Set class-level variables for email and username
    email = appwrite.email ?? 'no email';
    username = appwrite.username ?? 'no username';

    // Check if user is connected via OAuth
    isOAuthUser = false; //TODO appwrite.isOAuthUser();

    // Fetch and update user preferences (e.g., bio)
    appwrite.getUserPreferences().then((value) {
      if (value.data.isNotEmpty) {
        setState(() {
          bioTextController.text = value.data['bio'];
        });
      }
    });
  }

  // Method to show dialog for updating name
  void showUpdateNameDialog() {
    final nameController = TextEditingController(text: username);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'New Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<AuthAPI>().updateName(nameController.text);
              Navigator.of(context).pop();
              setState(() {
                username = nameController.text;
              });
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  // Method to show dialog for updating email
  void showUpdateEmailDialog() {
    final emailController = TextEditingController(text: email);
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Email'),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context
                  .read<AuthAPI>()
                  .updateEmail(emailController.text, passwordController.text);
              Navigator.of(context).pop();
              setState(() {
                email = emailController.text;
              });
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  // Method to show dialog for updating password
  void showUpdatePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Password'),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<AuthAPI>().updatePassword(
                  currentPasswordController.text, newPasswordController.text);
              Navigator.of(context).pop();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  // Method to show dialog for updating bio
  void showUpdateBioDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Bio'),
        content: TextField(
          controller: bioTextController,
          decoration: const InputDecoration(labelText: 'Bio'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<AuthAPI>()
                  .updatePreferences(bio: bioTextController.text);
              Navigator.of(context).pop();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  signOut() {
    context.read<AuthAPI>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: accentColor,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome back, $username!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '$email',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Change Name Button
            ElevatedButton(
              onPressed: showUpdateNameDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                minimumSize: Size(double.infinity, defaultButtonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(defaultCornerRadius),
                ),
              ),
              child: const Text("Change Name"),
            ),
            const SizedBox(height: 20),

            // Change Email Button (Only if not OAuth)
            if (!isOAuthUser)
              ElevatedButton(
                onPressed: showUpdateEmailDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  minimumSize: Size(double.infinity, defaultButtonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(defaultCornerRadius),
                  ),
                ),
                child: const Text("Change Email"),
              ),
            if (isOAuthUser)
              const Text(
                "Email updates are managed through your OAuth provider.",
                style: TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 20),

            // Change Password Button
            ElevatedButton(
              onPressed: showUpdatePasswordDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                minimumSize: Size(double.infinity, defaultButtonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(defaultCornerRadius),
                ),
              ),
              child: const Text("Change Password"),
            ),
            const SizedBox(height: 20),

            // Change Bio Button
            ElevatedButton(
              onPressed: showUpdateBioDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                minimumSize: Size(double.infinity, defaultButtonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(defaultCornerRadius),
                ),
              ),
              child: const Text("Change Bio"),
            ),
          ],
        ),
      ),
      backgroundColor: secondaryAccentColor,
    );
  }
}