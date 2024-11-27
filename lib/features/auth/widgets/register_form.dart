import 'package:flutter/material.dart';
import 'package:photojam_app/core/widgets/loading_overlay.dart';
import 'package:photojam_app/features/auth/controllers/register_controller.dart';

class RegisterForm extends StatefulWidget {
  final RegisterController controller;

  const RegisterForm({
    super.key,
    required this.controller,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _getInputDecoration({
    required String label,
    required IconData prefixIcon,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
      suffixIcon: suffixIcon,
      errorText: errorText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 2,
        ),
      ),
      fillColor: Theme.of(context).colorScheme.surface,
      filled: true,
      contentPadding: const EdgeInsets.all(16),
    );
  }

  Widget _buildVisibilityToggle(bool obscureText, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(
        obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final textStyle = TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
        );

        return Stack(
          children: [
            AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Name field
                  TextFormField(
                    controller: _nameController,
                    enabled: !widget.controller.isLoading,
                    style: textStyle,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: _getInputDecoration(
                      label: 'Full Name',
                      prefixIcon: Icons.person_outline,
                      errorText: widget.controller.nameError,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    enabled: !widget.controller.isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    style: textStyle,
                    decoration: _getInputDecoration(
                      label: 'Email Address',
                      prefixIcon: Icons.email_outlined,
                      errorText: widget.controller.emailError,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    enabled: !widget.controller.isLoading,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    style: textStyle,
                    decoration: _getInputDecoration(
                      label: 'Password',
                      prefixIcon: Icons.lock_outline,
                      errorText: widget.controller.passwordError,
                      suffixIcon: _buildVisibilityToggle(
                        _obscurePassword,
                        () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Confirm Password field
                  TextFormField(
                    controller: _confirmPasswordController,
                    enabled: !widget.controller.isLoading,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    style: textStyle,
                    onFieldSubmitted: (_) => widget.controller.register(
                      name: _nameController.text,
                      email: _emailController.text,
                      password: _passwordController.text,
                      confirmPassword: _confirmPasswordController.text,
                    ),
                    decoration: _getInputDecoration(
                      label: 'Confirm Password',
                      prefixIcon: Icons.lock_outline,
                      errorText: widget.controller.confirmPasswordError,
                      suffixIcon: _buildVisibilityToggle(
                        _obscureConfirmPassword,
                        () => setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Create Account button
                  FilledButton(
                    onPressed: widget.controller.isLoading
                        ? null
                        : () => widget.controller.register(
                              name: _nameController.text,
                              email: _emailController.text,
                              password: _passwordController.text,
                              confirmPassword: _confirmPasswordController.text,
                            ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.controller.isLoading)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        Text(
                          widget.controller.isLoading
                              ? 'Creating Account...'
                              : 'Create Account',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sign In link
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (widget.controller.isLoading) const LoadingOverlay(),
          ],
        );
      },
    );
  }
}
