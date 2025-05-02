import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'location_state.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationBloc extends Cubit<LocationState> {
  LocationBloc() : super(LocationInitial());

  Future<void> initLocation() async {
    emit(LocationLoading());

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.deniedForever) {
        emit(LocationPermissionDenied(
            'Location permissions are permanently denied. Please enable them in app settings.'));
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      bool hasPermission = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      if (hasPermission) {
        final position = await Geolocator.getCurrentPosition();
        emit(LocationSuccess(position));
      } else {
        emit(LocationPermissionDenied('Location permissions are not granted.'));
      }
    } catch (e) {
      emit(LocationFailure(e.toString()));
    }
  }

  Future<void> refreshLocation() async {
    emit(LocationLoading());

    try {
      final permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition();
        emit(LocationSuccess(position));
      } else {
        emit(LocationPermissionDenied('Location permissions are not granted.'));
      }
    } catch (e) {
      emit(LocationFailure(e.toString()));
    }
  }

  Future<void> openGoogleMapWithDestination(double lat, double lng) async {
    try {
      final Uri googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
      );

      if (!await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication)) {
        emit(LocationFailure('Could not launch Google Maps.'));
      }
    } catch (e) {
      emit(LocationFailure('Error opening Google Maps: $e'));
    }
  }

  double calculateDistance(Position? currentLocation, double destLat, double destLng) {
    if (currentLocation == null) return 0;
    return Geolocator.distanceBetween(
          currentLocation.latitude,
          currentLocation.longitude,
          destLat,
          destLng,
        ) /
        1000; // km
  }

   // Open app settings to let user manually enable permissions
  Future openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // Open location settings to let user enable location services
  Future openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}
