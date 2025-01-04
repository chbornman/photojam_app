import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/auth/role_utils.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/core/utils/snackbar_util.dart';
import 'package:photojam_app/features/auth/login_screen.dart';
import 'package:photojam_app/features/facilitator/facilitator_screen.dart';
import 'package:photojam_app/features/jams/jams_page.dart';
import 'package:photojam_app/core/widgets/standard_appbar.dart';
import 'package:photojam_app/features/account/account_screen.dart';
import 'package:photojam_app/features/admin/admin_screen.dart';
import 'package:photojam_app/features/photos/photos_screen.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_state_provider.dart';
import 'package:photojam_app/features/snippet/snippet_screen.dart';

class NavigationItem {
  final Widget screen;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final bool Function(List<String> labels)? roleCheck;

  const NavigationItem({
    required this.screen,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    this.roleCheck,
  });

  BottomNavigationBarItem toBottomNavItem() {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      label: label,
      backgroundColor: backgroundColor,
    );
  }
}

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
    // We'll call _validateAccess in didChangeDependencies instead
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _validateAccess();
  }

  List<NavigationItem> _getNavigationItems() {
    final theme = Theme.of(context);

    return [
      NavigationItem(
        screen: const JamPage(),
        label: 'Jams',
        icon: Icons.camera_alt,
        backgroundColor: theme.colorScheme.secondary,
      ),
      NavigationItem(
        screen: const SnippetScreen(),
        label: 'Lesson',
        icon: Icons.book,
        backgroundColor: theme.colorScheme.primary,
      ),
      NavigationItem(
        screen: const PhotosPage(),
        label: 'Photos',
        icon: Icons.subscriptions,
        backgroundColor: AppConstants.photojamPaleBlue,
      ),
//      NavigationItem(
//        screen: const AccountScreen(),
//        label: 'Account',
//        icon: Icons.account_circle,
//        backgroundColor: AppConstants.photojamPurple,
//      ),
      NavigationItem(
        screen: const FacilitatorPage(),
        label: 'Facilitate',
        icon: Icons.group,
        backgroundColor: AppConstants.photojamDarkYellow,
        roleCheck: RoleUtils.isFacilitator,
      ),
      NavigationItem(
        screen: const AdminPage(),
        label: 'Admin',
        icon: Icons.admin_panel_settings,
        backgroundColor: AppConstants.photojamDarkPink,
        roleCheck: RoleUtils.isAdmin,
      ),
    ];
  }

  List<NavigationItem> _getVisibleNavigationItems() {
    final labels = [widget.userRole];
    return _getNavigationItems().where((item) {
      return item.roleCheck?.call(labels) ?? true;
    }).toList();
  }

  void _validateAccess() {
    final visibleItems = _getVisibleNavigationItems();
    if (_currentIndex >= visibleItems.length) {
      setState(() => _currentIndex = 0);
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleItems = _getVisibleNavigationItems();

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
          SnackbarUtil.showErrorSnackBar(context, message);
        },
      );
    });

    final currentItem = visibleItems[_currentIndex];

    return Scaffold(
      appBar: StandardAppBar(
        title: currentItem.label,
        actions: [
          IconButton(
            icon: Icon(
              Icons.account_circle,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AccountScreen()),
              );
            },
          ),
        ],
        onLogoTap: () => setState(() => _currentIndex = 0),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: visibleItems.map((item) => item.screen).toList(),
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
        items: visibleItems.map((item) => item.toBottomNavItem()).toList(),
      ),
    );
  }
}
