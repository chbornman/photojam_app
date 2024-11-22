import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_state_provider.dart';
import 'package:photojam_app/appwrite/auth/providers/user_role_provider.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/error_screen.dart';
import 'package:photojam_app/features/auth/screens/login_screen.dart';
import 'package:photojam_app/app.dart';
import 'package:photojam_app/features/splashscreen.dart';
import 'package:uni_links/uni_links.dart';



void main() async {
  LogService.instance.info("App started");
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  ); 
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _initializeDeepLinks();
    // Initialize auth state
    ref.read(authStateProvider.notifier).checkAuthStatus();
  }

  Future<void> _initializeDeepLinks() async {
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null && mounted) {
        LogService.instance.info("Processing initial deep link: $initialUri");
        await _handleDeepLink(initialUri);
      }

      uriLinkStream.listen(
        (Uri? uri) async {
          if (uri != null && mounted) {
            await _handleDeepLink(uri);
          }
        },
        onError: (err) => LogService.instance.error("Deep link error: $err"),
      );
    } catch (e) {
      LogService.instance.error("Deep link initialization error: $e");
    }
  }

  Future<void> _handleDeepLink(Uri uri) async {
    if (uri.path.contains('/verify-membership')) {
      final params = uri.queryParameters;
      final requiredParams = ['teamId', 'membershipId', 'userId', 'secret'];
      
      if (requiredParams.every(params.containsKey)) {
        try {
          // After verification, refresh the role
          ref.invalidate(userRoleProvider);
          // Refresh auth state
          ref.read(authStateProvider.notifier).checkAuthStatus();
          LogService.instance.info("Membership verification successful");
        } catch (e) {
          LogService.instance.error("Membership verification failed: $e");
        }
      }
    }
  }

  void _onSplashComplete() {
    setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhotoJam',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: _showSplash
          ? SplashScreen(onAnimationComplete: _onSplashComplete)
          : Consumer(
              builder: (context, ref, _) {
                final authState = ref.watch(authStateProvider);
                
                return authState.when(
                  initial: () => const LoadingScreen(),
                  loading: () => const LoadingScreen(),
                  authenticated: (user) {
                    // Watch the user role using our new provider
                    final roleAsync = ref.watch(userRoleProvider);
                    
                    return roleAsync.when(
                      data: (role) => App(userRole: role),
                      loading: () => const LoadingScreen(),
                      error: (error, _) => ErrorScreen(
                        message: "Role check failed: $error",
                      ),
                    );
                  },
                  unauthenticated: () => const LoginPage(),
                  error: (message) => ErrorScreen(message: message),
                );
              },
            ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
