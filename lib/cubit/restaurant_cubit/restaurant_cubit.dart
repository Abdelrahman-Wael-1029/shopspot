import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shopspot/models/restaurant_product_model.dart';
import 'package:shopspot/models/restaurant_model.dart';
import 'package:shopspot/services/api_service.dart';
import 'package:shopspot/services/connectivity_service/connectivity_service.dart';
import 'package:shopspot/services/database_service.dart';
import 'package:shopspot/cubit/location_cubit/location_cubit.dart';
import 'package:shopspot/cubit/product_cubit/product_cubit.dart';
import 'package:shopspot/utils/utils.dart';

import 'restaurant_state.dart';

class RestaurantCubit extends Cubit<RestaurantState> {
  RestaurantCubit() : super(RestaurantInitial());

  List<Restaurant> _restaurants = [];
  final Map<int, bool> _isLoadingProductRestaurants = {};
  String? _productsError;
  bool _hasBeenInitialized = false;

  List<Restaurant> get restaurants => _restaurants;
  String? get productsError => _productsError;
  bool get hasBeenInitialized => _hasBeenInitialized;

  Future<void> initialize(BuildContext context) async {
    await fetchData(context);
  }

  Future<bool> fetchData(BuildContext context) async {
    emit(RestaurantLoading());

    final connectivityService = context.read<ConnectivityService>();

    final cachedRestaurants = DatabaseService.getAllRestaurants();
    final hasCachedData = cachedRestaurants.isNotEmpty;

    final serverIsAvailable = await ApiService.isApiAccessible();
    Map<String, dynamic> result = {};

    try {
      if (serverIsAvailable) {
        connectivityService.resetServerStatus();
        result = await ApiService.getRestaurants();

        if (result['success']) {
          final List<dynamic> restaurantsData = result['restaurants'];
          final List<Restaurant> serverRestaurants = restaurantsData
              .map((restaurantData) => Restaurant.fromJson(restaurantData))
              .toList();

          await DatabaseService.clearDatabase();
          await DatabaseService.saveRestaurants(serverRestaurants);
          _restaurants = serverRestaurants;

          connectivityService.markRefreshed();

          if (context.mounted) refreshRestaurantsDistances(context);

          _hasBeenInitialized = true;
          emit(RestaurantLoaded());
          return true;
        }
      }
    } finally {
      if (!serverIsAvailable || (serverIsAvailable && !result['success'])) {
        if (hasCachedData) {
          _restaurants = cachedRestaurants;

          if (context.mounted) {
            Fluttertoast.showToast(
              msg: 'Unable to connect to the server. Using cached data.',
              backgroundColor: getWarningColor(context),
            );
          }
        } else {
          emit(RestaurantError(connectivityService.isOnline
              ? 'Unable to connect to the server. Please try again later.'
              : 'You are offline. Please check your connection.'));
        }
      }

      if (context.mounted) refreshRestaurantsDistances(context);

      _hasBeenInitialized = true;
      emit(RestaurantLoaded());
    }

    return false;
  }

  Future<bool> refreshRestaurants(BuildContext context) async {
    context.read<ProductCubit>().fetchData(context);
    return await fetchData(context);
  }

  Future<void> refreshRestaurantsDistances(BuildContext context) async {
    final locationCubit = context.read<LocationCubit>();
    for (var restaurant in _restaurants) {
      await locationCubit.getDistance(restaurant);
    }
  }

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

  Future<void> updateFavoriteStatus(int restaurantId, bool isFavorite) async {
    await DatabaseService.changeFavoriteState(restaurantId, isFavorite);

    final restaurantIndex =
        _restaurants.indexWhere((restaurant) => restaurant.id == restaurantId);

    if (restaurantIndex != -1) {
      _restaurants[restaurantIndex].isFavorite = isFavorite;
    }

    emit(RestaurantLoaded());
  }

  bool isLoadingProductRestaurants(int productId) {
    return _isLoadingProductRestaurants[productId] ?? false;
  }

  Future<List<Restaurant>> getRestaurantsByProductId(
      BuildContext context, int productId) async {
    _isLoadingProductRestaurants[productId] = true;
    emit(RestaurantLoading());

    final connectivityService = context.read<ConnectivityService>();
    final restaurants = DatabaseService.getRestaurantsByProductId(productId);
    if (restaurants.isNotEmpty) {
      _productsError = null;
      _isLoadingProductRestaurants[productId] = false;
      emit(RestaurantLoaded());
      return restaurants;
    }

    final serverIsAvailable = await ApiService.isApiAccessible();
    Map<String, dynamic> result = {};

    try {
      if (serverIsAvailable) {
        connectivityService.resetServerStatus();
        result = await ApiService.getRestaurantsByProductId(productId);

        if (result['success']) {
          final List<dynamic> restaurantsData = result['restaurants'];
          final List<Restaurant> serverRestaurants = restaurantsData
              .map((restaurantData) => Restaurant.fromJson(restaurantData))
              .toList();
          final List<RestaurantProduct> relations = restaurantsData
              .map((restaurantData) =>
                  RestaurantProduct.fromJson(restaurantData['pivot']))
              .toList();

          await DatabaseService.saveRestaurantProducts(relations);

          connectivityService.markRefreshed();

          _productsError = null;
          _isLoadingProductRestaurants[productId] = false;
          emit(RestaurantLoaded());
          return serverRestaurants;
        }
      }
    } finally {
      if (!serverIsAvailable || (serverIsAvailable && !result['success'])) {
        _productsError = connectivityService.isOnline
            ? 'Unable to connect to the server. Please try again later.'
            : 'You are offline. Please check your connection.';
        emit(RestaurantError(_productsError!));
      }

      _isLoadingProductRestaurants[productId] = false;
      emit(RestaurantLoaded());
    }

    return [];
  }

  Future<void> refreshData(BuildContext context) async {
    final connectivityService = context.read<ConnectivityService>();

    emit(RestaurantLoading());

    // Always use server data when explicitly refreshing
    bool success = false;

    // Only try to refresh from server if we're online
    if (connectivityService.isOnline) {
      success = await refreshRestaurants(context);

      // Mark that we've refreshed the data
      if (success) {
        connectivityService.markRefreshed();
      }
    } else {
      emit(RestaurantError('You are offline. Please check your connection.'));

      // Check if still mounted before accessing context
      if (!context.mounted) return;

      // Show toast or alert that we're offline
      Fluttertoast.showToast(
        msg: 'You are offline. Please check your connection.',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }
}
