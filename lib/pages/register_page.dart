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

  createAccount(String selectedRole) async {
    // Use selectedRole directly as it is now non-nullable
    try {
      final AuthAPI appwrite = context.read<AuthAPI>();
      await appwrite.createUser(
        name: nameTextController.text,
        email: emailTextController.text,
        password: passwordTextController.text,
        role: selectedRole, // Directly passing selectedRole
      );
      Navigator.pop(context);
      const snackbar = SnackBar(content: Text('Account created!'));
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    } on AppwriteException catch (e) {
      Navigator.pop(context);
      showAlert(title: 'Account creation failed', text: e.message.toString());
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
              // Dropdown for user role selection
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select Role',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(defaultCornerRadius),
                  ),
                  filled: true,
                  fillColor: secondaryAccentColor,
                ),
                value: selectedRole,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedRole = newValue;
                  });
                },
                items: roles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  if (selectedRole == null) {
                    // Prompt the user to select a role if none is chosen
                    showAlert(
                        title: 'Select Role',
                        text: 'Please select a role before signing up.');
                  } else {
                    // Pass selectedRole as non-nullable using `!`
                    createAccount(selectedRole!);
                  }
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
