// lib/appwrite/auth/providers/auth_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/appwrite_auth_repository.dart';
import 'package:photojam_app/appwrite/appwrite_config.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final account = ref.watch(appwriteAccountProvider);
  final teams = ref.watch(appwriteTeamsProvider); 
  
  return AppwriteAuthRepository(account, teams);
});