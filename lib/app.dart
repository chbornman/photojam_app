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
      const JamPage(),
      const JourneyPage(),
      const PhotosPage(),
      EmptyPage(), //const AccountPage(),
      if (isFacilitator) const FacilitatorPage(),
      if (isAdmin) const AdminPage(),
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
    final theme = Theme.of(context);

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
                    color: theme.colorScheme.onPrimary,
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
        selectedItemColor: theme.colorScheme.onPrimary,
        unselectedItemColor: theme.colorScheme.onPrimary.withOpacity(0.7),
        showSelectedLabels: true,
        onTap: (index) {
          if (mounted) {
            setState(() => _currentIndex = index);
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.camera_alt),
            label: 'Jams',
            backgroundColor: theme.colorScheme.primary,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.book),
            label: 'Journeys',
            backgroundColor: theme.colorScheme.primary,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.subscriptions),
            label: 'Photos',
            backgroundColor: theme.colorScheme.primary,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_circle),
            label: 'Account',
            backgroundColor: theme.colorScheme.primary,
          ),
          if (isFacilitator)
            BottomNavigationBarItem(
              icon: const Icon(Icons.group),
              label: 'Facilitate',
              backgroundColor: theme.colorScheme.primary,
            ),
          if (isAdmin)
            BottomNavigationBarItem(
              icon: const Icon(Icons.admin_panel_settings),
              label: 'Admin',
              backgroundColor: theme.colorScheme.primary,
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
