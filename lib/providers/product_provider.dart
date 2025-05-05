import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shopspot/models/restaurant_product_model.dart';
import 'package:shopspot/models/product_model.dart';
import 'package:shopspot/services/api_service.dart';
import 'package:shopspot/services/database_service.dart';
import 'package:shopspot/services/connectivity_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _allProducts = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get allProducts => _allProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch products with context awareness
  Future<List<Product>> fetchData(BuildContext context,
      [int? restaurantId]) async {
    _isLoading = true;
    notifyListeners();

    // Extract connectivity service
    final connectivityService =
        Provider.of<ConnectivityService>(context, listen: false);

    // Always check cached restaurants availability first
    List<Product> cachedProducts = [];
    if (restaurantId != null) {
      cachedProducts = DatabaseService.getProductsByRestaurantId(restaurantId);
    }
    final hasCachedData = cachedProducts.isNotEmpty;

    // Always check server availability with a short timeout
    final serverIsAvailable = await ApiService.isApiAccessible();
    Map<String, dynamic> result = {};

    try {
      // SERVER DATA NEEDED: If we should use server data and server is available
      if (serverIsAvailable) {
        // Reset server status since it's available
        connectivityService.resetServerStatus();
        result = await ApiService.getProductsByRestaurantId(restaurantId);

        if (result['success']) {
          // Convert API response to Product objects
          final List<dynamic> productsData = result['products'];
          final List<Product> serverProducts = productsData
              .map((productData) => Product.fromJson(productData))
              .toList();

          if (restaurantId != null) {
            final List<RestaurantProduct> relations = productsData
                .map((productData) =>
                    RestaurantProduct.fromJson(productData['pivot']))
                .toList();
            await DatabaseService.deleteRestaurantRelations(restaurantId);
            await DatabaseService.saveRestaurantProducts(relations);
          } else {
            _allProducts = serverProducts;
          }

          // Save to database and update state
          await DatabaseService.saveProducts(serverProducts);
          _error = null;

          // Mark as refreshed if connectivity service is available
          connectivityService.markRefreshed();
          return serverProducts;
        }
      }
    } finally {
      if (!serverIsAvailable || (serverIsAvailable && !result['success'])) {
        if (restaurantId == null && _allProducts.isNotEmpty) {
          _error = null; // Don't show error if we have cached data
        } else if (restaurantId != null && hasCachedData) {
          _error = null; // Don't show error if we have cached data

          // Show toast if connectivity service available
          if (context.mounted) {
            Fluttertoast.showToast(
              msg: 'Unable to connect to the server. Using cached data.',
              backgroundColor: Colors.orange,
            );
          }
        } else {
          _error = connectivityService.isOnline
              ? 'Unable to connect to the server. Please check your connection.'
              : 'You are offline. Please check your connection.';
        }
      }
      _isLoading = false;
      notifyListeners();
    }
    return cachedProducts;
  }

  // Search products by name
  List<Product> filterProducts(List<Product> products, String query) {
    if (query.isEmpty) {
      return products;
    }

    final searchTerm = query.toLowerCase();
    return products
        .where((product) => product.name.toLowerCase().contains(searchTerm))
        .toList();
  }

  // Search all products by name
  List<Product> searchAllProducts(String query) {
    return filterProducts(_allProducts, query);
  }
}
