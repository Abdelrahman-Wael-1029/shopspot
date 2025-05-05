import 'package:flutter/material.dart';
import 'package:shopspot/main.dart';
import 'package:shopspot/screens/home_screen.dart';
import 'package:shopspot/screens/signup_screen.dart';
import 'package:shopspot/screens/login_screen.dart';
import 'package:shopspot/screens/profile_screen.dart';
import 'package:shopspot/screens/restaurants_list_screen.dart';
import 'package:shopspot/screens/restaurant_details_screen.dart';
import 'package:shopspot/screens/restaurants_map_screen.dart';
import 'package:shopspot/screens/products_list_screen.dart';
import 'package:shopspot/screens/product_details_screen.dart';
import 'package:shopspot/screens/products_search_screen.dart';
import 'package:shopspot/models/product_model.dart';
import 'package:shopspot/models/restaurant_model.dart';

class AppRoutes {
  static const String initial = '/';
  static const String home = '/home';
  static const String register = '/register';
  static const String login = '/login';
  static const String profile = '/profile';
  static const String restaurants = '/restaurants';
  static const String restaurantDetails = '/restaurant_details';
  static const String restaurantsMap = '/restaurants_map';
  static const String products = '/products';
  static const String productDetails = '/product_details';
  static const String productsSearch = '/products_search';

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initial:
        return MaterialPageRoute(
          builder: (_) => const AppLifecycleManager(
            child: InitScreen(),
          ),
        );
      case home:
        return MaterialPageRoute(
          builder: (_) => const AppLifecycleManager(
            child: HomeScreen(),
          ),
        );

      case register:
        return MaterialPageRoute(
          builder: (_) => const SignupScreen(),
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
      case profile:
        return MaterialPageRoute(
          builder: (_) => const AppLifecycleManager(
            child: ProfileScreen(),
          ),
        );

      case restaurants:
        return MaterialPageRoute(
          builder: (_) => AppLifecycleManager(
            child: RestaurantsListScreen(),
          ),
        );
      case restaurantDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => AppLifecycleManager(
            child: RestaurantDetailsScreen(
              restaurant: args['restaurant'] as Restaurant,
            ),
          ),
        );
      case restaurantsMap:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => AppLifecycleManager(
            child: RestaurantsMapScreen(
              restaurants: args['restaurants'],
              productName: args['productName'] as String,
            ),
          ),
        );

      case products:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => AppLifecycleManager(
            child: ProductsListScreen(
              restaurant: args['restaurant'] as Restaurant,
            ),
          ),
        );
      case productDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => AppLifecycleManager(
            child: ProductDetailsScreen(
              product: args['product'] as Product,
              restaurant: args['restaurant'] as Restaurant,
            ),
          ),
        );
      case productsSearch:
        return MaterialPageRoute(
          builder: (_) => const AppLifecycleManager(
            child: ProductsSearchScreen(),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
