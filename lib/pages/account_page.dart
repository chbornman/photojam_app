import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late String? email;
  late String? username;
  TextEditingController bioTextController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final AuthAPI appwrite = context.read<AuthAPI>();
    email = appwrite.email;
    username = appwrite.username;
    nameController.text = username ?? '';
    appwrite.getUserPreferences().then((value) {
      if (value.data.isNotEmpty) {
        setState(() {
          bioTextController.text = value.data['bio'];
        });
      }
    });
  }

  // Method to update the user's name in Appwrite
  updateName(String newName) async {
    try {
      final AuthAPI appwrite = context.read<AuthAPI>();
      await appwrite.updateName(newName); // Assuming updateName is a method in AuthAPI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update name: $e')),
      );
    }
  }

  // Method to update the user's password in Appwrite
  updatePassword(String newPassword) async {
    try {
      final AuthAPI appwrite = context.read<AuthAPI>();
      await appwrite.updatePassword(newPassword); // Assuming updatePassword is a method in AuthAPI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update password: $e')),
      );
    }
  }

  // Method to update the user's bio (already implemented)
  savePreferences() {
    final AuthAPI appwrite = context.read<AuthAPI>();
    appwrite.updatePreferences(bio: bioTextController.text);
    const snackbar = SnackBar(content: Text('Bio updated!'));
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  signOut() {
    final AuthAPI appwrite = context.read<AuthAPI>();
    appwrite.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: signOut,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Welcome back, $username!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text('$email', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),

              // Change Name Card
              Card(
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.save),
                    onPressed: () => updateName(nameController.text),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Change Password Card
              Card(
                child: ListTile(
                  leading: Icon(Icons.lock),
                  title: TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.save),
                    onPressed: () => updatePassword(passwordController.text),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Change Bio Card
              Card(
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: TextField(
                    controller: bioTextController,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.save),
                    onPressed: savePreferences,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}