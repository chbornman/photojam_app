import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/constants/constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailTextController = TextEditingController();
  final passwordTextController = TextEditingController();
  bool loading = false;

  signIn() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  CircularProgressIndicator(),
                ]),
          );
        });

    try {
      final AuthAPI appwrite = context.read<AuthAPI>();
      await appwrite.createEmailPasswordSession(
        email: emailTextController.text,
        password: passwordTextController.text,
      );
      Navigator.pop(context);
    } on AppwriteException catch (e) {
      Navigator.pop(context);
      showAlert(title: 'Login failed', text: e.message.toString());
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

  signInWithProvider(OAuthProvider provider) {
    try {
      context.read<AuthAPI>().signInWithProvider(provider: provider);
    } on AppwriteException catch (e) {
      showAlert(title: 'Login failed', text: e.message.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Photo Jam',
          style: TextStyle(
            fontSize: 40.0,
          ),
        ),
        foregroundColor: Colors.black,
        backgroundColor: accentColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: emailTextController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        defaultCornerRadius), 
                  ),
                  filled: true,
                  fillColor:
                      secondaryAccentColor, 
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordTextController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        defaultCornerRadius),
                  ),
                  filled: true,
                  fillColor: secondaryAccentColor,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  signIn();
                },
                icon: const Icon(Icons.login),
                label: const Text("Sign in"),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      accentColor, 
                  foregroundColor: Colors.black, 
                  minimumSize: const Size(double.infinity,
                      defaultButtonHeight), 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        defaultCornerRadius), 
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RegisterPage()));
                },
                child: const Text('Create Account'),
                style: TextButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black, // Black text color
                  minimumSize: const Size(double.infinity,
                      defaultButtonHeight), // Full-width button with fixed height
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        defaultCornerRadius), // Consistent corner radius
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => signInWithProvider(OAuthProvider.google),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor:
                            Colors.black, // Black text color for OAuth buttons
                        minimumSize: const Size(double.infinity,
                            defaultButtonHeight), // Half-width button with fixed height
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              defaultCornerRadius), // Consistent corner radius
                        ),
                      ),
                      child:
                          SvgPicture.asset('assets/google_icon.svg', width: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => signInWithProvider(OAuthProvider.apple),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity,
                            defaultButtonHeight), // Half-width button with fixed height
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              defaultCornerRadius), // Consistent corner radius
                        ),
                      ),
                      child:
                          SvgPicture.asset('assets/apple_icon.svg', width: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      backgroundColor: secondaryAccentColor,
    );
  }
}
