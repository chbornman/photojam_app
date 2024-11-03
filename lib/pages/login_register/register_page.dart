import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:flutter/material.dart';
import 'package:photojam_app/utilities/standard_button.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameTextController = TextEditingController();
  final emailTextController = TextEditingController();
  final passwordTextController = TextEditingController();
  final confirmPasswordTextController = TextEditingController();
  String? selectedRole = 'nonmember';

  final List<String> roles = ['nonmember', 'member', 'facilitator', 'admin'];

  createAccount() async {
    if (passwordTextController.text != confirmPasswordTextController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match!")),
      );
      return;
    }

    try {
      final authAPI = context.read<AuthAPI>();

      await authAPI.createUser(
        name: nameTextController.text,
        email: emailTextController.text,
        password: passwordTextController.text,
      );

      await authAPI.createEmailPasswordSession(
        email: emailTextController.text,
        password: passwordTextController.text,
      );

      if (selectedRole != null) {
        await authAPI.setRole(selectedRole!);
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created and role set!')));
    } on AppwriteException catch (e) {
      showAlert(
        title: 'Account creation failed',
        text: e.message.toString(),
      );
    } catch (e) {
      showAlert(
        title: 'Unexpected Error',
        text: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  showAlert({required String title, required String text}) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: Text(text),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Ok'))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create your account'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: nameTextController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    contentPadding: const EdgeInsets.all(20.0),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailTextController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    contentPadding: const EdgeInsets.all(20.0),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordTextController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    contentPadding: const EdgeInsets.all(20.0),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordTextController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    contentPadding: const EdgeInsets.all(20.0),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: roles
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          ))
                      .toList(),
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    contentPadding: const EdgeInsets.all(20.0),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value;
                    });
                  },
                ),
                const SizedBox(height: 26),
                StandardButton(
                  label: const Text("Sign up", style: TextStyle(fontSize: 18)),
                  icon: Icon(
                    Icons.app_registration,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: createAccount,
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
    );
  }
}