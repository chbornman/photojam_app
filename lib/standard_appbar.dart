import 'package:flutter/material.dart';
import 'package:photojam_app/pages/tabs_page.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  StandardAppBar({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: Theme.of(context).colorScheme.primary,
      leading: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TabsPage()),
        ),
        child: Image.asset('assets/icon/app_icon.png'),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
