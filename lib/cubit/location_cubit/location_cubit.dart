import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shopspot/cubit/location_cubit/location_state.dart';
import 'package:shopspot/models/restaurant_model.dart';

class LocationCubit extends Cubit<LocationState> {
  Position? _currentLocation;
  final Map<int, double?> _restaurantDistances = {};

  LocationCubit() : super(LocationInitial());

  Position? get currentLocation => _currentLocation;

  Future<bool> checkLocationPermission({request = true}) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!request) return false;
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied
          return false;
        }
      } else if (permission == LocationPermission.deniedForever) {
        // Permissions are permanently denied
        return false;
      }

      // Check if location services are enabled
      if (!request) return Geolocator.isLocationServiceEnabled();

      _currentLocation = await Geolocator.getCurrentPosition();
      return _currentLocation != null;
    } catch (e) {
      // Handle any exceptions that may occur during permission check
      return false;
    }
  }

  // Refresh current location
  Future<void> refreshLocation() async {
    try {
      if (!await checkLocationPermission(request: false)) {
        return;
      }

      // Always get fresh GPS data when refreshing
      _currentLocation = await Geolocator.getCurrentPosition();
    } catch (e) {
      // Do nothing
    }
  }

  // Calculate distance to restaurant (locally)
  double? calculateDistance(Restaurant restaurant) {
    if (_currentLocation == null) {
      return null; // Invalid distance
    }

    // First check if we already have the distance cached
    if (_restaurantDistances.containsKey(restaurant.id)) {
      return _restaurantDistances[restaurant.id]!;
    }

    try {
      final distance = Geolocator.distanceBetween(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            restaurant.latitude,
            restaurant.longitude,
          ) /
          1000; // Convert to kilometers
      return distance;
    } catch (e) {
      // Handle any exceptions that may occur during distance calculation
      return null; // Invalid distance
    }
  }

  double? getDistanceSync(Restaurant restaurant) {
    return _restaurantDistances[restaurant.id];
  }

  // Get distance from server (more accurate with road and terrain)
  Future<double?> getDistance(Restaurant restaurant) async {
    emit(LocationLoading());

    try {
      await refreshLocation();
    } catch (e) {
      // Failed to get location
    }

    if (_currentLocation == null) {
      emit(LocationError("Failed to get location"));
      return null; // Failed to get location
    }

    // Calculate distance locally
    final distance = calculateDistance(restaurant);
    _restaurantDistances[restaurant.id] = distance;
    emit(LocationLoaded());
    return distance;
  }

  // Format distance for display
  String formatDistance(double distance) {
    if (distance < 1) {
      final meters = (distance * 1000).round();
      return '$meters m';
    } else if (distance < 10) {
      return '${distance.toStringAsFixed(1)} km';
    } else {
      return '${distance.round()} km';
    }
  }
}
