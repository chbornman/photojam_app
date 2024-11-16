import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/services.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/config/app_constants.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/config/app_theme.dart';
import 'package:photojam_app/core/services/deep_link_handler.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/features/auth/screens/login_screen.dart';
import 'package:photojam_app/app.dart';
import 'package:photojam_app/features/journeys/models/journey_repository.dart';
import 'package:photojam_app/features/journeys/providers/journey_provider.dart';
import 'package:photojam_app/features/splashscreen.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';

void main() async {
  LogService.instance.info("App started");
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final client = Client()
      .setEndpoint(appwriteEndpointId)
      .setProject(appwriteProjectId)
      .setSelfSigned();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthAPI>(create: (_) => AuthAPI(client)),
        Provider<DatabaseAPI>(create: (_) => DatabaseAPI(client)),
        Provider<StorageAPI>(create: (_) => StorageAPI(client)),
        ChangeNotifierProvider(
          create: (context) => JourneyProvider(
            JourneyRepository(
              Provider.of<DatabaseAPI>(context, listen: false),
            ),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

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
    try {
      // Handle initial URI if app was launched from deep link
      final initialUri = await getInitialUri();
      if (initialUri != null && mounted) {
        LogService.instance.info("Handling initial deep link: $initialUri");
        await DeepLinkHandler.handleDeepLink(initialUri, context);
      }

      // Handle deep links while app is running
      uriLinkStream.listen(
        (Uri? uri) async {
          if (uri != null && mounted) {
            await DeepLinkHandler.handleDeepLink(uri, context);
          }
        },
        onError: (err) =>
            LogService.instance.error("Deep link stream error: $err"),
      );
    } catch (e) {
      LogService.instance.error("Error initializing deep links: $e");
    }
  }

  void _onSplashComplete() {
    setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhotoJam App',
      theme: getLightTheme(),
      darkTheme: getDarkTheme(),
      home: _showSplash
          ? SplashScreen(onAnimationComplete: _onSplashComplete)
          : Consumer<AuthAPI>(
              builder: (context, authAPI, _) {
                if (!authAPI.isAuthenticated) {
                  return const LoginPage();
                }

                return FutureBuilder<String>(
                  future: authAPI.roleService.getCurrentUserRole(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      LogService.instance
                          .error("Error loading user role: ${snapshot.error}");
                      return const Scaffold(
                        body: Center(child: Text("Error loading user role")),
                      );
                    }

                    return App(userRole: snapshot.data ?? 'nonmember');
                  },
                );
              },
            ),
    );
  }
}
