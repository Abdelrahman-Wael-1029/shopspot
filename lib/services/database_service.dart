import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shopspot/models/product.dart';
import 'package:shopspot/models/product_restaurant_cache.dart';
import 'package:shopspot/models/restaurant.dart';
import 'package:shopspot/models/restaurant_product_cache.dart';
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
  static const String _restaurantProductCacheBox = 'restaurantProductCacheBox';

  /// Initialize Hive and open all boxes
  static Future<void> init() async {
    // Initialize Hive
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(RestaurantAdapter());
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(ProductRestaurantCacheAdapter());
    Hive.registerAdapter(RestaurantProductCacheAdapter());

    // Open boxes
    _userBox = await Hive.openBox<User>(_userBoxName);
    await Hive.openBox<Product>(_productsBox);
    await Hive.openBox<Restaurant>(_restaurantsBox);
    await Hive.openBox<ProductRestaurantCache>(_productRestaurantCacheBox);
    await Hive.openBox<RestaurantProductCache>(_restaurantProductCacheBox);
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

  // Product-Restaurant relationship caching
  static Future<void> cacheProductRestaurantRelations(
      Map<int, List<Restaurant>> productRestaurantsCache) async {
    final box =
        await Hive.openBox<ProductRestaurantCache>(_productRestaurantCacheBox);

    // Convert the Map<int, List<Restaurant>> to Map<String, List<int>>
    // because Hive works better with primitive types
    final Map<String, List<int>> serializableMap = {};

    productRestaurantsCache.forEach((productId, restaurants) {
      // Store restaurant IDs instead of full objects
      serializableMap[productId.toString()] =
          restaurants.map((r) => r.id).toList();
    });

    final cacheObject =
        ProductRestaurantCache(productRestaurantsMap: serializableMap);
    await box.put(_productRestaurantCacheKey, cacheObject);
    await box.close();
  }

  static Future<Map<int, List<Restaurant>>> getProductRestaurantCache() async {
    final box =
        await Hive.openBox<ProductRestaurantCache>(_productRestaurantCacheBox);
    final cacheObject = box.get(_productRestaurantCacheKey);
    final Map<int, List<Restaurant>> result = {};

    if (cacheObject != null) {
      // First, get all restaurants to use for lookup
      final allRestaurants = await getCachedRestaurants();
      final Map<int, Restaurant> restaurantMap = {};
      for (var restaurant in allRestaurants) {
        restaurantMap[restaurant.id] = restaurant;
      }

      // Convert back from Map<String, List<int>> to Map<int, List<Restaurant>>
      cacheObject.productRestaurantsMap.forEach((productIdStr, restaurantIds) {
        final productId = int.parse(productIdStr);
        final List<Restaurant> restaurantsForProduct = [];

        for (var restaurantId in restaurantIds) {
          if (restaurantMap.containsKey(restaurantId)) {
            restaurantsForProduct.add(restaurantMap[restaurantId]!);
          }
        }

        result[productId] = restaurantsForProduct;
      });
    }

    await box.close();
    return result;
  }

  static Future<void> clearProductRestaurantCache() async {
    final box =
        await Hive.openBox<ProductRestaurantCache>(_productRestaurantCacheBox);
    await box.clear();
    await box.close();
  }

  static Future<void> cacheProductsForRestaurant(
      int restaurantId, List<Product> products) async {
    try {
      final box = Hive.box<RestaurantProductCache>(_restaurantProductCacheBox);
      final productIds = products.map((p) => p.id).toList();

      await box.put(
        restaurantId.toString(),
        RestaurantProductCache(productIds: productIds),
      );

      final productsBox = Hive.box<Product>(_productsBox);
      for (var product in products) {
        productsBox.put(product.id.toString(), product);
      }

      debugPrint('Cached products for restaurant $restaurantId');
    } catch (e) {
      debugPrint('Error caching products for restaurant $restaurantId: $e');
    }
  }

  static Future<List<Product>> getCachedProductsForRestaurant(
      int restaurantId) async {
    try {
      final box = Hive.box<RestaurantProductCache>(_restaurantProductCacheBox);
      final cache = box.get(restaurantId.toString());

      if (cache == null) return [];

      final productsBox = Hive.box<Product>(_productsBox);
      final products = <Product>[];

      for (var id in cache.productIds) {
        final product = productsBox.get(id.toString());
        if (product != null) products.add(product);
      }

      return products;
    } catch (e) {
      debugPrint(
          'Error loading cached products for restaurant $restaurantId: $e');
      return [];
    }
  }
}
