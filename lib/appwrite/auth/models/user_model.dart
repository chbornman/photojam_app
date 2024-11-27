// lib/appwrite/auth/models/user_model.dart
import 'package:appwrite/models.dart';

class AppUser {
  final String id;
  final String email;
  final String name;
  final bool emailVerification;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Preferences prefs;
  final List<String> labels; // Add this

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.emailVerification,
    required this.createdAt,
    required this.updatedAt,
    required this.prefs,
    required this.labels,
  });

  factory AppUser.fromAccount(User user) {
    return AppUser(
      id: user.$id,
      email: user.email,
      name: user.name,
      emailVerification: user.emailVerification,
      createdAt: DateTime.parse(user.$createdAt),
      updatedAt: DateTime.parse(user.$updatedAt),
      prefs: user.prefs,
      labels: List<String>.from(user.labels),
    );
  }
}