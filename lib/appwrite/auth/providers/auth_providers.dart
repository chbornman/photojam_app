// lib/appwrite/auth/providers/auth_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/appwrite_auth_repository.dart';
import 'package:photojam_app/appwrite/appwrite_config.dart';
import 'package:photojam_app/appwrite/auth/models/user_model.dart';
import 'package:photojam_app/core/services/log_service.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final account = ref.watch(appwriteAccountProvider);
  final client = ref.watch(appwriteClientProvider);
  
  return AppwriteAuthRepository(account, client);
});


final userListProvider = FutureProvider<List<AppUser>>((ref) async {
  try {
    final authRepo = ref.watch(authRepositoryProvider);
    return await authRepo.getAllUsers();
  } catch (e) {
    LogService.instance.error('Error loading users: $e');
    throw Exception('Failed to load users: $e');
  }
});