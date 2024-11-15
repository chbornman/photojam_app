import 'package:flutter/material.dart';
import 'package:photojam_app/core/widgets/loading_overlay.dart';
import 'package:photojam_app/features/auth/controllers/login_controller.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/core/widgets/standard_button.dart';
import 'package:photojam_app/features/auth/screens/register_screen.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LoginController>();
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildEmailField(controller.isLoading),
                  const SizedBox(height: 18),
                  _buildPasswordField(controller.isLoading),
                  const SizedBox(height: 26),
                  _buildLoginButton(controller),
                  const SizedBox(height: 16),
                  _buildRegisterButton(controller),
                ],
              ),
            ),
          ),
          if (controller.isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildEmailField(bool isLoading) {
    return TextField(
      controller: _emailController,
      enabled: !isLoading,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
    );
  }

  Widget _buildPasswordField(bool isLoading) {
    return TextField(
      controller: _passwordController,
      enabled: !isLoading,
      obscureText: _obscurePassword,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }

  Widget _buildLoginButton(LoginController controller) {
    return StandardButton(
      label: Text(
        controller.isLoading ? "Signing In..." : "Sign In",
        style: const TextStyle(fontSize: 18),
      ),
      onPressed: controller.isLoading
          ? null
          : () => controller.signIn(
                email: _emailController.text,
                password: _passwordController.text,
              ),
      icon: Icon(
        Icons.login,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildRegisterButton(LoginController controller) {
    return StandardButton(
      label: const Text("Create Account", style: TextStyle(fontSize: 18)),
      icon: Icon(
        Icons.app_registration,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
      onPressed: controller.isLoading
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RegisterPage(),
                ),
              ),
    );
  }
}