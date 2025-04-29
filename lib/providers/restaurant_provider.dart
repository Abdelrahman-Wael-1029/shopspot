import 'package:flutter/foundation.dart';
import '../models/restaurant.dart';
import '../services/api_service.dart';

class RestaurantProvider with ChangeNotifier {
  List<Restaurant> _restaurants = [];
  bool _isLoading = false;
  String? _error;

  List<Restaurant> get restaurants => _restaurants;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRestaurants() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.getRestaurants();
      
      if (result['success']) {
        _restaurants = result['restaurants'];
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

  Future<List<Restaurant>> getRestaurantsForProduct(int productId) async {
    try {
      final result = await ApiService.getProductRestaurants(productId);
      
      if (result['success']) {
        return result['restaurants'];
      } else {
        _error = result['message'];
        notifyListeners();
        return [];
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }
} 