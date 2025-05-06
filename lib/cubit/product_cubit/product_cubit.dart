import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shopspot/cubit/product_cubit/product_state.dart';
import 'package:shopspot/models/restaurant_product_model.dart';
import 'package:shopspot/models/product_model.dart';
import 'package:shopspot/services/api_service.dart';
import 'package:shopspot/services/database_service.dart';
import 'package:shopspot/services/connectivity_service/connectivity_service.dart';

class ProductCubit extends Cubit<ProductState> {
  List<Product> _allProducts = [];

  ProductCubit() : super(ProductInitial());

  List<Product> get allProducts => _allProducts;

  // Fetch products with context awareness
  Future<List<Product>> fetchData(BuildContext context,
      [int? restaurantId]) async {
    emit(ProductLoading());

    // Extract connectivity service
    final connectivityService = context.read<ConnectivityService>();

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
          emit(ProductLoaded());

          // Mark as refreshed if connectivity service is available
          connectivityService.markRefreshed();
          return serverProducts;
        }
      }
    } finally {
      if (!serverIsAvailable || (serverIsAvailable && !result['success'])) {
        if (restaurantId == null && _allProducts.isNotEmpty) {
          emit(ProductLoaded());
        } else if (restaurantId != null && hasCachedData) {
          emit(ProductLoaded());

          // Show toast if connectivity service available
          if (context.mounted) {
            Fluttertoast.showToast(
              msg: 'Unable to connect to the server. Using cached data.',
              backgroundColor: Colors.orange,
            );
          }
        } else {
          emit(ProductError(connectivityService.isOnline
              ? 'Unable to connect to the server. Please check your connection.'
              : 'You are offline. Please check your connection.'));
        }
      }
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
