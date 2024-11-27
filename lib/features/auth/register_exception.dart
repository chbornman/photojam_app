// lib/features/auth/exceptions/register_exception.dart
class RegisterException implements Exception {
  final String message;

  const RegisterException(this.message);

  @override
  String toString() => message;
}