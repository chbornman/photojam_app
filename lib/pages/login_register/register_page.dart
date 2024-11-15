import 'package:flutter/material.dart';
import 'package:photojam_app/pages/login_register/register_controller.dart';
import 'package:photojam_app/pages/login_register/register_form.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create your account'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ChangeNotifierProvider(
        create: (_) => RegisterController(context.read()),
        child: const RegisterForm(),
      ),
    );
  }
}