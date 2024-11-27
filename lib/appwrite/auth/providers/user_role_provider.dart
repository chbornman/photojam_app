import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_providers.dart';

final userRoleProvider = FutureProvider<String>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  final role = await authRepository.getUserRole();
  return role;
});

// Add a new provider for direct label access if needed
final userLabelsProvider = FutureProvider<List<String>>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  final user = await authRepository.getCurrentUser();
  return user?.labels ?? [];
});