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
import 'package:photojam_app/constants/constants.dart';

class TabsPage extends StatefulWidget {
  const TabsPage({Key? key}) : super(key: key);

  @override
  _TabsPageState createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
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

  @override
  Widget build(BuildContext context) {
    if (userRole == null) {
      return Center(child: CircularProgressIndicator());
    }

    List<Widget> _screens = [
      HomePage(),
      JamPage(),
      JourneyPage(),
      PhotosPage(),
      AccountPage(),
    ];

    if (userRole == "admin") {
      _screens.add(AdminPage());
    }

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Photo Jam',
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).colorScheme.onSurface,
        unselectedItemColor: Theme.of(context).colorScheme.onPrimary,
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
          BottomNavigationBarItem(
              icon: Icon(Icons.subscriptions), label: 'Photos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: 'Account'),
          if (userRole == "admin")
            BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        ],
      ),
    );
  }
}
