import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentLocation;
  final Map<int, double?> _storeDistances = {};

  // Refresh current location
  Future<void> refreshLocation() async {
    try {
      final hasPermission = await LocationService.checkLocationPermission();
      if (!hasPermission) {
        return;
      }

      // Always get fresh GPS data when refreshing
      _currentLocation = await LocationService.getCurrentLocation();
    } catch (e) {
      // Do nothing
    }
  }
}
