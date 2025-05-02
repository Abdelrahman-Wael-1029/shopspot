import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shopspot/providers/connectivity_provider.dart';
import 'package:shopspot/services/database_service.dart';
import 'package:shopspot/utils/app_colors.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _allProducts = [];
  List<Product> _searchResults = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  List<Product> get searchResults => _searchResults;
  bool get isLoading => _isLoading;

  Future<void> fetchProducts(context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final connectivityProvider =
          Provider.of<ConnectivityProvider>(context, listen: false);
      final shouldLoadFromServer =
          connectivityProvider.isOnline && connectivityProvider.shouldRefresh;

      if (shouldLoadFromServer) {
        final result = await ApiService.getProducts();
        if (result['success']) {
          _allProducts = result['products'];
          _searchResults = _allProducts;
          await DatabaseService.cacheProducts(
              _allProducts); // Cache products locally
          // Mark as refreshed
          connectivityProvider.markRefreshed();
        } else {
          throw Exception(result['message']);
        }
      } else {
        debugPrint('load products from cache');
        if (!connectivityProvider.isOnline) {
          // Show toast if we're offline
          Fluttertoast.showToast(
            msg: "You are offline. Showing cached Restaurants data.",
            backgroundColor: AppColors.error,
          );
        }
        await Future.delayed(const Duration(microseconds: 1500));

        // Display current cached data immediately if available
        _allProducts = await DatabaseService.getCachedProducts();
        _searchResults = _allProducts;
      }
    } catch (e) {
      debugPrint(e.toString());
      _allProducts = await DatabaseService.getCachedProducts();
      _searchResults = _allProducts;

      Fluttertoast.showToast(
        msg: "Unable to connect to the server. Showing cached data.",
        backgroundColor: AppColors.error,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProductsForRestaurant(
      BuildContext context, int restaurantId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final connectivityProvider =
          Provider.of<ConnectivityProvider>(context, listen: false);
      final shouldLoadFromServer =
          connectivityProvider.isOnline && connectivityProvider.shouldRefresh;

      // Load from cache
      _products =
          await DatabaseService.getCachedProductsForRestaurant(restaurantId);

      if (!shouldLoadFromServer) {
        debugPrint('load products from cache for restaurant $restaurantId');
        if (!connectivityProvider.isOnline) {
          // Show toast if we're offline
          Fluttertoast.showToast(
            msg: "You are offline. Showing cached Restaurants data.",
            backgroundColor: AppColors.error,
          );
        }
        await Future.delayed(const Duration(microseconds: 500));
        if (_products.isNotEmpty) return;
      }
      final result = await ApiService.getRestaurantProducts(restaurantId);
      if (result['success']) {
        _products = result['products'];

        // Cache data
        await DatabaseService.cacheProductsForRestaurant(
            restaurantId, _products);

        // Mark as refreshed
        connectivityProvider.markRefreshed();
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      debugPrint(e.toString());

      Fluttertoast.showToast(
        msg: "Unable to connect to server. Showing cached data.",
        backgroundColor: AppColors.error,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchProducts(String query) async {
    _searchResults = _allProducts
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    notifyListeners();
  }
}
