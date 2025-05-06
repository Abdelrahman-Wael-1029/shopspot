import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shopspot/cubit/index_cubit/index_cubit.dart';
import 'package:shopspot/utils/app_routes.dart';
import 'package:shopspot/cubit/auth_cubit/auth_cubit.dart';
import 'package:shopspot/cubit/restaurant_cubit/restaurant_cubit.dart';
import 'package:shopspot/cubit/favorite_cubit/favorite_cubit.dart';
import 'package:shopspot/cubit/location_cubit/location_cubit.dart';
import 'package:shopspot/cubit/product_cubit/product_cubit.dart';
import 'package:shopspot/services/database_service.dart';
import 'package:shopspot/services/connectivity_service/connectivity_service.dart';
import 'package:shopspot/utils/app_theme.dart';

void main() async {
  // Ensure Flutter is initialized - this is important!
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Keep native splash screen up until initialization is complete
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Hive database before app starts
  await DatabaseService.init();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => RestaurantCubit()),
        BlocProvider(create: (_) => IndexCubit()),
        BlocProvider(create: (_) => ConnectivityService()),
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => FavoriteCubit()),
        BlocProvider(create: (_) => LocationCubit()),
        BlocProvider(create: (_) => ProductCubit()),
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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
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
    final authCubit = context.read<AuthCubit>();
    final isAuthenticated = authCubit.checkCachedAuthentication();

    // Wait a brief moment to ensure proper initialization
    await Future.delayed(const Duration(milliseconds: 500));

    // Request location permission
    await LocationCubit.checkLocationPermission(request: true);

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
  // Restaurant cubits as class members to avoid BuildContext access in async methods
  late ConnectivityService _connectivityService;
  late AuthCubit _authCubit;
  late RestaurantCubit _restaurantCubit;
  bool _cubitsInitialized = false;

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
    // Initialize cubits once when dependencies are available
    if (!_cubitsInitialized) {
      _connectivityService =
          context.read<ConnectivityService>();
      _authCubit = context.read<AuthCubit>();
      _restaurantCubit =
          context.read<RestaurantCubit>();
      _cubitsInitialized = true;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || !_cubitsInitialized) return;

    // When app resumes, refresh data if needed
    if (state == AppLifecycleState.resumed) {
      _connectivityService.checkConnectivity();
      if (_connectivityService.shouldRefresh && _authCubit.isAuthenticated) {
        // Refresh data from server - but not profile data (will be refreshed on demand)
        _restaurantCubit.refreshRestaurants(context);

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
