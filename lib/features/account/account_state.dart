// account_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_state.freezed.dart';

@freezed
class AccountState with _$AccountState {
  const factory AccountState({
    required String name,
    required String email,
    required String role,
    @Default(false) bool isLoading,
    String? error,
  }) = _AccountState;

  const AccountState._();

  bool get isMember => role != 'nonmember';
  bool get isFacilitator => role == 'facilitator' || role == 'admin';
  bool get isAdmin => role == 'admin';
}