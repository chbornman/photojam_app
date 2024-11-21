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

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.emailVerification,
    required this.createdAt,
    required this.updatedAt,
    required this.prefs,
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
    );
  }

  // Helper method to create a copy with updated fields
  AppUser copyWith({
    String? name,
    Preferences? prefs,
    bool? emailVerification,
  }) {
    return AppUser(
      id: id,
      email: email,
      name: name ?? this.name,
      emailVerification: emailVerification ?? this.emailVerification,
      createdAt: createdAt,
      updatedAt: updatedAt,
      prefs: prefs ?? this.prefs,
    );
  }

  // Convert to Map for storage or transmission
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'emailVerification': emailVerification,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'prefs': prefs.data, // Access the underlying Map from Preferences
    };
  }
}