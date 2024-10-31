import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:flutter/material.dart';
import 'package:photojam_app/constants/constants.dart';
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

  // Add a controller to store the selected role
  String? selectedRole;

  // Role options for the dropdown
  final List<String> roles = ['nonmember', 'member', 'facilitator', 'admin'];

  createAccount() async {
    try {
      // Step 1: Obtain the AuthAPI instance to interact with Appwrite authentication
      final AuthAPI appwrite = context.read<AuthAPI>();
      print("AuthAPI instance acquired.");

      // Step 2: Log the input data for debugging
      print("Starting account creation with details:");
      print("Name: ${nameTextController.text}");
      print("Email: ${emailTextController.text}");

      // Step 3: Attempt to create the user account in Appwrite
      await appwrite.createUser(
        name: nameTextController.text,
        email: emailTextController.text,
        password: passwordTextController.text,
      );
      print("Account creation successful!");

      // Step 4: Notify user of success and return to the previous screen
      Navigator.pop(context);
      const snackbar = SnackBar(content: Text('Account created!'));
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    } on AppwriteException catch (e) {
      // Step 5: Catch any Appwrite-specific exceptions and log them
      print("Account creation failed with error code: ${e.code}");
      print("Error message: ${e.message}");

      // Step 6: Display the error message to the user in a dialog
      Navigator.pop(context);
      showAlert(
        title: 'Account creation failed',
        text: e.message.toString(),
      );
    } catch (e) {
      // Step 7: Catch any unexpected errors that aren't Appwrite exceptions
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
        backgroundColor: accentColor,
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
                  fillColor: secondaryAccentColor,
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
                  fillColor: secondaryAccentColor,
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
                  fillColor: secondaryAccentColor,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  createAccount();
                },
                icon: const Icon(Icons.app_registration),
                label: const Text('Sign up'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: accentColor,
                  minimumSize: Size(double.infinity, defaultButtonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(defaultCornerRadius),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: secondaryAccentColor,
    );
  }
}
