// account_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/features/account/account_actions.dart';
import 'package:photojam_app/features/account/account_info.dart';
import 'package:photojam_app/features/account/account_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountProvider);

    if (accountState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AccountInfo(
              name: accountState.name,
              email: accountState.email,
              role: accountState.role,
            ),
            const SizedBox(height: 24),
            AccountActions(
              isMember: accountState.isMember,
              isFacilitator: accountState.isFacilitator,
            ),
            if (accountState.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  accountState.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
