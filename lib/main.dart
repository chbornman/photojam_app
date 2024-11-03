import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/constants/custom_theme.dart';
import 'package:photojam_app/pages/utilities/userdataprovider.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/pages/login_register/login_page.dart';
import 'package:photojam_app/pages/mainframe.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(); // Initialize Hive
  await Hive.openBox('submissionsCache'); // Open the cache box

  // Initialize and configure Appwrite Client
  final Client client = Client()
      .setEndpoint(APPWRITE_ENDPOINT_ID)
      .setProject(APPWRITE_PROJECT_ID)
      .setSelfSigned(); // Include only if necessary

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthAPI>(create: (_) => AuthAPI(client)),
        ChangeNotifierProvider<UserDataProvider>(
            create: (_) => UserDataProvider()), // Add UserDataProvider here
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
  bool _isUserDataInitialized = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhotoJam',
      theme: getLightTheme(),
      darkTheme: getDarkTheme(),
      themeMode: ThemeMode.system,
      home: Consumer<AuthAPI>(
        builder: (context, authAPI, child) {
          if (authAPI.status == AuthStatus.authenticated) {
            if (!_isUserDataInitialized) {
              // Delay initializeUserData until after the current frame is built
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<UserDataProvider>().initializeUserData(authAPI);
                setState(() {
                  _isUserDataInitialized = true; // Ensure this runs only once
                });
              });
            }
            return Mainframe();
          } else {
            return LoginPage();
          }
        },
      ),
    );
  }
}
