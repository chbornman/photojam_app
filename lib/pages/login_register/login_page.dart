import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/pages/login_register/register_page.dart';
import 'package:flutter/material.dart';
import 'package:photojam_app/utilities/standard_appbar.dart';
import 'package:photojam_app/utilities/standard_button.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/log_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailTextController = TextEditingController();
  final passwordTextController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword =
      true; // Add this line to track password visibility state

  Future<void> signIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authAPI = context.read<AuthAPI>();

      LogService.instance.info("Attempting to sign in");

      await authAPI.createEmailPasswordSession(
        email: emailTextController.text,
        password: passwordTextController.text,
      );

      LogService.instance.info("Login successful");
    } on AppwriteException catch (e) {
      LogService.instance.error("Login failed: ${e.message}");
      if (!mounted) return;
      showAlert(title: 'Login failed', text: e.message.toString());
    } catch (e) {
      LogService.instance.error("Unexpected error during login: $e");
      if (!mounted) return;
      showAlert(title: 'Login failed', text: 'An unexpected error occurred');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void showAlert({required String title, required String text}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(
        title: 'Photo Jam',
        enableLeadingGesture: false,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: emailTextController,
                      enabled: !_isLoading,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(20.0),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: passwordTextController,
                      enabled: !_isLoading,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(20.0),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        // Add suffix icon for password visibility toggle
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText:
                          _obscurePassword, // Use the state variable here
                    ),
                    const SizedBox(height: 26),
                    StandardButton(
                      label: Text(
                        _isLoading ? "Signing In..." : "Sign In",
                        style: TextStyle(fontSize: 18),
                      ),
                      onPressed: _isLoading ? null : signIn,
                      icon: Icon(
                        Icons.login,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StandardButton(
                      label: const Text("Create Account",
                          style: TextStyle(fontSize: 18)),
                      icon: Icon(
                        Icons.app_registration,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterPage(),
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }

  @override
  void dispose() {
    emailTextController.dispose();
    passwordTextController.dispose();
    super.dispose();
  }
}
