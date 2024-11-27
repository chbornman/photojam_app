// account_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_providers.dart';
import 'package:photojam_app/appwrite/auth/repositories/auth_repository.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/features/account/account_state.dart';

final accountProvider = StateNotifierProvider<AccountNotifier, AccountState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AccountNotifier(authRepo);
});

class AccountNotifier extends StateNotifier<AccountState> {
  final AuthRepository _authRepo;

  AccountNotifier(this._authRepo) : super(AccountState(
    name: '',
    email: '',
    role: 'nonmember',
    isLoading: true,
  )) {
    _initializeState();
  }

  Future<void> _initializeState() async {
    try {
      final user = await _authRepo.getCurrentUser();
      final role = await _authRepo.getUserRole();
      
      if (user == null) throw Exception('No authenticated user');
      
      state = AccountState(
        name: user.name,
        email: user.email,
        role: role,
      );
    } catch (e, stack) {
      LogService.instance.error('Failed to initialize account state: $e\n$stack');
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> updateName(String newName) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authRepo.updateName(newName);
      state = state.copyWith(name: newName, isLoading: false);
    } catch (e, stack) {
      LogService.instance.error('Failed to update name: $e\n$stack');
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> updateEmail(String newEmail, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      // TODO: Implement email update in AuthRepository
      await _initializeState();
    } catch (e, stack) {
      LogService.instance.error('Failed to update email: $e\n$stack');
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authRepo.updatePassword(newPassword);
      state = state.copyWith(isLoading: false);
    } catch (e, stack) {
      LogService.instance.error('Failed to update password: $e\n$stack');
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> requestRole(String role) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      // TODO: Implement role request in AuthRepository
      await _initializeState();
    } catch (e, stack) {
      LogService.instance.error('Failed to request role: $e\n$stack');
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}
