// lib/appwrite/auth/providers/membership_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_providers.dart';


//this doesn't really do anything if we only have one team
final teamMembershipProvider = FutureProvider.family<List<String>, String>((ref, userId) async {
  final authRepository = ref.read(authRepositoryProvider);
  return authRepository.getUserTeams(userId);
});