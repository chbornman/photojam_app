import 'package:flutter/material.dart';
import 'package:photojam_app/pages/login/login_controller.dart';
import 'package:photojam_app/pages/login/login_form.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/utilities/standard_appbar.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(
        title: 'Photo Jam',
        enableLeadingGesture: false,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ChangeNotifierProvider(
        create: (_) => LoginController(context.read()),
        child: const LoginForm(),
      ),
    );
  }
}