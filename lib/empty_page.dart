import 'package:flutter/material.dart';

class EmptyPage extends StatelessWidget {
  final String? message;
  const EmptyPage({super.key, this.message = "Empty page"});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 16.0,
            ),
            child: Text(
              message ?? "Empty page",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}