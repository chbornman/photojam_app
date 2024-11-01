import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/pages/login_register/login_page.dart';
import 'package:photojam_app/pages/tabs_page.dart';
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
        Provider<DatabaseAPI>(create: (_) => DatabaseAPI(client)),
        Provider<StorageAPI>(create: (_) => StorageAPI(client)),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhotoJam',
      home: Consumer<AuthAPI>(
        builder: (context, authAPI, child) {
          if (authAPI.status == AuthStatus.authenticated) {
            return TabsPage();
          } else if (authAPI.status == AuthStatus.unauthenticated) {
            return LoginPage();
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}