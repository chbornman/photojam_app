import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:photojam_app/constants/custom_theme.dart';
import 'package:photojam_app/log_service.dart';
import 'package:photojam_app/utilities/userdataprovider.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/pages/login_register/login_page.dart';
import 'package:photojam_app/pages/mainframe.dart';

void main() async {
  LogService.instance.info("App started");
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize and configure Appwrite Client
  final Client client = Client()
      .setEndpoint(appwriteEndpointId)
      .setProject(appwriteProjectId)
      .setSelfSigned(); // Include only if necessary

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthAPI>(create: (_) => AuthAPI(client)),
        ChangeNotifierProvider<UserDataProvider>(
            create: (_) => UserDataProvider()),
        Provider<DatabaseAPI>(create: (_) => DatabaseAPI(client)),
        Provider<StorageAPI>(create: (_) => StorageAPI(client)),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
            return FutureBuilder(
              future:
                  context.read<UserDataProvider>().initializeUserData(authAPI),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(); // Show a loading indicator while initializing
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error loading user data."));
                } else {
                  return Mainframe(); // Proceed to main content when initialization is complete
                }
              },
            );
          } else {
            return LoginPage();
          }
        },
      ),
    );
  }
}
