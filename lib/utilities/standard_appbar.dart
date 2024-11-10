import 'package:flutter/material.dart';
import 'package:photojam_app/pages/mainframe.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool enableLeadingGesture; // New parameter to control leading icon tap

  const StandardAppBar({super.key, 
    required this.title,
    this.actions,
    this.enableLeadingGesture = true, // Default to true for other pages
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      leading: enableLeadingGesture
          ? Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Mainframe()),
                ),
                child: Image.asset('assets/icon/app_icon_transparent.png'),
              ),
            )
          : Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Image.asset('assets/icon/app_icon_transparent.png'),
            ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(20.0),
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10.0);
}