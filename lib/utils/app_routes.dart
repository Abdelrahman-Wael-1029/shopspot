import 'package:flutter/material.dart';
import 'package:shopspot/screens/auth/login_screen.dart';
import 'package:shopspot/screens/auth/signup_screen.dart';
import '../screens/restaurants_screen.dart';
import '../screens/products_screen.dart';
import '../screens/product_details_screen.dart';
import '../screens/search_screen.dart';
import '../screens/restaurant_map_screen.dart';
import '../screens/auth/profile_screen.dart';
import '../screens/home_screen.dart';

class AppRoutes {
  // Route names
  static const String home = '/home';
  static const String restaurants = '/restaurants';
  static const String products = '/products';
  static const String productDetails = '/product-details';
  static const String search = '/search';
  static const String restaurantMap = '/restaurant-map';
  static const String profile = '/profile';
  static const String login = '/login';
  static const String signup = '/signup';

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
      case restaurants:
        return MaterialPageRoute(
          builder: (_) => const RestaurantsScreen(),
        );

      case products:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ProductsScreen(
            restaurantId: args['restaurantId'] as int,
            restaurantName: args['restaurantName'] as String,
          ),
        );

      case productDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(
            productId: args['productId'] as int,
            restaurantId: args['restaurantId'] as int,
          ),
        );

      case search:
        return MaterialPageRoute(
          builder: (_) => const SearchScreen(),
        );

      case restaurantMap:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => RestaurantMapScreen(
            restaurants: args['restaurants'],
            productName: args['productName'] as String,
          ),
        );

      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
      case signup:
        return MaterialPageRoute(
          builder: (_) => const SignupScreen(),
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

  // Navigation helper methods
  static void navigateToProducts(BuildContext context, {
    required int restaurantId,
    required String restaurantName,
  }) {
    Navigator.pushNamed(
      context,
      products,
      arguments: {
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
      },
    );
  }

  static void navigateToProductDetails(BuildContext context, {
    required int productId,
    required int restaurantId,
  }) {
    Navigator.pushNamed(
      context,
      productDetails,
      arguments: {
        'productId': productId,
        'restaurantId': restaurantId,
      },
    );
  }

  static void navigateToRestaurantMap(BuildContext context, {
    required List<dynamic> restaurants,
    required String productName,
  }) {
    Navigator.pushNamed(
      context,
      restaurantMap,
      arguments: {
        'restaurants': restaurants,
        'productName': productName,
      },
    );
  }
} 