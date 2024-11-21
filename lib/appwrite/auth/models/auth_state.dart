// lib/appwrite/auth/models/auth_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import './user_model.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(AppUser user) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(String message) = _Error;

  const AuthState._(); // Add a private constructor for common methods

  bool get isLoading => this is _Loading;
  bool get isAuthenticated => this is _Authenticated;
  bool get isUnauthenticated => this is _Unauthenticated;
  bool get hasError => this is _Error;

  AppUser? get user => maybeWhen(
        authenticated: (user) => user,
        orElse: () => null,
      );

  String? get errorMessage => maybeWhen(
        error: (message) => message,
        orElse: () => null,
      );
}