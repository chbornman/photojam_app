import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/empty_page.dart';
import 'package:photojam_app/features/auth/screens/login_screen.dart';
import 'package:photojam_app/features/facilitator/screens/facilitator_screen.dart';
import 'package:photojam_app/features/jams/screens/jams_page.dart';
import 'package:photojam_app/core/widgets/standard_appbar.dart';
import 'package:photojam_app/features/account/screens/account_screen.dart';
import 'package:photojam_app/features/journeys/screens/journey_page.dart';
import 'package:photojam_app/features/admin/screens/admin_screen.dart';
import 'package:photojam_app/features/photos/screens/photos_screen.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_state_provider.dart';

class App extends ConsumerStatefulWidget {
  final String userRole;

  const App({
    super.key,
    required this.userRole,
  });

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _validateAccess();
  }

  void _validateAccess() {
    final isAdmin = widget.userRole == 'admin';
    final isFacilitator = widget.userRole == 'facilitator' || isAdmin;

    // If current index is for admin/facilitator pages but user lost permission,
    // redirect to home
    if ((_currentIndex == 4 && !isFacilitator) ||
        (_currentIndex == 5 && !isAdmin)) {
      setState(() => _currentIndex = 0);
    }
  }

  List<Widget> _getScreens(String userRole) {
    final isAdmin = userRole == 'admin';
    final isFacilitator = userRole == 'facilitator' || isAdmin;

    return [
      EmptyPage(), //const JamPage(),
      EmptyPage(), //const JourneyPage(),
      EmptyPage(), //const PhotosPage(),
      EmptyPage(), //const AccountPage(),
      if (isFacilitator) const FacilitatorPage(),
      EmptyPage(), //if (isAdmin) const AdminPage(),
    ];
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authStateProvider.notifier).signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Signed out successfully!"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error signing out: $e"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.userRole == 'admin';
    final isFacilitator = widget.userRole == 'facilitator' || isAdmin;

    // Watch auth state to handle sign out and session expiry
    ref.listen(authStateProvider, (previous, current) {
      current.whenOrNull(
        unauthenticated: () {
          // Updated to use MaterialPageRoute instead of named route
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
          );
        },
        error: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    });

    final screens = _getScreens(widget.userRole);

    return Scaffold(
      appBar: StandardAppBar(
        title: getTitleForIndex(_currentIndex),
        actions: _currentIndex == 3
            ? [
                IconButton(
                  icon: Icon(
                    Icons.logout,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: _signOut,
                  tooltip: 'Sign Out',
                ),
              ]
            : null,
        onLogoTap: () => setState(() => _currentIndex = 0),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.shifting,
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        onTap: (index) {
          if (mounted) {
            setState(() => _currentIndex = index);
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Jams',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Journeys',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.subscriptions),
            label: 'Photos',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
          if (isFacilitator)
            const BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: 'Facilitate',
            ),
          if (isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
        ],
      ),
    );
  }
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
