import 'package:geolocator/geolocator.dart';

abstract class LocationState {}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationSuccess extends LocationState {
  final Position position;

  LocationSuccess(this.position);
}

class LocationFailure extends LocationState {
  final String error;

  LocationFailure(this.error);
}

class LocationPermissionDenied extends LocationState {
  final String message;

  LocationPermissionDenied(this.message);
}
