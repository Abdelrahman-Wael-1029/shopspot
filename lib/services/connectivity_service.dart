import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService with ChangeNotifier {
  bool _isOnline = false;
  bool _wasOffline = false;
  DateTime _lastRefreshTime = DateTime.now();

  // Add variable to track server availability for favorite actions
  bool _isServerUnavailable = false;

  // Stream subscriptions
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Getters
  bool get isOnline => _isOnline;
  bool get wasOffline => _wasOffline;
  bool get shouldRefresh =>
      _wasOffline || DateTime.now().difference(_lastRefreshTime).inMinutes > 5;

  // Getter for favorite server status
  bool get isServerUnavailable => _isServerUnavailable;

  ConnectivityService() {
    _initConnectivity();
  }

  void _initConnectivity() {
    // Check initial connectivity status
    checkConnectivity();

    // Listen for connectivity changes
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> checkConnectivity() async {
    // Initialize connectivity monitoring
    final connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;

    // Track if we were offline but now back online
    if (!wasOnline && _isOnline) {
      _wasOffline = true;
    }

    notifyListeners();
  }

  // Mark that data has been refreshed
  void markRefreshed() {
    _wasOffline = false;
    _lastRefreshTime = DateTime.now();

    // When data is successfully refreshed, also clear the favorite server unavailable flag
    _isServerUnavailable = false;

    notifyListeners();
  }

  void setServerUnavailable() {
    _isServerUnavailable = true;
    notifyListeners();
  }

  // Reset server down status (call when server is back up)
  void resetServerStatus() {
    _isServerUnavailable = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
