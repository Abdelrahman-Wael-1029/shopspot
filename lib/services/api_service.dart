import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/user_model.dart';
import '../models/restaurant.dart';
import '../models/product.dart';
import '../services/database_service.dart';

class ApiService {
  // Base URL for the API
  static const String baseUrl = 'http://192.168.1.8:8000/api';
  // For physical devices using the same network, you might need to use your computer's IP address
  // Example: static const String baseUrl = 'http://192.168.1.4:8000/api';
  // Use 10.0.2.2 for Android emulator to connect to localhost
  // For iOS simulator use 127.0.0.1 instead

  // Cache the server status to avoid multiple ping requests
  static bool? _cachedServerStatus;
  static DateTime? _lastPingTime;
  static const Duration _pingCacheValidity = Duration(seconds: 20);

  // Track active HTTP clients for cancellation
  static final Map<String, http.Client> _activeClients = {};

  // Close all active HTTP clients
  static void _closeAllClients() {
    _activeClients.forEach((key, client) {
      client.close();
    });
    _activeClients.clear();
  }

  // Get a client for a request - allows tracking for later cancellation
  static http.Client _getClient(String requestId) {
    final client = http.Client();
    _activeClients[requestId] = client;
    return client;
  }

  // Remove client after request is complete
  static void _removeClient(String requestId) {
    _activeClients.remove(requestId);
  }

  static void timeoutHandling() {
    // For timeouts, we don't want to block for the full cache validity period
    // Set the lastPingTime to a time that's closer to expiration
    _cachedServerStatus = false;
    _lastPingTime = DateTime.now().subtract(const Duration(seconds: 20));

    // Close any other pending requests since the server is likely down
    _closeAllClients();
  }

  // Check if the Laravel API is accessible with a short timeout
  static Future<bool> isApiAccessible() async {
    if (_cachedServerStatus != null && _lastPingTime != null) {
      final timeSinceLastPing = DateTime.now().difference(_lastPingTime!);
      // If the cache is still valid, return the cached result
      if (timeSinceLastPing < _pingCacheValidity) {
        return _cachedServerStatus!;
      }
    }

    // Generate a unique ID for this request
    final requestId = 'ping-${DateTime.now().millisecondsSinceEpoch}';
    final client = _getClient(requestId);

    try {
      // Test the API using a lightweight endpoint
      final response = await client.get(
        Uri.parse('$baseUrl/ping'),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 2));

      // Cache the result
      _cachedServerStatus = response.statusCode == 200;
      _lastPingTime = DateTime.now();

      // Cleanup the client
      client.close();
      _removeClient(requestId);
      return _cachedServerStatus!;
    } on TimeoutException {
      timeoutHandling();

      return false;
    } catch (e) {
      // Cache the negative result
      _cachedServerStatus = false;
      _lastPingTime = DateTime.now();

      // Close the client to kill the request
      client.close();
      _removeClient(requestId);
      return false;
    }
  }

  // Headers for API requests
  static Future<Map<String, String>> _getHeaders(
      {bool authorized = false}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authorized) {
      final user = DatabaseService.getCurrentUser();
      final token = user?.token;
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final user = DatabaseService.getCurrentUser();
    return user != null && user.token != null;
  }

  // Login user
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    // Generate a unique ID for this request
    final requestId = 'login-${DateTime.now().millisecondsSinceEpoch}';
    final client = _getClient(requestId);

    try {
      final response = await client
          .post(
            Uri.parse('$baseUrl/login'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 2));

      final responseData = jsonDecode(response.body);

      // Cleanup the client
      client.close();
      _removeClient(requestId);

      if (response.statusCode == 200) {
        final user = User.fromJson(responseData['user']);
        final token = responseData['token'];

        // Create a complete user object with token
        final userWithToken = user.copyWith(token: token);

        await DatabaseService.saveCurrentUser(userWithToken);

        return {
          'success': true,
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'],
          'errors': responseData['errors'],
        };
      }
    } on TimeoutException {
      timeoutHandling();

      return {
        'success': false,
        'message': 'Connection timed out. Please try again later.',
      };
    } catch (e) {
      // Cleanup the client
      client.close();
      _removeClient(requestId);

      return {
        'success': false,
        'message': 'Network connection issue. Please try again later.',
      };
    }
  }

  // Register user
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? gender,
    String? level,
  }) async {
    // Generate a unique ID for this request
    final requestId = 'register-${DateTime.now().millisecondsSinceEpoch}';
    final client = _getClient(requestId);
    try {
      final Map<String, dynamic> body = {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      };

      if (gender != null) {
        body['gender'] = gender;
      }

      if (level != null) {
        body['level'] = level;
      }

      // Prepare the request URL
      const requestUrl = '$baseUrl/register';

      final response = await client
          .post(
            Uri.parse(requestUrl),
            headers: await _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 2));

      // Process the response
      final responseData = jsonDecode(response.body);

      // Cleanup the client
      client.close();
      _removeClient(requestId);

      if (response.statusCode == 201) {
        final user = User.fromJson(responseData['user']);
        final token = responseData['token'];

        // Create a complete user object with token
        final userWithToken = user.copyWith(token: token);

        // Store user in Hive database
        await DatabaseService.saveCurrentUser(userWithToken);

        return {
          'success': true,
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'],
          'errors': responseData['errors']
        };
      }
    } on TimeoutException {
      timeoutHandling();

      return {
        'success': false,
        'message': 'Connection timed out. Please try again later.',
      };
    } catch (e) {
      // Cleanup the client
      client.close();
      _removeClient(requestId);

      return {
        'success': false,
        'message': 'Network connection issue. Please try again later.',
        'errors': {
          'error': ['Unable to connect to server']
        },
      };
    }
  }

  // Logout user
  static Future<void> logout() async {
    // Generate a unique ID for this request
    final requestId = 'logout-${DateTime.now().millisecondsSinceEpoch}';
    final client = _getClient(requestId);

    try {
      // Then try to logout from server
      await client
          .post(
            Uri.parse('$baseUrl/logout'),
            headers: await _getHeaders(authorized: true),
          )
          .timeout(const Duration(seconds: 2));

      // Cleanup the client
      client.close();
      _removeClient(requestId);
    } catch (e) {
      // Ignore errors, just clean up
      client.close();
      _removeClient(requestId);
    }

    // Delete local data regardless of server response
    await DatabaseService.deleteCurrentUser();
  }

  // Get user profile
  static Future<Map<String, dynamic>> getProfile() async {
    // Generate a unique ID for this request
    final requestId = 'profile-${DateTime.now().millisecondsSinceEpoch}';
    final client = _getClient(requestId);

    try {
      // Get the current token before making the request
      final currentUser = DatabaseService.getCurrentUser();
      final token = currentUser?.token;

      final response = await client
          .get(
            Uri.parse('$baseUrl/profile'),
            headers: await _getHeaders(authorized: true),
          )
          .timeout(const Duration(seconds: 2));

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final updatedUser = User.fromJson(responseData['user']);

        // Create user with preserved token
        final userWithToken = updatedUser.copyWith(token: token);

        // Save user with token preserved
        await DatabaseService.saveCurrentUser(userWithToken);

        // Cleanup the client
        client.close();
        _removeClient(requestId);

        return {
          'success': true,
        };
      } else {
        // Cleanup the client
        client.close();
        _removeClient(requestId);

        return {
          'success': false,
          'message': responseData['message'],
        };
      }
    } on TimeoutException {
      timeoutHandling();

      return {
        'success': false,
        'message': 'Connection timed out. Please try again later.',
      };
    } catch (e) {
      // Cleanup the client
      client.close();
      _removeClient(requestId);

      return {
        'success': false,
        'message': 'Network connection issue. Please try again later.',
      };
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? gender,
    String? level,
    String? password,
    String? passwordConfirmation,
    File? profilePhoto,
  }) async {
    // This method uses MultipartRequest which doesn't have a direct client instance
    // but we can still track for logging purposes
    final requestId = 'update-profile-${DateTime.now().millisecondsSinceEpoch}';
    _activeClients[requestId] = http.Client(); // track the operation

    try {
      // Get the current user and token
      final currentUser = DatabaseService.getCurrentUser();
      final token = currentUser?.token;

      if (token == null) {
        _removeClient(requestId);
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/profile'),
      );

      request.fields['_method'] = 'PUT';

      // Add auth header
      final headers = await _getHeaders(authorized: true);
      request.headers.addAll(headers);

      // Add fields if they are not null
      if (name != null) request.fields['name'] = name;
      if (gender != null) request.fields['gender'] = gender;
      if (level != null) request.fields['level'] = level;
      if (password != null) request.fields['password'] = password;
      if (passwordConfirmation != null) {
        request.fields['password_confirmation'] = passwordConfirmation;
      }

      // Add profile photo if available
      if (profilePhoto != null) {
        profilePhoto = await compressImageIfNeeded(profilePhoto);
        request.files.add(await http.MultipartFile.fromPath(
          'profile_photo',
          profilePhoto!.path,
        ));
      }

      // Set timeout for the request
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 2));
      final response = await http.Response.fromStream(streamedResponse);

      final responseData = jsonDecode(response.body);

      // Remove from tracking
      _removeClient(requestId);

      if (response.statusCode == 200) {
        final updatedUser = User.fromJson(responseData['user']);

        // Preserve the token
        final userWithToken = updatedUser.copyWith(token: token);

        // Save user with token preserved
        await DatabaseService.saveCurrentUser(userWithToken);

        return {
          'success': true,
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'],
          'errors': responseData['errors'],
        };
      }
    } on TimeoutException {
      timeoutHandling();

      return {
        'success': false,
        'message': 'Connection timed out. Please try again later.',
      };
    } catch (e) {
      // Remove from tracking
      _removeClient(requestId);

      return {
        'success': false,
        'message': 'Network connection issue. Please try again later.',
      };
    }
  }

  static Future<File?> compressImageIfNeeded(File imageFile,
      {int maxSizeKB = 1024}) async {
    final int fileSize = await imageFile.length();
    final int fileSizeKB = fileSize ~/ 1024;

    // If file is already under the limit, return it as is
    if (fileSizeKB <= maxSizeKB) {
      return imageFile;
    }

    // Determine file extension for compression format
    final String extension = p.extension(imageFile.path).toLowerCase();
    final CompressFormat format =
        extension == '.png' ? CompressFormat.png : CompressFormat.jpeg;

    // Create a target path for compressed file
    final Directory tempDir = await getTemporaryDirectory();
    final String targetPath =
        p.join(tempDir.path, 'compressed_${imageFile.path.split('/').last}');

    // Initial quality
    int quality = 100;

    // Calculate quality needed based on file size ratio
    while (fileSizeKB > maxSizeKB) {
      // Reduce quality by 5% each time
      quality -= 5;

      // Delete target file if it exists
      if (File(targetPath).existsSync()) {
        await File(targetPath).delete();
      }

      // Try compression
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        targetPath,
        quality: quality,
        format: format,
      );

      if (result == null) {
        return imageFile;
      }

      // Check size after compression
      final int compressedSize = await File(result.path).length();
      final int compressedSizeKB = compressedSize ~/ 1024;

      // If compressed file is less than maxSizeKB, return it
      if (compressedSizeKB <= maxSizeKB) {
        return File(result.path);
      }
    }
    return imageFile;
  }

  // Restaurant API methods

  // Get all restaurants
  static Future<Map<String, dynamic>> getRestaurants() async {
    final requestId = 'restaurants-${DateTime.now().millisecondsSinceEpoch}';
    final client = _getClient(requestId);

    try {
      final response = await client
          .get(
            Uri.parse('$baseUrl/restaurants'),
            headers: await _getHeaders(authorized: true),
          )
          .timeout(const Duration(seconds: 5));

      final responseData = jsonDecode(response.body);

      // Cleanup the client
      client.close();
      _removeClient(requestId);

      if (response.statusCode == 200) {
        final List<Restaurant> restaurants =
            List<Restaurant>.from(responseData.map((item) => Restaurant.fromJson(item)).toList());

        return {
          'success': true,
          'restaurants': restaurants,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'],
        };
      }
    } on TimeoutException {
      timeoutHandling();

      return {
        'success': false,
        'message': 'Connection timed out. Please try again later.',
      };
    } catch (e) {
      // Cleanup the client
      client.close();
      _removeClient(requestId);
      print(e);

      return {
        'success': false,
        'message': 'Network connection issue. Please try again later.',
      };
    }
  }

  // Get products for a specific restaurant
  static Future<Map<String, dynamic>> getRestaurantProducts(
      int restaurantId) async {
    final requestId =
        'restaurant-products-$restaurantId-${DateTime.now().millisecondsSinceEpoch}';
    final client = _getClient(requestId);

    try {
      final response = await client
          .get(
            Uri.parse('$baseUrl/restaurants/$restaurantId/products'),
            headers: await _getHeaders(authorized: true),
          )
          .timeout(const Duration(seconds: 5));

      final responseData = jsonDecode(response.body);

      // Cleanup the client
      client.close();
      _removeClient(requestId);

      if (response.statusCode == 200) {
        final List<dynamic> data = responseData['data'];
        final List<Product> products =
            data.map((item) => Product.fromJson(item)).toList();

        return {
          'success': true,
          'products': products,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'],
        };
      }
    } on TimeoutException {
      timeoutHandling();

      return {
        'success': false,
        'message': 'Connection timed out. Please try again later.',
      };
    } catch (e) {
      // Cleanup the client
      client.close();
      _removeClient(requestId);

      return {
        'success': false,
        'message': 'Network connection issue. Please try again later.',
      };
    }
  }

  // Product API methods

  // Get all products
  static Future<Map<String, dynamic>> getProducts() async {
    final requestId = 'products-${DateTime.now().millisecondsSinceEpoch}';
    final client = _getClient(requestId);

    try {
      final response = await client
          .get(
            Uri.parse('$baseUrl/products'),
            headers: await _getHeaders(authorized: true),
          )
          .timeout(const Duration(seconds: 5));

      final responseData = jsonDecode(response.body);

      // Cleanup the client
      client.close();
      _removeClient(requestId);

      if (response.statusCode == 200) {
        final List<dynamic> data = responseData['data'];
        final List<Product> products =
            data.map((item) => Product.fromJson(item)).toList();

        return {
          'success': true,
          'products': products,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'],
        };
      }
    } on TimeoutException {
      timeoutHandling();

      return {
        'success': false,
        'message': 'Connection timed out. Please try again later.',
      };
    } catch (e) {
      // Cleanup the client
      client.close();
      _removeClient(requestId);

      return {
        'success': false,
        'message': 'Network connection issue. Please try again later.',
      };
    }
  }

  // Search products by name
  static Future<Map<String, dynamic>> searchProducts(String query) async {
    final requestId =
        'search-products-${DateTime.now().millisecondsSinceEpoch}';
    final client = _getClient(requestId);

    try {
      final response = await client
          .get(
            Uri.parse('$baseUrl/products/search?query=$query'),
            headers: await _getHeaders(authorized: true),
          )
          .timeout(const Duration(seconds: 5));

      final responseData = jsonDecode(response.body);

      // Cleanup the client
      client.close();
      _removeClient(requestId);

      if (response.statusCode == 200) {
        final List<dynamic> data = responseData['data'];
        final List<Product> products =
            data.map((item) => Product.fromJson(item)).toList();

        return {
          'success': true,
          'products': products,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'],
        };
      }
    } on TimeoutException {
      timeoutHandling();

      return {
        'success': false,
        'message': 'Connection timed out. Please try again later.',
      };
    } catch (e) {
      // Cleanup the client
      client.close();
      _removeClient(requestId);

      return {
        'success': false,
        'message': 'Network connection issue. Please try again later.',
      };
    }
  }

  // Get restaurants that sell a specific product
  static Future<Map<String, dynamic>> getProductRestaurants(
      int productId) async {
    final requestId =
        'product-restaurants-$productId-${DateTime.now().millisecondsSinceEpoch}';
    final client = _getClient(requestId);

    try {
      final response = await client
          .get(
            Uri.parse('$baseUrl/products/$productId/restaurants'),
            headers: await _getHeaders(authorized: true),
          )
          .timeout(const Duration(seconds: 5));

      final responseData = jsonDecode(response.body);

      // Cleanup the client
      client.close();
      _removeClient(requestId);

      if (response.statusCode == 200) {
        final List<dynamic> data = responseData['data'];
        final List<Restaurant> restaurants =
            data.map((item) => Restaurant.fromJson(item)).toList();

        return {
          'success': true,
          'restaurants': restaurants,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'],
        };
      }
    } on TimeoutException {
      timeoutHandling();

      return {
        'success': false,
        'message': 'Connection timed out. Please try again later.',
      };
    } catch (e) {
      // Cleanup the client
      client.close();
      _removeClient(requestId);

      return {
        'success': false,
        'message': 'Network connection issue. Please try again later.',
      };
    }
  }

  // Get product details for a specific restaurant
  static Future<Map<String, dynamic>> getProductDetailsForRestaurant(
      int restaurantId, int productId) async {
    final requestId =
        'product-details-$restaurantId-$productId-${DateTime.now().millisecondsSinceEpoch}';
    final client = _getClient(requestId);

    try {
      final response = await client
          .get(
            Uri.parse('$baseUrl/restaurants/$restaurantId/products/$productId'),
            headers: await _getHeaders(authorized: true),
          )
          .timeout(const Duration(seconds: 5));

      final responseData = jsonDecode(response.body);

      // Cleanup the client
      client.close();
      _removeClient(requestId);

      if (response.statusCode == 200) {
        final productData = responseData['data'];
        final product = Product.fromJson(productData);

        return {
          'success': true,
          'product': product,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'],
        };
      }
    } on TimeoutException {
      timeoutHandling();

      return {
        'success': false,
        'message': 'Connection timed out. Please try again later.',
      };
    } catch (e) {
      // Cleanup the client
      client.close();
      _removeClient(requestId);

      return {
        'success': false,
        'message': 'Network connection issue. Please try again later.',
      };
    }
  }
}
