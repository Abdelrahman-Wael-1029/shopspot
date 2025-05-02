import 'package:flutter/foundation.dart';
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
  String? _errorRestaurant;

  List<Product> get products => _products;
  List<Product> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get errorRestaurant => _errorRestaurant;

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

  Future<void> fetchProductsForRestaurant(int restaurantId) async {
    _isLoading = true;
    _errorRestaurant = null;
    notifyListeners();

    try {
      final result = await ApiService.getRestaurantProducts(restaurantId);
      if (result['success']) {
        _products = result['products'];
        _isLoading = false;
        notifyListeners();
      } else {
        _isLoading = false;
        _errorRestaurant = result['message'];
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _errorRestaurant =
          'Unable to connect to the server. Please try again later.';
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
