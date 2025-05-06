// State classes
abstract class ConnectivityState {}

class ConnectivityInitial extends ConnectivityState {}

class ConnectivityLoading extends ConnectivityState {}

class ConnectivityLoaded extends ConnectivityState {}

class ConnectivityError extends ConnectivityState {
  final String message;

  ConnectivityError(this.message);
}
