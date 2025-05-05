import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shopspot/providers/index_provider.dart';
import 'package:shopspot/utils/app_routes.dart';
import 'package:shopspot/utils/app_theme.dart';
import 'package:shopspot/providers/auth_provider.dart';
import 'package:shopspot/providers/restaurant_provider.dart';
import 'package:shopspot/providers/favorite_provider.dart';
import 'package:shopspot/providers/location_provider.dart';
import 'package:shopspot/providers/product_provider.dart';
import 'package:shopspot/services/database_service.dart';
import 'package:shopspot/services/connectivity_service.dart';

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
        ChangeNotifierProvider(create: (_) => IndexProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
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
      title: 'ShopSpot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // theme: AppTheme.lightTheme,
      // darkTheme: AppTheme.darkTheme,
      // themeMode: ThemeMode.system,
      onGenerateRoute: AppRoutes.generateRoute,
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
    await LocationProvider.checkLocationPermission(request: true);

    // Remove splash screen
    FlutterNativeSplash.remove();

    // Navigate to the appropriate screen
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        isAuthenticated ? AppRoutes.home : AppRoutes.login,
      );
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
  // Restaurant providers as class members to avoid BuildContext access in async methods
  late ConnectivityService _connectivityService;
  late AuthProvider _authProvider;
  late RestaurantProvider _restaurantProvider;
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
      _restaurantProvider =
          Provider.of<RestaurantProvider>(context, listen: false);
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
        _restaurantProvider.refreshRestaurants(context);

        // Mark that we've refreshed
        _connectivityService.markRefreshed();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
