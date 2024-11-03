import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:flutter/material.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:photojam_app/standard_button.dart';
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
  String? selectedRole = 'nonmember';

  // Role options for the dropdown
  final List<String> roles = ['nonmember', 'member', 'facilitator', 'admin'];

  createAccount() async {
    try {
      final authAPI = context.read<AuthAPI>();
      print("AuthAPI instance acquired.");

      // Attempt to create the user account in Appwrite
      await authAPI.createUser(
        name: nameTextController.text,
        email: emailTextController.text,
        password: passwordTextController.text,
      );
      print("Account creation successful!");

      // Authenticate and set role once the user is logged in
      await authAPI.createEmailPasswordSession(
        email: emailTextController.text,
        password: passwordTextController.text,
      );

      // Set role if login is successful
      if (selectedRole != null) {
        await authAPI.setRole(selectedRole!);
        print("Role ${selectedRole!} set successfully.");
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created and role set!')));
    } on AppwriteException catch (e) {
      print("Account creation failed with error code: ${e.code}");
      showAlert(
        title: 'Account creation failed',
        text: e.message.toString(),
      );
    } catch (e) {
      print("An unexpected error occurred: $e");
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
        backgroundColor: PHOTOJAM_YELLOW,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameTextController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(defaultCornerRadius),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailTextController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(defaultCornerRadius),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordTextController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(defaultCornerRadius),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              StandardButton(
                label: const Text('Sign up'),
                icon: const Icon(Icons.app_registration),
                onPressed: () {
                  createAccount();
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}
