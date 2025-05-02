import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shopspot/models/product.dart';
import 'package:shopspot/models/product_restaurant_cache.dart';
import 'package:shopspot/models/restaurant.dart';
import '../models/user_model.dart';

class DatabaseService {
  static const String _userBoxName = 'userBox';
  static const String _currentUserKey = 'currentUser';
  static const String _profileImageFolderName = 'profile_images';
  static const String _productsBox = 'products_box';
  static const String _restaurantsBox = 'restaurants_box';
  static const String _productRestaurantCacheBox =
      'product_restaurant_cache_box';
  static const String _productRestaurantCacheKey = 'product_restaurant_cache';
  static Box<User>? _userBox;

  /// Initialize Hive and open all boxes
  static Future<void> init() async {
    // Initialize Hive
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(RestaurantAdapter());
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(ProductRestaurantCacheAdapter());

    // Open boxes
    _userBox = await Hive.openBox<User>(_userBoxName);
    await Hive.openBox<Product>(_productsBox);
    await Hive.openBox<Restaurant>(_restaurantsBox);
    await Hive.openBox<ProductRestaurantCache>(_productRestaurantCacheBox);
  }

  /// Save current user to local database
  static Future<void> saveCurrentUser(User user) async {
    // Save profile image locally if it has a URL
    User userToSave = user;
    if (user.profilePhotoUrl != null && user.profilePhotoUrl!.isNotEmpty) {
      final localImagePath =
          await _saveProfileImageLocally(user.profilePhotoUrl!);
      if (localImagePath != null) {
        userToSave = user.copyWith(profilePhoto: localImagePath);
      }
    }

    // Save user with current timestamp
    final userWithTimestamp = userToSave.copyWith(
      lastSyncTime: DateTime.now(),
    );

    await _userBox?.put(_currentUserKey, userWithTimestamp);
  }

  /// Get current user from local database
  static User? getCurrentUser() {
    return _userBox?.get(_currentUserKey);
  }

  /// Delete current user from local database
  static Future<void> deleteCurrentUser() async {
    // Delete saved profile image if exists
    final user = getCurrentUser();
    if (user?.profilePhoto != null) {
      final file = File(user!.profilePhoto!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    // Clear the user from the database
    await _userBox?.delete(_currentUserKey);
  }

  /// Save profile image locally
  static Future<String?> _saveProfileImageLocally(String imageUrl) async {
    try {
      // Check if URL has changed
      final currentUser = getCurrentUser();

      if (currentUser?.profilePhotoUrl == imageUrl &&
          currentUser?.profilePhoto != null &&
          File(currentUser!.profilePhoto!).existsSync()) {
        return currentUser.profilePhoto;
      }

      // Download image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) return null;

      // Get local directory
      final directory = await getApplicationDocumentsDirectory();
      final imageFolderPath = '${directory.path}/$_profileImageFolderName';
      final imageFolder = Directory(imageFolderPath);

      // Create folder if it doesn't exist
      if (!imageFolder.existsSync()) {
        imageFolder.createSync(recursive: true);
      } else {
        // delete the previous image
        final previousImage =
            File('$imageFolderPath/${currentUser?.profilePhoto}');
        if (previousImage.existsSync()) {
          previousImage.deleteSync();
        }
      }

      // Extract image name from URL
      final imageName = imageUrl.split('/').last;
      final imagePath = '$imageFolderPath/$imageName';

      // Save image to local storage
      final file = File(imagePath);
      await file.writeAsBytes(response.bodyBytes);

      return imagePath;
    } catch (e) {
      return null;
    }
  }

  // Save products to local Hive storage
  static Future<void> cacheProducts(List<Product> products) async {
    final box = await Hive.openBox<Product>(_productsBox);
    await box.clear(); // Clear old data before saving new data
    await box.addAll(products);
  }

  // Get cached products from Hive
  static Future<List<Product>> getCachedProducts() async {
    final box = await Hive.openBox<Product>(_productsBox);
    return box.values.toList();
  }

  // Save restaurants to local Hive storage
  static Future<void> cacheRestaurants(List<Restaurant> restaurants) async {
    final box = await Hive.openBox<Restaurant>(_restaurantsBox);
    await box.clear(); // Clear old data before saving new data
    await box.addAll(restaurants);
  }

  // Get cached restaurants from Hive
  static Future<List<Restaurant>> getCachedRestaurants() async {
    final box = await Hive.openBox<Restaurant>(_restaurantsBox);
    return box.values.toList();
  }

  static Future<void> cacheProductRestaurants(
      int productId, List<Restaurant> restaurants) async {
    try {
      final box = await Hive.openBox('product_restaurants');

      // Store the serialized restaurants with a key based on the product ID
      await box.put('product_$productId',
          restaurants.map((restaurant) => restaurant.toJson()).toList());
    } catch (e) {
      debugPrint('Error caching product restaurants in Hive: $e');
    }
  }

// Get cached restaurants for a specific product from Hive
  static Future<List<Restaurant>?> getCachedProductRestaurants(
      int productId) async {
    try {
      final box = await Hive.openBox('product_restaurants');

      // Check if we have data for this product
      if (!box.containsKey('product_$productId')) {
        return null;
      }

      // Retrieve and deserialize the data
      final restaurantsData = box.get('product_$productId') as List;
      return restaurantsData
          .map((restaurantData) =>
              Restaurant.fromJson(Map<String, dynamic>.from(restaurantData)))
          .toList();
    } catch (e) {
      debugPrint('Error getting cached product restaurants from Hive: $e');
      return null;
    }
  }

  // Product-Restaurant cache methods
  static Future<void> cacheProductRestaurantRelations(
      Map<int, List<Restaurant>> productRestaurants) async {
    try {
      final box = Hive.box<ProductRestaurantCache>(_productRestaurantCacheBox);

      // Convert the Map<int, List<Restaurant>> to Map<String, List<int>>
      // This is because Hive has better support for simple data types
      final Map<String, List<int>> serializedMap = {};

      productRestaurants.forEach((productId, restaurants) {
        serializedMap[productId.toString()] =
            restaurants.map((r) => r.id).toList();
      });

      // Store the serialized map
      await box.put(_productRestaurantCacheKey,
          ProductRestaurantCache(productRestaurantsMap: serializedMap));

      debugPrint('Product-Restaurant relations cached successfully');
    } catch (e) {
      debugPrint('Error caching product-restaurant relations: $e');
    }
  }

  static Future<Map<int, List<Restaurant>>> getProductRestaurantCache() async {
    try {
      final box = Hive.box<ProductRestaurantCache>(_productRestaurantCacheBox);
      final cache = box.get(_productRestaurantCacheKey);

      if (cache == null) {
        debugPrint('No product-restaurant cache found');
        return {};
      }

      // Convert back from serialized format to usable format
      final Map<int, List<Restaurant>> result = {};
      final restaurantsBox = Hive.box<Restaurant>(_restaurantsBox);

      cache.productRestaurantsMap.forEach((productIdStr, restaurantIds) {
        final productId = int.parse(productIdStr);
        final restaurantsList = <Restaurant>[];

        for (var restaurantId in restaurantIds) {
          final restaurant = restaurantsBox.get(restaurantId.toString());
          if (restaurant != null) {
            restaurantsList.add(restaurant);
          }
        }

        if (restaurantsList.isNotEmpty) {
          result[productId] = restaurantsList;
        }
      });

      debugPrint(
          'Loaded ${result.length} product-restaurant relations from cache');
      return result;
    } catch (e) {
      debugPrint('Error loading product-restaurant cache: $e');
      return {};
    }
  }

  static Future<void> clearProductRestaurantCache() async {
    try {
      final box = Hive.box<ProductRestaurantCache>(_productRestaurantCacheBox);
      await box.clear();
      debugPrint('Product-Restaurant cache cleared');
    } catch (e) {
      debugPrint('Error clearing product-restaurant cache: $e');
    }
  }
}
