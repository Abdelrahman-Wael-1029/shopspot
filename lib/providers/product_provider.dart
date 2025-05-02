import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _allProducts = [];
  List<Product> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<Product> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.getProducts();
      if (result['success']) {
        _allProducts = result['products'];
        _searchResults = _allProducts;
        _isLoading = false;
        notifyListeners();
      } else {
        _isLoading = false;
        _error = result['message'];
        notifyListeners();
      }
    } catch (e) {
      print(e);
      _error = 'Unable to connect to the server. Please try again later.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
    _searchResults = _allProducts
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    notifyListeners();
  }
}
