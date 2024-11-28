import 'package:flutter/material.dart';
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Action locked'),
                duration: Duration(seconds: 1),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Warning: Dangerous action unlocked'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      ),
      onTap: isUnlocked
          ? widget.onTap
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Unlock this action first'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
    );
  }
}