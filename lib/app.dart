import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/auth/role_utils.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/features/auth/login_screen.dart';
import 'package:photojam_app/features/facilitator/facilitator_screen.dart';
import 'package:photojam_app/features/jams/jams_page.dart';
import 'package:photojam_app/core/widgets/standard_appbar.dart';
import 'package:photojam_app/features/account/account_screen.dart';
import 'package:photojam_app/features/journeys/journey_page.dart';
import 'package:photojam_app/features/admin/admin_screen.dart';
import 'package:photojam_app/features/photos/photos_screen.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_state_provider.dart';
import 'package:photojam_app/features/snippet/snippet_screen.dart';

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
    final labels = [widget.userRole];
    final isAdmin = RoleUtils.isAdmin(labels);
    final isFacilitator = RoleUtils.isFacilitator(labels);

    if ((_currentIndex == 4 && !isFacilitator) ||
        (_currentIndex == 5 && !isAdmin)) {
      setState(() => _currentIndex = 0);
    }
  }

  List<Widget> _getScreens(String userRole) {
    final labels = [userRole];
    final isMember = RoleUtils.isMember(labels);
    final isFacilitator = RoleUtils.isFacilitator(labels);
    final isAdmin = RoleUtils.isAdmin(labels);

    return [
      const JamPage(),
      const SnippetScreen(),
      if (isMember) const JourneyPage(),
      const PhotosPage(),
      const AccountScreen(),
      if (isFacilitator) const FacilitatorPage(),
      if (isAdmin) const AdminPage(),
    ];
  }

  List<BottomNavigationBarItem> _getNavBarItems(String userRole) {
    final labels = [userRole];
    final isMember = RoleUtils.isMember(labels);
    final isFacilitator = RoleUtils.isFacilitator(labels);
    final isAdmin = RoleUtils.isAdmin(labels);
    final theme = Theme.of(context);

    return [
      BottomNavigationBarItem(
        icon: const Icon(Icons.camera_alt),
        label: 'Jams',
        backgroundColor: theme.colorScheme.primary,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.play_lesson),
        label: 'Snippet',
        backgroundColor: theme.colorScheme.secondary,
      ),
      if (isMember)
        BottomNavigationBarItem(
          icon: const Icon(Icons.book),
          label: 'Journeys',
          backgroundColor: AppConstants.photojamDarkGreen,
        ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.subscriptions),
        label: 'Photos',
        backgroundColor: AppConstants.photojamPaleBlue,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.account_circle),
        label: 'Account',
        backgroundColor: AppConstants.photojamPurple,
      ),
      if (isFacilitator)
        BottomNavigationBarItem(
          icon: const Icon(Icons.group),
          label: 'Facilitate',
          backgroundColor: AppConstants.photojamDarkYellow,
        ),
      if (isAdmin)
        BottomNavigationBarItem(
          icon: const Icon(Icons.admin_panel_settings),
          label: 'Admin',
          backgroundColor: AppConstants.photojamDarkPink,
        ),
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
    final theme = Theme.of(context);

    // Watch auth state to handle sign out and session expiry
    ref.listen(authStateProvider, (previous, current) {
      current.whenOrNull(
        unauthenticated: () {
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
    final navBarItems = _getNavBarItems(widget.userRole);

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
        items: navBarItems,
      ),
    );
  }
}

String getTitleForIndex(int index) {
  switch (index) {
    case 0:
      return 'Jams';
    case 1:
      return 'Weekly Lesson Snippet';
    case 2:
      return 'Journeys';
    case 3:
      return 'Photos';
    case 4:
      return 'Account';
    case 5:
      return 'Facilitator Dashboard';
    case 6:
      return 'Admin Dashboard';
    default:
      return 'PhotoJam';
  }
}
