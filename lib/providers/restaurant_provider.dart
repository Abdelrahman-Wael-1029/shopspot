import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shopspot/providers/connectivity_provider.dart';
import 'package:shopspot/services/database_service.dart';
import 'package:shopspot/utils/app_colors.dart';
import '../models/restaurant.dart';
import '../services/api_service.dart';

class RestaurantProvider with ChangeNotifier {
  List<Restaurant> _restaurants = [];
  List<Restaurant> _allRestaurants = [];

  // Cache for product-restaurant relationships
  Map<int, List<Restaurant>> _productRestaurantsCache = {};

  // Track which products are currently loading
  Map<int, bool> _loadingProductRestaurants = {};

  bool _isLoading = false;
  String? _errorProducts;
  bool _isCacheInitialized = false;

  List<Restaurant> get restaurants => _restaurants;
  bool get isLoading => _isLoading;
  String? get errorProducts => _errorProducts;

  RestaurantProvider();

  // Initialize cache from Hive storage
  Future<void> _initializeCache() async {
    if (_isCacheInitialized) return;

    _productRestaurantsCache =
        await DatabaseService.getProductRestaurantCache();
    _isCacheInitialized = true;
    notifyListeners();
    debugPrint(
        'Restaurant provider cache initialized with ${_productRestaurantsCache.length} entries');
  }

  Future<void> fetchRestaurants(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final connectivityProvider =
          Provider.of<ConnectivityProvider>(context, listen: false);
      final shouldLoadFromServer =
          connectivityProvider.isOnline && connectivityProvider.shouldRefresh;

      if (shouldLoadFromServer) {
        final result = await ApiService.getRestaurants();

        if (result['success']) {
          _allRestaurants = result['restaurants'];
          _restaurants = _allRestaurants;

          await DatabaseService.cacheRestaurants(_allRestaurants);

          // We don't clear the product-restaurants cache here
          // as it might still be useful even with new restaurant data
        } else {
          throw Exception(result['message']);
        }
        // Mark as refreshed
        connectivityProvider.markRefreshed();
      } else {
        debugPrint('load restaurants from cache');
        if (!connectivityProvider.isOnline) {
          // Show toast if we're offline
          Fluttertoast.showToast(
            msg: "You are offline. Showing cached Restaurants data.",
            backgroundColor: AppColors.error,
          );
        }
        await Future.delayed(const Duration(microseconds: 500));
        _allRestaurants = await DatabaseService.getCachedRestaurants();
        _restaurants = _allRestaurants;
      }
    } catch (e) {
      debugPrint(e.toString());
      Fluttertoast.showToast(
        msg: "Unable to fetch Restaurants. Showing cached data.",
        backgroundColor: AppColors.error,
      );
      _allRestaurants = await DatabaseService.getCachedRestaurants();
      _restaurants = _allRestaurants;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _restaurants = _allRestaurants
        .where((r) => r.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    notifyListeners();
  }

  // New method to check if restaurants are being loaded for a specific product
  bool isLoadingProductRestaurants(int productId) {
    return _loadingProductRestaurants[productId] ?? false;
  }

  // New method to get already loaded restaurants without triggering a new load
  List<Restaurant>? getLoadedRestaurantsForProduct(int productId) {
    return _productRestaurantsCache[productId];
  }

  // New method to trigger loading restaurants for a product
  void loadRestaurantsForProduct(BuildContext context, int productId) {
    // Check if we have already loaded this product's restaurants
    if (_productRestaurantsCache.containsKey(productId)) {
      debugPrint('Already have restaurants for product $productId');
      return;
    }

    // Check if we're already loading restaurants for this product
    if (_loadingProductRestaurants[productId] == true) {
      debugPrint('Already loading restaurants for product $productId');
      return;
    }

    // Start loading restaurants
    _loadingProductRestaurants[productId] = true;
    notifyListeners();

    getRestaurantsForProduct(context, productId).then((_) {
      _loadingProductRestaurants[productId] = false;
      notifyListeners();
    });
  }

  // Original method kept for compatibility
  Future<List<Restaurant>> getRestaurantsForProduct(
      BuildContext context, int productId) async {
    if (!_isCacheInitialized) {
      await _initializeCache();
    }

    final connectivityProvider =
        Provider.of<ConnectivityProvider>(context, listen: false);
    final shouldLoadFromServer =
        connectivityProvider.isOnline && connectivityProvider.shouldRefresh;

    if (!shouldLoadFromServer) {
      if (_productRestaurantsCache.containsKey(productId)) {
        debugPrint('Using cached restaurants for product $productId');
        return _productRestaurantsCache[productId]!;
      }
    }

    debugPrint('Fetching restaurants for product $productId from API');

    try {
      final result = await ApiService.getProductRestaurants(productId);

      if (result['success']) {
        final restaurants = result['restaurants'] as List<Restaurant>;

        _productRestaurantsCache[productId] = restaurants;

        await DatabaseService.cacheProductRestaurantRelations(
            _productRestaurantsCache);
        // Mark as refreshed
        connectivityProvider.markRefreshed();
        notifyListeners();
        return restaurants;
      } else {
        _errorProducts = result['message'];
        notifyListeners();
        return [];
      }
    } catch (e) {
      _errorProducts = e.toString();
      notifyListeners();
      return [];
    }
  }

  void clearSearch() {
    _restaurants = _allRestaurants;
    notifyListeners();
  }

  // Method to clear the restaurant-product cache
  Future<void> clearProductRestaurantsCache() async {
    _productRestaurantsCache.clear();
    _loadingProductRestaurants.clear();
    await DatabaseService.clearProductRestaurantCache();
    notifyListeners();
    debugPrint('Product-Restaurant cache cleared');
  }
}
