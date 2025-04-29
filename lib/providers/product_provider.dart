import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<Product> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProductsForRestaurant(int restaurantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.getRestaurantProducts(restaurantId);
      
      if (result['success']) {
        _products = result['products'];
        _isLoading = false;
        notifyListeners();
      } else {
        _isLoading = false;
        _error = result['message'];
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.searchProducts(query);
      
      if (result['success']) {
        _searchResults = result['products'];
        _isLoading = false;
        notifyListeners();
      } else {
        _isLoading = false;
        _error = result['message'];
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Product?> getProductDetailsForRestaurant(int restaurantId, int productId) async {
    try {
      final result = await ApiService.getProductDetailsForRestaurant(restaurantId, productId);
      
      if (result['success']) {
        return result['product'];
      } else {
        _error = result['message'];
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
} 