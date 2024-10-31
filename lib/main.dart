
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/pages/login_page.dart';
import 'package:photojam_app/pages/tabs_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize and configure Appwrite Client
  final Client client = Client()
      .setEndpoint(APPWRITE_URL)
      .setProject(APPWRITE_PROJECT_ID)
      .setSelfSigned(); // Include only if necessary

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthAPI>(create: (_) => AuthAPI(client)),
        Provider<DatabaseAPI>(create: (_) => DatabaseAPI(client)),
        Provider<StorageAPI>(create: (_) => StorageAPI(client)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authAPI = Provider.of<AuthAPI>(context);
    
    // Display TabsPage if authenticated, otherwise LoginPage
    return MaterialApp(
      title: 'PhotoJam App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: authAPI.status == AuthStatus.authenticated
          ? const TabsPage()
          : const LoginPage(),
    );
  }
}