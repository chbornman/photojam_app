import 'package:flutter/material.dart';

class StandardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle; // Make subtitle optional
  final VoidCallback onTap;

  const StandardCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle, // Make subtitle optional
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primary,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.onPrimary),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: subtitle != null && subtitle!.isNotEmpty
            ? Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.8),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}