import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/pages/login_register/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photojam_app/standard_button.dart';
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
            child: Center(
              child: CircularProgressIndicator(),
            ),
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
              StandardButton(
                  label: Text("Sign in"),
                  onPressed: signIn,
                  icon: Icon(Icons.login)),
              const SizedBox(height: 16),
              StandardButton(
                label: Text("Create Account"),
                icon: Icon(Icons.app_registration),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RegisterPage()));
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: StandardButton(
                      label:
                          SvgPicture.asset('assets/google_icon.svg', width: 20),
                      onPressed: () => signInWithProvider(OAuthProvider.google),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StandardButton(
                      label:
                          SvgPicture.asset('assets/apple_icon.svg', width: 20),
                      onPressed: () => signInWithProvider(OAuthProvider.apple),
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
