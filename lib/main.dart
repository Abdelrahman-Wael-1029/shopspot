import 'package:flutter/material.dart';
import 'package:shopspot/screens/login_screen.dart';
import 'package:shopspot/screens/profile_screen.dart';
import 'package:shopspot/screens/signup_screen.dart';
import 'package:shopspot/services/location_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'services/auth_provider.dart';
import 'services/location_provider.dart';
import 'services/database_service.dart';
import 'services/connectivity_service.dart';

void main() async {
  // Ensure Flutter is initialized - this is important!
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Keep native splash screen up until initialization is complete
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Hive database before app starts
  await DatabaseService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ConnectivityService()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => LocationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCI Student Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Use InitScreen as the home screen that will handle auth check
      home: const InitScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const SignupScreen());
          case '/profile':
            return MaterialPageRoute(
                builder: (_) =>
                    const AppLifecycleManager(child: ProfileScreen()));
          default:
            return MaterialPageRoute(
                builder: (_) => const AppLifecycleManager(child: InitScreen()));
        }
      },
    );
  }
}

// Screen that handles the initial loading and navigation
class InitScreen extends StatefulWidget {
  const InitScreen({super.key});

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  @override
  void initState() {
    super.initState();
    // Perform initialization on the next frame when context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndNavigate();
    });
  }

  Future<void> _initializeAndNavigate() async {
    if (!mounted) return;

    // Check authentication status
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = authProvider.checkCachedAuthentication();

    // Wait a brief moment to ensure proper initialization
    await Future.delayed(const Duration(milliseconds: 500));

    // Request location permission
    await LocationService.checkLocationPermission(request: true);

    // Remove splash screen
    FlutterNativeSplash.remove();

    // Navigate to the appropriate screen
    if (mounted) {
      Navigator.pushReplacementNamed(
          context, isAuthenticated ? '/stores' : '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or title
            const Text(
              'FCI Student Portal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            // Loading indicator
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget to handle app lifecycle state - ONLY for post-splash screens
class AppLifecycleManager extends StatefulWidget {
  final Widget child;
  const AppLifecycleManager({super.key, required this.child});

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  // Store providers as class members to avoid BuildContext access in async methods
  late ConnectivityService _connectivityService;
  late AuthProvider _authProvider;
  bool _providersInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize providers once when dependencies are available
    if (!_providersInitialized) {
      _connectivityService =
          Provider.of<ConnectivityService>(context, listen: false);
      _authProvider = Provider.of<AuthProvider>(context, listen: false);
      _providersInitialized = true;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || !_providersInitialized) return;

    // When app resumes, refresh data if needed
    if (state == AppLifecycleState.resumed) {
      _connectivityService.checkConnectivity();
      if (_connectivityService.shouldRefresh && _authProvider.isAuthenticated) {
        // Refresh data from server - but not profile data (will be refreshed on demand)
        _connectivityService.markRefreshed();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
