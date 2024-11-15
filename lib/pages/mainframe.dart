import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/pages/admin/facilitator_page.dart';
import 'package:photojam_app/pages/jams/jams_page.dart';
import 'package:photojam_app/utilities/standard_appbar.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/pages/account/account_page.dart';
import 'package:photojam_app/pages/journeys/journey_page.dart';
import 'package:photojam_app/pages/admin/admin_page.dart';
import 'package:photojam_app/pages/photos_tab/photos_page.dart';

class Mainframe extends StatefulWidget {
  final String userRole;

  const Mainframe({
    super.key,
    required this.userRole,
  });

  @override
  _MainframeState createState() => _MainframeState();
}

class _MainframeState extends State<Mainframe> {
  int _currentIndex = 0;

  List<Widget> getScreens(String userRole) {
    return [
      JamPage(),
      JourneyPage(),
      PhotosPage(),
      AccountPage(),
      if (userRole == "facilitator" || userRole == "admin") FacilitatorPage(),
      if (userRole == "admin") AdminPage(),
    ];
  }

  void signOut() {
    context.read<AuthAPI>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> screens = getScreens(widget.userRole);

    return Scaffold(
      appBar: StandardAppBar(
        title: getTitleForIndex(_currentIndex),
        actions: _currentIndex == 3
            ? [
                IconButton(
                  icon: Icon(Icons.logout,
                      color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: () {
                    signOut();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Signed out successfully!")),
                    );
                  },
                  tooltip: 'Sign Out',
                ),
              ]
            : null,
        onLogoTap: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.shifting,
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).colorScheme.onSurface,
        unselectedItemColor: Theme.of(context).colorScheme.surface,
        onTap: (index) {
          if (mounted) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Jams',
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Journeys',
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.subscriptions),
            label: 'Photos',
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          if (widget.userRole == "facilitator" || widget.userRole == "admin")
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: 'Facilitate',
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          if (widget.userRole == "admin")
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );
  }

  // ... rest of the code remains the same
}

String getTitleForIndex(int index) {
  switch (index) {
    case 0:
      return 'Jams';
    case 1:
      return 'Journeys';
    case 2:
      return 'Photos';
    case 3:
      return 'Account';
    case 4:
      return 'Facilitator Dashboard';
    case 5:
      return 'Admin Dashboard';
    default:
      return 'PhotoJam';
  }
}
