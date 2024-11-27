import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/features/auth/register_exception.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_providers.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_state_provider.dart';
import 'package:photojam_app/appwrite/auth/providers/user_role_provider.dart';

// Provider for the register controller
final registerControllerProvider = ChangeNotifierProvider.autoDispose((ref) {
  return RegisterController(ref);
});

class RegisterState {
  final bool isLoading;
  final String? nameError;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;

  const RegisterState({
    this.isLoading = false,
    this.nameError,
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
  });

  RegisterState copyWith({
    bool? isLoading,
    String? nameError,
    String? emailError,
    String? passwordError,
    String? confirmPasswordError,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      nameError: nameError,
      emailError: emailError,
      passwordError: passwordError,
      confirmPasswordError: confirmPasswordError,
    );
  }
}

class RegisterController extends ChangeNotifier {
  final AutoDisposeRef _ref;
  RegisterState _state = const RegisterState();
  bool _disposed = false;

  RegisterController(this._ref) {
    _ref.onDispose(() {
      _disposed = true;
    });
  }

  bool get isLoading => _state.isLoading;
  String? get nameError => _state.nameError;
  String? get emailError => _state.emailError;
  String? get passwordError => _state.passwordError;
  String? get confirmPasswordError => _state.confirmPasswordError;

  void _updateState(RegisterState newState) {
    if (!_disposed) {
      _state = newState;
      notifyListeners();
    }
  }

  void _clearErrors() {
    if (!_disposed) {
      _updateState(_state.copyWith(
        nameError: null,
        emailError: null,
        passwordError: null,
        confirmPasswordError: null,
      ));
    }
  }

  bool _validateInputs({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    bool isValid = true;
    _clearErrors();

    RegisterState newState = _state;

    if (name.trim().isEmpty) {
      newState = newState.copyWith(nameError: 'Please enter your name');
      isValid = false;
    }

    if (email.trim().isEmpty) {
      newState = newState.copyWith(emailError: 'Please enter your email');
      isValid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      newState = newState.copyWith(emailError: 'Please enter a valid email');
      isValid = false;
    }

    if (password.isEmpty) {
      newState = newState.copyWith(passwordError: 'Please enter a password');
      isValid = false;
    } else if (password.length < 8) {
      newState = newState.copyWith(passwordError: 'Password must be at least 8 characters');
      isValid = false;
    }

    if (confirmPassword.isEmpty) {
      newState = newState.copyWith(confirmPasswordError: 'Please confirm your password');
      isValid = false;
    } else if (confirmPassword != password) {
      newState = newState.copyWith(confirmPasswordError: 'Passwords do not match');
      isValid = false;
    }

    _updateState(newState);
    return isValid;
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (_state.isLoading || _disposed) return;

    if (!_validateInputs(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    )) {
      return;
    }

    try {
      _updateState(_state.copyWith(isLoading: true));
      LogService.instance.info("Attempting to register user: $email");
      
      final authRepo = _ref.read(authRepositoryProvider);
      
      // Create account
      final user = await authRepo.createAccount(
        email: email,
        password: password,
        name: name,
      );

      LogService.instance.info("Account created for user: ${user.name}");

      if (_disposed) return;

      // Sign in after successful registration
      await _ref.read(authStateProvider.notifier).signIn(email, password);

      // Invalidate the role provider to force a refresh
      _ref.invalidate(userRoleProvider);
      
      LogService.instance.info("Registration and sign-in successful for user: ${user.name}");
      
    } on AppwriteException catch (e) {
      LogService.instance.error("Appwrite registration failed: ${e.message}");
      if (!_disposed) {
        throw RegisterException(e.message.toString());
      }
    } catch (e) {
      LogService.instance.error("Unexpected error during registration: $e");
      if (!_disposed) {
        if (e is RegisterException) {
          rethrow;
        }
        throw const RegisterException('An unexpected error occurred');
      }
    } finally {
      if (!_disposed) {
        _updateState(_state.copyWith(isLoading: false));
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}