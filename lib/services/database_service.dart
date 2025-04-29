import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/user_model.dart';

class DatabaseService {
  static const String _userBoxName = 'userBox';
  static const String _currentUserKey = 'currentUser';
  static const String _profileImageFolderName = 'profile_images';
  static Box<User>? _userBox;

  /// Initialize Hive and open all boxes
  static Future<void> init() async {
    // Initialize Hive
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(UserAdapter());

    // Open boxes
    _userBox = await Hive.openBox<User>(_userBoxName);
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
}
