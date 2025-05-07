import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shopspot/models/restaurant_model.dart';
import 'package:shopspot/services/api_service.dart';
import 'package:shopspot/services/connectivity_service/connectivity_service.dart';
import 'package:shopspot/services/database_service.dart';
import 'package:shopspot/cubit/location_cubit/location_cubit.dart';
import 'package:shopspot/cubit/product_cubit/product_cubit.dart';
import 'package:shopspot/utils/color_scheme_extension.dart';

import 'restaurant_state.dart';

class RestaurantCubit extends Cubit<RestaurantState> {
  RestaurantCubit() : super(RestaurantInitial());

  List<Restaurant> _restaurants = [];
  String? _productsError;

  List<Restaurant> get restaurants => _restaurants;
  String? get productsError => _productsError;

  Future<void> initialize(BuildContext context) async {
    await fetchData(context);
  }

  Future<void> fetchData(BuildContext context) async {
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
          emit(RestaurantLoaded());
        }
      }
    } finally {
      if (!serverIsAvailable || (serverIsAvailable && !result['success'])) {
        if (hasCachedData) {
          if (context.mounted) refreshRestaurantsDistances(context);
          emit(RestaurantLoaded());
          _restaurants = cachedRestaurants;

          if (context.mounted) {
            Fluttertoast.showToast(
              msg: 'Unable to connect to the server. Using cached data.',
              backgroundColor: Theme.of(context).colorScheme.warning,
              textColor: Theme.of(context).colorScheme.onWarning,
            );
          }
        } else {
          emit(RestaurantError(connectivityService.isOnline
              ? 'Unable to connect to the server. Please try again later.'
              : 'You are offline. Please check your connection.'));
        }
      }
      if (context.mounted) refreshRestaurantsDistances(context);
    }
  }

  Future<void> refreshRestaurants(BuildContext context) async {
    await context.read<ProductCubit>().fetchData(context);
    if (context.mounted) await fetchData(context);
  }

  Future<void> refreshRestaurantsDistances(BuildContext context) async {
    final locationCubit = context.read<LocationCubit>();
    for (var restaurant in _restaurants) {
      await locationCubit.getDistance(restaurant);
    }
  }

  Future<void> refreshData(BuildContext context) async {
    final connectivityService = context.read<ConnectivityService>();

    // Only try to refresh from server if we're online
    if (connectivityService.isOnline) {
      await refreshRestaurants(context);
    } else {
      // Show toast or alert that we're offline
      Fluttertoast.showToast(
        msg: 'You are offline. Please check your connection.',
        backgroundColor: Theme.of(context).colorScheme.error,
        textColor: Theme.of(context).colorScheme.onError,
      );
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
}
