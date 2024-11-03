import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/pages/jams/jams_page.dart';
import 'package:photojam_app/standard_appbar.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/pages/account_page.dart';
import 'package:photojam_app/pages/home/home_page.dart';
import 'package:photojam_app/pages/journeys/journey_page.dart';
import 'package:photojam_app/pages/admin/admin_page.dart';
import 'package:photojam_app/pages/photos_tab/photos_page.dart';

class Mainframe extends StatefulWidget {
  const Mainframe({Key? key}) : super(key: key);

  @override
  _MainframeState createState() => _MainframeState();
}

class _MainframeState extends State<Mainframe> {
  int _currentIndex = 0;
  String? userRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchUserRole());
  }

  void _fetchUserRole() async {
    final authAPI = Provider.of<AuthAPI>(context, listen: false);
    try {
      final role = await authAPI.getUserRole();
      if (mounted) {
        setState(() {
          userRole = role;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userRole = null;
        });
      }
    }
  }

  List<Widget> getScreens() {
    return [
      HomePage(),
      JamPage(),
      JourneyPage(),
      PhotosPage(),
      AccountPage(),
      if (userRole == "admin") AdminPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (userRole == null) {
      return const Center(child: CircularProgressIndicator());
    }

    List<Widget> screens = getScreens();

    return Scaffold(
      appBar: StandardAppBar(
        title: getTitleForIndex(_currentIndex),
        actions: _currentIndex == 4 // Show sign-out button only on AccountPage
            ? [
                IconButton(
                  icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: () {
                    context.read<AuthAPI>().signOut();
                    Navigator.of(context).pop(); // Optional: Navigate back to login screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Signed out successfully!")),
                    );
                  },
                  tooltip: 'Sign Out',
                ),
              ]
            : null,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).colorScheme.onSurface,
        unselectedItemColor: Theme.of(context).colorScheme.surface,
        backgroundColor: Theme.of(context).colorScheme.primary,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Jams'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Journeys'),
          BottomNavigationBarItem(icon: Icon(Icons.subscriptions), label: 'Photos'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
          if (userRole == "admin")
            BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        ],
      ),
    );
  }

  String getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Jams';
      case 2:
        return 'Journeys';
      case 3:
        return 'My Photos';
      case 4:
        return 'Account';
      case 5:
        return 'Admin Panel';
      default:
        return 'PhotoJam';
    }
  }
}