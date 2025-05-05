import 'package:flutter/material.dart';
import 'package:shopspot/providers/restaurant_provider.dart';
import 'package:provider/provider.dart';
import 'package:shopspot/models/restaurant_model.dart';
import 'package:shopspot/services/api_service.dart';
import 'package:shopspot/services/database_service.dart';
import 'package:shopspot/services/connectivity_service.dart';

class FavoriteProvider extends ChangeNotifier {
  List<Restaurant> _favorites = [];
  bool _isLoading = false;
  String? _error;
  bool _hasBeenInitialized = false; // Track if we've loaded favorites before

  List<Restaurant> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasBeenInitialized => _hasBeenInitialized;

  // Initialize provider and load favorites
  Future<void> initialize(BuildContext context) async {
    final RestaurantProvider restaurantProvider =
        Provider.of<RestaurantProvider>(context, listen: false);

    // Set loading state to match the restaurant provider
    _isLoading = true;
    notifyListeners();

    // If restaurant provider is still loading, wait for it to complete
    if (restaurantProvider.isLoading) {
      // Listen for changes in the restaurant provider's loading state
      restaurantProvider.addListener(() {
        // When restaurant provider finishes loading, load favorites
        if (!restaurantProvider.isLoading && _isLoading) {
          _loadFavoritesFromDatabase();
        }
      });
    } else {
      // Restaurant provider already loaded, load favorites immediately
      _loadFavoritesFromDatabase();
    }
  }

  // Helper method to load favorites from database
  void _loadFavoritesFromDatabase() {
    _favorites = DatabaseService.getFavoriteRestaurants();
    _hasBeenInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  // Clear all favorites (call this on logout)
  Future<void> clearAllFavorites() async {
    _favorites = [];
    _hasBeenInitialized = false;
    await DatabaseService.clearAllFavorites();
    notifyListeners();
  }

  // Add a restaurant to favorites
  Future<bool> addToFavorites(
      Restaurant restaurant, BuildContext context) async {
    // Extract ConnectivityService early if context is provided
    final connectivityService =
        Provider.of<ConnectivityService>(context, listen: false);

    // Make a copy of the restaurant to avoid modifying the original
    final updatedRestaurant = Restaurant.from(restaurant);
    updatedRestaurant.isFavorite = true;

    // For server operations
    bool success = false;

    try {
      // Attempt to add to favorites on server
      final result = await ApiService.addToFavorites(restaurant.id);

      // Reset server status when successful
      connectivityService.resetServerStatus();

      if (!result['success']) {
        // Handle error but keep local change
        return false;
      }

      await DatabaseService.changeFavoriteState(restaurant.id, true);

      // Now update local state
      _favorites.add(updatedRestaurant);

      notifyListeners();
      success = true;
    } catch (e) {
      // Mark server unavailable if connectivity service exists
      connectivityService.setServerUnavailable();
      return false;
    }

    return success;
  }

  // Remove a restaurant from favorites
  Future<bool> removeFromFavorites(
      Restaurant restaurant, BuildContext context) async {
    // Extract ConnectivityService early if context is provided
    final connectivityService =
        Provider.of<ConnectivityService>(context, listen: false);

    // Make a copy of the restaurant to avoid modifying the original
    final updatedRestaurant = Restaurant.from(restaurant);
    updatedRestaurant.isFavorite = false;

    bool success = false;

    try {
      // Attempt to remove from favorites on server
      final result = await ApiService.removeFromFavorites(restaurant.id);

      // Reset server status when successful
      connectivityService.resetServerStatus();

      if (!result['success']) {
        // Handle error but keep local change
        return false;
      }

      // Always force remove from database first
      await DatabaseService.changeFavoriteState(restaurant.id, false);

      // Now update local state
      _favorites.remove(restaurant);
      notifyListeners();
      success = true;
    } catch (e) {
      // Mark server unavailable if connectivity service exists
      connectivityService.setServerUnavailable();
      return false;
    }

    return success;
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(
      Restaurant restaurant, BuildContext context) async {
    if (restaurant.isFavorite) {
      return removeFromFavorites(restaurant, context);
    } else {
      return addToFavorites(restaurant, context);
    }
  }

  // Search restaurants by name
  List<Restaurant> searchFavorites(String query) {
    if (query.isEmpty) {
      return _favorites;
    }

    final searchTerm = query.toLowerCase();
    return _favorites
        .where((restaurant) =>
            restaurant.name.toLowerCase().contains(searchTerm) ||
            restaurant.description.toLowerCase().contains(searchTerm))
        .toList();
  }
}
