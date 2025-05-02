import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopspot/providers/location_bloc.dart';
import 'package:shopspot/providers/product_provider.dart';
import 'package:shopspot/providers/restaurant_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shopspot/utils/app_theme.dart';
import 'providers/auth_bloc.dart';
import 'providers/index_bloc.dart';
import 'services/database_service.dart';
import 'providers/connectivity_bloc.dart';
import 'utils/app_routes.dart';

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
        ChangeNotifierProvider(create: (context) => ProductProvider()),
        ChangeNotifierProvider(create: (context) => RestaurantProvider()),
        
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(), // You can pass dependencies here if needed
          ),
          BlocProvider<IndexBloc>(
            create: (context) => IndexBloc(), // You can pass dependencies here if needed
          ),
          BlocProvider<LocationBloc>(
            create: (context) => LocationBloc(), // You can pass dependencies here if needed
          ),
          BlocProvider<ConnectivityBloc>(
            create: (context) => ConnectivityBloc(), // You can pass dependencies here if needed
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      onGenerateRoute: AppRoutes.generateRoute,
      home: const InitScreen(),
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
    final authProvider = Provider.of<AuthBloc>(context, listen: false);
    final isAuthenticated = authProvider.checkCachedAuthentication();

    // Check connectivity status
    final connectivityProvider =
        Provider.of<ConnectivityBloc>(context, listen: false);
    await connectivityProvider.initConnectivity();

    // Wait a brief moment to ensure proper initialization
    await Future.delayed(const Duration(milliseconds: 500));

    final locationProvider = Provider.of<LocationBloc>(context, listen: false);
    await locationProvider.initLocation();
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
  late ConnectivityBloc _ConnectivityProvider;
  late AuthBloc _authProvider;
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
      _ConnectivityProvider =
          Provider.of<ConnectivityBloc>(context, listen: false);
      _authProvider = Provider.of<AuthBloc>(context, listen: false);
      _providersInitialized = true;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || !_providersInitialized) return;

    // When app resumes, refresh data if needed
    if (state == AppLifecycleState.resumed) {
      _ConnectivityProvider.checkConnectivity();
      if (_ConnectivityProvider.shouldRefresh &&
          _authProvider.isAuthenticated) {
        // Refresh data from server - but not profile data (will be refreshed on demand)
        _ConnectivityProvider.markRefreshed();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
