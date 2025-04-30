import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentLocation;

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

  void openGoogleMapWithDestination(double lat, double lng) async {
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
      print('Error opening Google Maps: $e');
    }
  }
}
