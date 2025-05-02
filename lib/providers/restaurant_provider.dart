import 'package:flutter/foundation.dart';
import '../models/restaurant.dart';
import '../services/api_service.dart';

class RestaurantProvider with ChangeNotifier {
  List<Restaurant> _restaurants = [];
  List<Restaurant> _allRestaurants = [];

  bool _isLoading = false;
  String? _error;
  String? _errorProducts;

  List<Restaurant> get restaurants => _restaurants;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorProducts => _errorProducts;

  Future<void> fetchRestaurants() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.getRestaurants();

      if (result['success']) {
        _allRestaurants = result['restaurants'];
        _restaurants = _allRestaurants;
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

  void search(String query) {
    _restaurants = _allRestaurants
        .where((r) => r.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    notifyListeners();
  }

  Future<List<Restaurant>> getRestaurantsForProduct(int productId) async {
    try {
      final result = await ApiService.getProductRestaurants(productId);

      if (result['success']) {
        return result['restaurants'];
      } else {
        _errorProducts = result['message'];
        notifyListeners();
        return [];
      }
    } catch (e) {
      notifyListeners();
      return [];
    }
  }

  void clearSearch() {
    _restaurants = _allRestaurants;
    notifyListeners();
  }
}
