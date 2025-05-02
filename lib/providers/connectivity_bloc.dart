// connectivity_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'connectivity_state.dart';

class ConnectivityBloc extends Cubit<ConnectivityState> {
  bool _wasOffline = false;
  DateTime _lastRefreshTime = DateTime.now();
  bool _isServerUnavailable = false;

  StreamSubscription<ConnectivityResult>? _subscription;

  bool get wasOffline => _wasOffline;
  bool get shouldRefresh =>
      _wasOffline || DateTime.now().difference(_lastRefreshTime).inMinutes > 5;
  bool get isServerUnavailable => _isServerUnavailable;

  ConnectivityBloc() : super(ConnectivityInitial()) {
    initConnectivity();
  }

  Future<void> initConnectivity() async{
    // Check initial connectivity status
    await checkConnectivity();

    // Listen for connectivity changes
    _subscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> checkConnectivity() async {
    // Initialize connectivity monitoring
    final connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final isOnline = result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;

    if (isOnline) {
      if (state is ConnectivityOffline) _wasOffline = true;
      emit(ConnectivityOnline());
    } else {
      emit(ConnectivityOffline());
    }
  }

  void markRefreshed() {
    _wasOffline = false;
    _lastRefreshTime = DateTime.now();
    _isServerUnavailable = false;
    emit(ConnectivityOnline());
  }

  void setServerUnavailable() {
    _isServerUnavailable = true;
    emit(ConnectivityServerUnavailable());
  }

  void resetServerStatus() {
    _isServerUnavailable = false;
    emit(ConnectivityOnline());
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
