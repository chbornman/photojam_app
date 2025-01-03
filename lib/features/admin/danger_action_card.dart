import 'package:flutter/material.dart';
import 'package:photojam_app/core/utils/snackbar_util.dart';
import 'package:photojam_app/core/widgets/standard_card.dart';

class DangerActionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const DangerActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  State<DangerActionCard> createState() => _DangerActionCardState();
}

class _DangerActionCardState extends State<DangerActionCard> {
  bool isUnlocked = false;

  @override
  Widget build(BuildContext context) {
    return StandardCard(
      icon: isUnlocked ? widget.icon : Icons.lock,
      title: widget.title,
      action: IconButton(
        icon: Icon(
          isUnlocked ? Icons.lock_open : Icons.lock_outline,
          color: isUnlocked ? Colors.red : null,
        ),
        onPressed: () {
          setState(() {
            isUnlocked = !isUnlocked;
          });
          if (!isUnlocked) {
            SnackbarUtil.showSuccessSnackBar(context, 'Action locked');
          } else {
            SnackbarUtil.showErrorSnackBar(context, 'Warning: Dangerous action unlocked');
          }
        },
      ),
      onTap: isUnlocked
          ? widget.onTap
          : () {
            SnackbarUtil.showCustomSnackBar(context, 'Unlock this action first', Colors.blue);
            },
    );
  }
}