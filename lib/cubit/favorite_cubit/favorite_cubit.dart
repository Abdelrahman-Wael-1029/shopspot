import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopspot/cubit/favorite_cubit/favorite_state.dart';
import 'package:shopspot/cubit/restaurant_cubit/restaurant_cubit.dart';
import 'package:shopspot/cubit/restaurant_cubit/restaurant_state.dart';
import 'package:shopspot/models/restaurant_model.dart';
import 'package:shopspot/services/api_service.dart';
import 'package:shopspot/services/database_service.dart';
import 'package:shopspot/services/connectivity_service/connectivity_service.dart';

class FavoriteCubit extends Cubit<FavoriteState> {
  List<Restaurant> _favorites = [];

  FavoriteCubit() : super(FavoriteInitial());

  List<Restaurant> get favorites => _favorites;

  // Initialize cubit and load favorites
  Future<void> initialize(BuildContext context) async {
    final RestaurantCubit restaurantCubit = context.read<RestaurantCubit>();

    // Set loading state to match the restaurant cubit
    emit(FavoriteLoading());
    if (restaurantCubit.state is RestaurantLoading) {
      late StreamSubscription subscription;

      subscription = restaurantCubit.stream.listen((restaurantState) {
        if (restaurantState is RestaurantLoaded && state is FavoriteLoading) {
          _loadFavoritesFromDatabase();
          subscription.cancel();
        }
      });
    } else if (restaurantCubit.state is RestaurantLoaded) {
      _loadFavoritesFromDatabase();
    }
  }

  // Helper method to load favorites from database
  void _loadFavoritesFromDatabase() {
    _favorites = DatabaseService.getFavoriteRestaurants();
    emit(FavoriteLoaded());
  }

  // Clear all favorites (call this on logout)
  Future<void> clearAllFavorites() async {
    _favorites = [];
    await DatabaseService.clearAllFavorites();
    emit(FavoriteInitial());
  }

  // Add a restaurant to favorites
  Future<bool> addToFavorites(
      Restaurant restaurant, BuildContext context) async {
    // Extract ConnectivityService early if context is provided
    final connectivityService = context.read<ConnectivityService>();

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

      emit(FavoriteLoaded());
      success = true;
    } catch (e) {
      // Mark server unavailable if connectivity service exists
      connectivityService.setServerUnavailable();
      emit(FavoriteError('Something went wrong.'));
      return false;
    }

    return success;
  }

  // Remove a restaurant from favorites
  Future<bool> removeFromFavorites(
      Restaurant restaurant, BuildContext context) async {
    // Extract ConnectivityService early if context is provided
    final connectivityService = context.read<ConnectivityService>();

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
      emit(FavoriteLoaded());
      success = true;
    } catch (e) {
      // Mark server unavailable if connectivity service exists
      connectivityService.setServerUnavailable();
      emit(FavoriteError('Something went wrong.'));
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
