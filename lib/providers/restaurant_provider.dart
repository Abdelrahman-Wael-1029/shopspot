import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shopspot/models/restaurant_product_model.dart';
import 'package:shopspot/providers/location_provider.dart';
import 'package:provider/provider.dart';
import 'package:shopspot/providers/product_provider.dart';
import 'package:shopspot/models/restaurant_model.dart';
import 'package:shopspot/services/api_service.dart';
import 'package:shopspot/services/database_service.dart';
import 'package:shopspot/services/connectivity_service.dart';

class RestaurantProvider extends ChangeNotifier {
  List<Restaurant> _restaurants = [];
  final Map<int, bool> _isLoadingProductRestaurants = {};
  bool _isLoading = false;
  String? _error;
  String? _productsError;
  bool _hasBeenInitialized = false;

  List<Restaurant> get restaurants => _restaurants;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get productsError => _productsError;
  bool get hasBeenInitialized => _hasBeenInitialized;

  // Set loading state manually
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Initialize provider and load restaurants with context awareness
  Future<void> initialize(BuildContext context) async {
    await fetchData(context);
  }

  // Fetch restaurants with context awareness
  Future<bool> fetchData(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    // Extract connectivity service
    final connectivityService =
        Provider.of<ConnectivityService>(context, listen: false);

    // Always check cached restaurants availability first
    final cachedRestaurants = DatabaseService.getAllRestaurants();
    final hasCachedData = cachedRestaurants.isNotEmpty;

    // Always check server availability with a short timeout
    final serverIsAvailable = await ApiService.isApiAccessible();
    Map<String, dynamic> result = {};

    try {
      // SERVER DATA NEEDED: If we should use server data and server is available
      if (serverIsAvailable) {
        // Reset server status since it's available
        connectivityService.resetServerStatus();
        result = await ApiService.getRestaurants();

        if (result['success']) {
          // Convert API response to Restaurant objects
          final List<dynamic> restaurantsData = result['restaurants'];
          final List<Restaurant> serverRestaurants = restaurantsData
              .map((restaurantData) => Restaurant.fromJson(restaurantData))
              .toList();

          // Save to database and update state
          await DatabaseService.clearDatabase();
          await DatabaseService.saveRestaurants(serverRestaurants);
          _restaurants = serverRestaurants;
          _error = null;

          // Mark as refreshed if connectivity service is available
          connectivityService.markRefreshed();

          // Update location provider with new restaurants
          if (context.mounted) refreshRestaurantsDistances(context);

          return true;
        }
      }
    } finally {
      if (!serverIsAvailable || (serverIsAvailable && !result['success'])) {
        if (hasCachedData) {
          _restaurants = cachedRestaurants;
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
              ? 'Unable to connect to the server. Please try again later.'
              : 'You are offline. Please check your connection.';
        }
      }

      // Update location provider with new restaurants
      if (context.mounted) refreshRestaurantsDistances(context);

      _isLoading = false;
      _hasBeenInitialized = true;
      notifyListeners();
    }

    return false;
  }

  // Refresh restaurants from API
  Future<bool> refreshRestaurants(BuildContext context) async {
    Provider.of<ProductProvider>(context, listen: false).fetchData(context);
    return await fetchData(context);
  }

  // Refresh restaurants distances
  Future<void> refreshRestaurantsDistances(BuildContext context) async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    for (var restaurant in _restaurants) {
      await locationProvider.getDistance(restaurant);
    }
  }

  // Search restaurants by name
  List<Restaurant> searchRestaurants(String query) {
    if (query.isEmpty) {
      return _restaurants;
    }

    final searchTerm = query.toLowerCase();
    return _restaurants
        .where((restaurant) =>
            restaurant.name.toLowerCase().contains(searchTerm) ||
            restaurant.description.toLowerCase().contains(searchTerm))
        .toList();
  }

  // Update the favorite status of a restaurant in the list
  Future<void> updateFavoriteStatus(int restaurantId, bool isFavorite) async {
    await DatabaseService.changeFavoriteState(restaurantId, isFavorite);

    // Find the restaurant in the list
    final restaurantIndex =
        _restaurants.indexWhere((restaurant) => restaurant.id == restaurantId);

    // If the restaurant exists in our list, update its favorite status
    if (restaurantIndex != -1) {
      _restaurants[restaurantIndex].isFavorite = isFavorite;
    }

    // Always notify listeners to ensure UI is updated
    notifyListeners();
  }

  // Get the loading state for a specific restaurant
  bool isLoadingProductRestaurants(int productId) {
    return _isLoadingProductRestaurants[productId] ?? false;
  }

  // Get a restaurant by ID
  Future<List<Restaurant>> getRestaurantsByProductId(
      BuildContext context, int productId) async {
    _isLoadingProductRestaurants[productId] = true;
    notifyListeners();

    final connectivityService =
        Provider.of<ConnectivityService>(context, listen: false);
    final restaurants = DatabaseService.getRestaurantsByProductId(productId);
    if (restaurants.isNotEmpty) {
      _productsError = null;
      _isLoadingProductRestaurants[productId] = false;
      notifyListeners();
      return restaurants;
    }

    // If no restaurant found, get it from the API
    final serverIsAvailable = await ApiService.isApiAccessible();
    Map<String, dynamic> result = {};

    try {
      // SERVER DATA NEEDED: If we should use server data and server is available
      if (serverIsAvailable) {
        // Reset server status since it's available
        connectivityService.resetServerStatus();
        result = await ApiService.getRestaurantsByProductId(productId);

        if (result['success']) {
          // Convert API response to Restaurant objects
          final List<dynamic> restaurantsData = result['restaurants'];
          final List<Restaurant> serverRestaurants = restaurantsData
              .map((restaurantData) => Restaurant.fromJson(restaurantData))
              .toList();
          final List<RestaurantProduct> relations = restaurantsData
              .map((restaurantData) =>
                  RestaurantProduct.fromJson(restaurantData['pivot']))
              .toList();

          // Save to database and update state
          await DatabaseService.saveRestaurantProducts(relations);

          // Mark as refreshed if connectivity service is available
          connectivityService.markRefreshed();

          _productsError = null;
          return serverRestaurants;
        }
      }
    } finally {
      if (!serverIsAvailable || (serverIsAvailable && !result['success'])) {
        _productsError = connectivityService.isOnline
            ? 'Unable to connect to the server. Please try again later.'
            : 'You are offline. Please check your connection.';
      }
      _isLoadingProductRestaurants[productId] = false;
      notifyListeners();
    }
    return [];
  }
}
