import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopspot/cubit/product_cubit/product_state.dart';
import 'package:shopspot/models/restaurant_product_model.dart';
import 'package:shopspot/models/product_model.dart';
import 'package:shopspot/services/api_service.dart';
import 'package:shopspot/services/database_service.dart';
import 'package:shopspot/services/connectivity_service/connectivity_service.dart';

class ProductCubit extends Cubit<ProductState> {
  List<Product> _products = [];

  ProductCubit() : super(ProductInitial());

  List<Product> get products => _products;

  // Fetch products with context awareness
  Future<void> fetchData(BuildContext context) async {
    emit(ProductLoading());
    final connectivityService = context.read<ConnectivityService>();

    // Always check cached restaurants availability first
    List<Product> cachedProducts = DatabaseService.getAllProducts();
    final hasCachedData = cachedProducts.isNotEmpty;

    // Always check server availability with a short timeout
    final serverIsAvailable = await ApiService.isApiAccessible();
    Map<String, dynamic> result = {};

    try {
      // SERVER DATA NEEDED: If we should use server data and server is available
      if (serverIsAvailable) {
        // Reset server status since it's available
        connectivityService.resetServerStatus();
        result = await ApiService.getProducts();

        if (result['success']) {
          // Convert API response to Product objects
          final List<Product> serverProducts = [];
          final List<RestaurantProduct> relations = [];

          for (var productData in List<dynamic>.from(result['products'])) {
            // Add the product
            serverProducts.add(Product.fromJson(productData));

            // Process pivot relationships if they exist
            for (var relationData in List<dynamic>.from(productData['pivots'])) {
              relations.add(RestaurantProduct.fromJson(relationData));
            }
          }

          // Clear the database and save new data
          await DatabaseService.deleteProductsWithRelations();
          await DatabaseService.saveRelations(relations);
          await DatabaseService.saveProducts(serverProducts);

          // Mark as refreshed if connectivity service is available
          connectivityService.markRefreshed();
          _products = serverProducts;
          emit(ProductLoaded());
        }
      }
    } finally {
      if (!serverIsAvailable || (serverIsAvailable && !result['success'])) {
        if (hasCachedData) {
          _products = cachedProducts;
          emit(ProductLoaded());
        } else {
          emit(ProductError(connectivityService.isOnline
              ? 'Unable to connect to the server. Please check your connection.'
              : 'You are offline. Please check your connection.'));
        }
      }
    }
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
    return filterProducts(_products, query);
  }
}
