// connectivity_state.dart
abstract class ConnectivityState {}

class ConnectivityInitial extends ConnectivityState {}

class ConnectivityOnline extends ConnectivityState {}

class ConnectivityOffline extends ConnectivityState {}

class ConnectivityServerUnavailable extends ConnectivityState {}
