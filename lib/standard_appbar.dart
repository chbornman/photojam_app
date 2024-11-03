import 'package:flutter/material.dart';
import 'package:photojam_app/pages/mainframe.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions; // Add an optional actions parameter

  StandardAppBar({
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10.0),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Mainframe()),
          ),
          child: Image.asset('assets/icon/app_icon.png'),
        ),
      ),
      actions: actions, // Pass actions to AppBar
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(10.0),
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10.0);
}