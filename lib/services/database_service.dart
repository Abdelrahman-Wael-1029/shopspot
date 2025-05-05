import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shopspot/models/user_model.dart';
import 'package:shopspot/models/restaurant_model.dart';
import 'package:shopspot/models/product_model.dart';
import 'package:shopspot/models/restaurant_product_model.dart';

class DatabaseService {
  static const String _userBoxName = 'userBox';
  static const String _restaurantsBoxName = 'restaurantsBox';
  static const String _productsBoxName = 'productsBox';
  static const String _restaurantProductsBoxName = 'restaurantProductsBox';
  static const String _currentUserKey = 'currentUser';
  static const String _profileImageFolderName = 'profile_images';
  static Box<User>? _userBox;
  static Box<Restaurant>? _restaurantsBox;
  static Box<Product>? _productsBox;
  static Box<RestaurantProduct>? _restaurantProductsBox;

  /// Initialize Hive and open all boxes
  static Future<void> init() async {
    // Initialize Hive
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(RestaurantAdapter());
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(RestaurantProductAdapter());

    // Open boxes
    _userBox = await Hive.openBox<User>(_userBoxName);
    _restaurantsBox = await Hive.openBox<Restaurant>(_restaurantsBoxName);
    _productsBox = await Hive.openBox<Product>(_productsBoxName);
    _restaurantProductsBox =
        await Hive.openBox<RestaurantProduct>(_restaurantProductsBoxName);
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

      // If the URL is the same as what we already have restaurantd locally, reuse the existing image
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

  // Restaurant methods

  /// Save restaurants to local database
  static Future<void> saveRestaurants(List<Restaurant> restaurants) async {
    // Save all restaurants
    for (var restaurant in restaurants) {
      await _restaurantsBox?.put(restaurant.id, restaurant);
    }
  }

  /// Delete all relations with a restaurant
  static Future<void> deleteRestaurantRelations(int restaurantId) async {
    // Delete all relations with the restaurant
    final relations = getRelationsByRestaurantId(restaurantId);
    for (var relation in relations) {
      await _restaurantProductsBox?.delete(relation.uniqueKey);
    }
  }

  /// Delete all restaurants and products from local database
  static Future<void> clearDatabase() async {
    // Delete all restaurants
    await _restaurantsBox?.clear();
    // Delete all restaurant products
    await _restaurantProductsBox?.clear();
    // Delete all products
    await _productsBox?.clear();
  }

  /// Get all restaurants from local database
  static List<Restaurant> getAllRestaurants() {
    return _restaurantsBox?.values.toList() ?? [];
  }

  /// Get a restaurant by ID
  static Restaurant? getRestaurant(int restaurantId) {
    return _restaurantsBox?.get(restaurantId);
  }

  /// Get restaurants by product ID
  static List<Restaurant> getRestaurantsByProductId(int productId) {
    return getRelationsByProductId(productId)
        .map((relation) => getRestaurant(relation.restaurantId))
        .whereType<Restaurant>()
        .toList();
  }

  /// Get relations by restaurant ID
  static List<RestaurantProduct> getRelationsByRestaurantId(int restaurantId) {
    return _restaurantProductsBox?.values
            .where((relation) => relation.restaurantId == restaurantId)
            .toList() ??
        [];
  }

  // Product methods

  /// Save products to local database
  static Future<void> saveProducts(List<Product> products) async {
    // Save all products
    for (var product in products) {
      await _productsBox?.put(product.id, product);
    }
  }

  /// Get all products from local database
  static List<Product> getAllProducts() {
    return _productsBox?.values.toList() ?? [];
  }

  /// Get a product by ID
  static Product? getProduct(int productId) {
    return _productsBox?.get(productId);
  }

  /// Get products by restaurant ID
  static List<Product> getProductsByRestaurantId(int restaurantId) {
    return getRelationsByRestaurantId(restaurantId)
        .map((relation) => getProduct(relation.productId))
        .whereType<Product>()
        .toList();
  }

  /// Get relations by product ID
  static List<RestaurantProduct> getRelationsByProductId(int productId) {
    return _restaurantProductsBox?.values
            .where((relation) => relation.productId == productId)
            .toList() ??
        [];
  }

  /// Save restaurant's products to local database
  static Future<void> saveRestaurantProducts(
      List<RestaurantProduct> relations) async {
    final Map<String, RestaurantProduct> entries = {
      for (var relation in relations) relation.uniqueKey: relation
    };
    await _restaurantProductsBox?.putAll(entries);
  }

  // Favorites methods

  /// Add a restaurant to favorites
  static Future<void> changeFavoriteState(
      int restaurantId, bool isFavorite) async {
    // Get the current user to check if we're logged in
    final user = getCurrentUser();
    if (user == null) {
      return; // Don't add favorites if not logged in
    }

    // Update the isFavorite flag in the restaurant
    final restaurant = getRestaurant(restaurantId);
    if (restaurant != null) {
      final updatedRestaurant = Restaurant.from(restaurant);
      updatedRestaurant.isFavorite = isFavorite;
      await _restaurantsBox?.put(restaurantId, updatedRestaurant);
    }
  }

  /// Get all favorited restaurants
  static List<Restaurant> getFavoriteRestaurants() {
    // If not logged in, no favorites
    if (getCurrentUser() == null) {
      return [];
    }

    // Filter restaurants where isFavorite is true
    return getAllRestaurants()
        .where((restaurant) => restaurant.isFavorite)
        .toList();
  }

  /// Clear all favorites
  static Future<void> clearAllFavorites() async {
    // Get the current user to check if we're logged in
    final user = getCurrentUser();
    if (user == null) {
      return; // Don't clear favorites if not logged in
    }

    // Update isFavorite flag in all restaurants
    final restaurants = getAllRestaurants()
        .where((restaurant) => restaurant.isFavorite)
        .toList();
    for (final restaurant in restaurants) {
      final updatedRestaurant = Restaurant.from(restaurant);
      updatedRestaurant.isFavorite = false;
      await _restaurantsBox?.put(restaurant.id, updatedRestaurant);
    }
  }
}
