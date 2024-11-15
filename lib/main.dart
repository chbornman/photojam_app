// main.dart
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/services.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/constants/custom_theme.dart';
import 'package:photojam_app/log_service.dart';
import 'package:photojam_app/pages/login_register/login_page.dart';
import 'package:photojam_app/pages/mainframe.dart';
import 'package:photojam_app/role_service.dart';
import 'package:photojam_app/splashscreen.dart';
import 'package:provider/provider.dart';

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

  final authAPI = AuthAPI(client);
  final roleService = RoleService(client);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthAPI>(create: (_) => authAPI),
        Provider<DatabaseAPI>(create: (_) => DatabaseAPI(client)),
        Provider<StorageAPI>(create: (_) => StorageAPI(client)),
        Provider<RoleService>(create: (_) => roleService),
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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final authAPI = Provider.of<AuthAPI>(context, listen: false);

      LogService.instance.info("Starting app initialization");

      // Load authentication
      await authAPI.loadUser();

      LogService.instance.info("Authentication loaded");

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      LogService.instance.error("Error during initialization: $e");
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _onSplashComplete() {
    if (_isInitialized) {
      setState(() {
        _showSplash = false;
      });
    }
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
                // Check authentication status
                if (authAPI.status != AuthStatus.authenticated) {
                  return LoginPage();
                }

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

                    // All data is loaded, show main app
                    return Mainframe(userRole: snapshot.data ?? 'nonmember');
                  },
                );
              },
            ),
    );
  }
}
