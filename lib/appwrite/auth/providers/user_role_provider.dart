// Provider for user role that uses the auth repository
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_providers.dart';

final userRoleProvider = FutureProvider<String>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.getUserRole();
});