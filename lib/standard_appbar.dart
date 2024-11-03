import 'package:flutter/material.dart';
import 'package:photojam_app/pages/mainframe.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  StandardAppBar({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Theme.of(context).colorScheme.surface, // Use surface color
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10.0), // Inset from the left side by 10 pixels
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Mainframe()),
          ),
          child: Image.asset('assets/icon/app_icon.png'),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(10.0), // Adjust the height here
        child: Container(
          color: Colors.transparent, // Optional: set color for visual effect
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 10.0); // Adjust height here
}