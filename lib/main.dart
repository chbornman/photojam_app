import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/constants/custom_theme.dart';
import 'package:photojam_app/log_service.dart';
import 'package:photojam_app/pages/login_register/login_page.dart';
import 'package:photojam_app/pages/mainframe.dart';
import 'package:photojam_app/splashscreen.dart';
import 'package:photojam_app/utilities/userdataprovider.dart';
import 'package:provider/provider.dart';

void main() async {
  LogService.instance.info("App started");
  WidgetsFlutterBinding.ensureInitialized();

  final Client client = Client()
      .setEndpoint(appwriteEndpointId)
      .setProject(appwriteProjectId)
      .setSelfSigned();

  final authAPI = AuthAPI(client);
  final userDataProvider = UserDataProvider(authAPI);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthAPI>(create: (_) => authAPI),
        ChangeNotifierProvider<UserDataProvider>(create: (_) => userDataProvider),
        Provider<DatabaseAPI>(create: (_) => DatabaseAPI(client)),
        Provider<StorageAPI>(create: (_) => StorageAPI(client)),
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
      final userDataProvider = Provider.of<UserDataProvider>(context, listen: false);

      LogService.instance.info("Starting app initialization");
      
      // First load authentication
      await authAPI.loadUser();
      
      // If authenticated, load user role
      if (authAPI.status == AuthStatus.authenticated) {
        LogService.instance.info("User authenticated, loading user role");
        await userDataProvider.loadUserRole();
        LogService.instance.info("User role loaded: ${userDataProvider.userRole}");
      }

      setState(() {
        _isInitialized = true;
      });
      
    } catch (e) {
      LogService.instance.error("Error during initialization: $e");
      setState(() {
        _isInitialized = true; // Still mark as initialized so we can show error state if needed
      });
    }
  }

  void _onSplashComplete() {
    // Only hide splash if initialization is complete
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
              // If animation completes before initialization, it will wait
              // If initialization completes first, splash will continue until animation completes
            )
          : Consumer2<AuthAPI, UserDataProvider>(
              builder: (context, authAPI, userDataProvider, _) {
                // Check authentication status
                if (authAPI.status != AuthStatus.authenticated) {
                  return LoginPage();
                }
                
                // Double check user role is loaded
                if (userDataProvider.userRole == null) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                // All data is loaded, show main app
                return Mainframe();
              },
            ),
    );
  }
}