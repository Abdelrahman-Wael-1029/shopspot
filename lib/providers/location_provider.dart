import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentLocation;
  String? _error;
  bool hasPermission = false;
  bool loading = false;

  Position? get currentLocation => _currentLocation;
  String? get error => _error;
  bool get hasLocation => _currentLocation != null;

  // Getter to check if location services are available
  Future get isLocationServiceEnabled async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Initialize location (for first load)
  Future initLocation() async {
    try {
      // Just check permission status without requesting again
      LocationPermission permission = await Geolocator.checkPermission();

      // If denied forever, just set error and return
      if (permission == LocationPermission.deniedForever) {
        hasPermission = false;
        _error =
            'Location permissions are permanently denied. Please enable them in app settings.';
        notifyListeners();
        return;
      }

      // Only request if it's the first time (when permission is denied)
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        // Don't request again if user denied
      }

      // Update permission status based on current state
      hasPermission = (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse);

      if (hasPermission) {
        _currentLocation = await Geolocator.getCurrentPosition();
        _error = null;
      } else {
        _error = 'Location permissions are not granted.';
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Refresh location if not have permission request again and update current location
  Future refreshLocation() async {
    loading = true;
    notifyListeners();
    try {
      final permission = await Geolocator.requestPermission();
      hasPermission = (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse);
      if (hasPermission) {
        _currentLocation = await Geolocator.getCurrentPosition();
        _error = null;
      } else {
        _error = 'Location permissions are not granted.';
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
    finally{
      loading = false;
      notifyListeners();
    }
  }

  // Open app settings to let user manually enable permissions
  Future openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // Open location settings to let user enable location services
  Future openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Calculate distance between current location and destination
  double calculateDistance(double destLatitude, double destLongitude) {
    if (_currentLocation == null) return 0;

    return Geolocator.distanceBetween(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          destLatitude,
          destLongitude,
        ) /
        1000; // Convert to km
  }

  // Open Google Maps with directions
  Future openGoogleMapWithDestination(double lat, double lng) async {
    try {
      final Uri googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
      );

      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch Google Maps.';
      }
    } catch (e) {
      _error = 'Error opening Google Maps: $e';
      notifyListeners();
      print(_error);
    }
  }

  // Clear any errors
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
