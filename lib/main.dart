import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/services.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/config/app_theme.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/features/auth/screens/login_screen.dart';
import 'package:photojam_app/app.dart';
import 'package:photojam_app/core/services/role_service.dart';
import 'package:photojam_app/features/journeys/models/journey_repository.dart';
import 'package:photojam_app/features/journeys/providers/journey_provider.dart';
import 'package:photojam_app/features/splashscreen.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';

// Add this class to handle deep links
class DeepLinkHandler {
  static Future<void> handleDeepLink(Uri uri, BuildContext context) async {
    LogService.instance.info("Handling deep link: ${uri.toString()}");

    if (uri.host == 'verify-membership') {
      final userId = uri.queryParameters['userId'];
      final secret = uri.queryParameters['secret'];
      final membershipId = uri.queryParameters['membershipId'];
      final teamId = uri.queryParameters['teamId'];

      if (userId != null &&
          secret != null &&
          membershipId != null &&
          teamId != null) {
        try {
          final roleService = Provider.of<RoleService>(context, listen: false);
          await roleService.verifyMembership(
            teamId: teamId,
            membershipId: membershipId,
            userId: userId,
            secret: secret,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team membership verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh role after verification
          await roleService.clearRoleCache();
        } catch (e) {
          LogService.instance.error("Deep link verification error: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to verify membership: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

void main() async {
  LogService.instance.info("App started");
  WidgetsFlutterBinding.ensureInitialized();

  // Add portrait mode lock
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final Client client = Client()
      .setEndpoint(appwriteEndpointId)
      .setProject(appwriteProjectId)
      .setSelfSigned();

  final roleService = RoleService(client);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthAPI>(create: (_) => AuthAPI(client)),
        Provider<DatabaseAPI>(create: (_) => DatabaseAPI(client)),
        Provider<StorageAPI>(create: (_) => StorageAPI(client)),
        Provider<RoleService>(create: (_) => roleService),
        ChangeNotifierProvider(
          create: (context) => JourneyProvider(
            JourneyRepository(
              Provider.of<DatabaseAPI>(context, listen: false),
            ),
          ),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _initializeDeepLinks();
  }

  Future<void> _initializeDeepLinks() async {
    // Handle initial URI if app was launched from deep link
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null && mounted) {
        LogService.instance.info("Handling initial deep link: $initialUri");
        await DeepLinkHandler.handleDeepLink(initialUri, context);
      }
    } catch (e) {
      LogService.instance.error("Error handling initial deep link: $e");
    }

    // Handle deep links while app is running
    uriLinkStream.listen((Uri? uri) async {
      if (uri != null && mounted) {
        await DeepLinkHandler.handleDeepLink(uri, context);
      }
    }, onError: (err) {
      LogService.instance.error("Deep link stream error: $err");
    });
  }

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhotoJam App',
      theme: getLightTheme(),
      darkTheme: getDarkTheme(),
      home: _showSplash
          ? SplashScreen(
              onAnimationComplete: _onSplashComplete,
            )
          : Consumer<AuthAPI>(
              builder: (context, authAPI, _) {
                // If not authenticated, show login
                if (!authAPI.isAuthenticated) {
                  return LoginPage();
                }

                // If authenticated, load role and show main app
                return FutureBuilder<String>(
                  future: Provider.of<RoleService>(context, listen: false)
                      .getCurrentUserRole(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      LogService.instance
                          .error("Error loading user role: ${snapshot.error}");
                      return const Scaffold(
                        body: Center(
                          child: Text("Error loading user role"),
                        ),
                      );
                    }

                    // All data is loaded, show main app
                    return App(userRole: snapshot.data ?? 'nonmember');
                  },
                );
              },
            ),
    );
  }
}
