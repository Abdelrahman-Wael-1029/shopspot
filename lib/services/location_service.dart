import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Request location permission and check status
  static Future<bool> checkLocationPermission({bool request = false}) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (request) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied
          return false;
        }
      } else {
        // Permissions are denied and not asked
        return false;
      }
    } else if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      return false;
    }

    // Check if location services are enabled
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get current user location
  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }

  // Calculate distance between user and store using Haversine formula
  static double calculateDistance(
      double userLat, double userLng, double storeLat, double storeLng) {
    // Earth's radius in kilometers
    const double earthRadius = 6371;

    // Convert degrees to radians
    final double latDiff = _toRadians(storeLat - userLat);
    final double lngDiff = _toRadians(storeLng - userLng);

    // Haversine formula
    final double a = math.sin(latDiff / 2) * math.sin(latDiff / 2) +
        math.cos(_toRadians(userLat)) *
            math.cos(_toRadians(storeLat)) *
            math.sin(lngDiff / 2) *
            math.sin(lngDiff / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final double distance = earthRadius * c;

    return distance;
  }

  // Convert degrees to radians
  static double _toRadians(double degree) {
    return degree * math.pi / 180;
  }
}
