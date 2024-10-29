import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:photojam_app/constants/constants.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/pages/login_page.dart';
import 'package:photojam_app/pages/tabs_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Client client = Client()
      .setEndpoint(APPWRITE_URL)
      .setProject(APPWRITE_PROJECT_ID);

  final realtime = Realtime(client);

  final subscription = realtime.subscribe(['account']);

  subscription.stream.listen((response) {
      // Callback will be executed on all account events.
      print(response);
  });
  
  // runApp(const MyApp());
  runApp(ChangeNotifierProvider(
      create: ((context) => AuthAPI()), child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final value = context.watch<AuthAPI>().status;
    print('TOP CHANGE Value changed to: $value!');

    return MaterialApp(
        title: 'PhotoJam',
        debugShowCheckedModeBanner: false,
        home: value == AuthStatus.uninitialized
            ? const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              )
            : value == AuthStatus.authenticated
                ? const TabsPage()
                : const LoginPage(),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: const Color(0xFFE91052),
          ),
        ));
  }
}