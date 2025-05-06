import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shopspot/cubit/auth_cubit/auth_state.dart';
import 'package:shopspot/cubit/favorite_cubit/favorite_cubit.dart';
import 'package:shopspot/cubit/restaurant_cubit/restaurant_cubit.dart';
import 'package:shopspot/models/user_model.dart';
import 'package:shopspot/services/api_service.dart';
import 'package:shopspot/services/database_service.dart';
import 'package:shopspot/services/connectivity_service/connectivity_service.dart';
import 'package:shopspot/utils/color_scheme_extension.dart';

class AuthCubit extends Cubit<AuthState> {
  User? _user;
  Map<String, dynamic>? _validationErrors;

  AuthCubit() : super(AuthInitial());

  User? get user => _user;
  Map<String, dynamic>? get validationErrors => _validationErrors;
  bool get isAuthenticated => _user != null;

  // Login user
  Future<bool> login(
      BuildContext context, String email, String password) async {
    _validationErrors = null;
    emit(AuthLoading());
    bool success = false;

    try {
      // Check internet connection before attempting login
      final hasInternet = await ApiService.isApiAccessible();
      if (!hasInternet) {
        emit(AuthError(
            'Unable to connect to the server. Please try again later.'));
        return false;
      }

      final result = await ApiService.login(email, password);

      if (result['success']) {
        _user = DatabaseService.getCurrentUser();
        success = true;
        emit(AuthLoaded());
        if (context.mounted) {
          context.read<RestaurantCubit>().refreshRestaurants(context);
        }
      } else {
        _validationErrors = result['errors'] as Map<String, dynamic>?;
        emit(AuthError(result['message']));
      }
    } catch (e) {
      emit(AuthError(
          'Unable to connect to the server. Please try again later.'));
    }

    return success;
  }

  // Register user
  Future<bool> register({
    required BuildContext context,
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? gender,
    String? level,
  }) async {
    _validationErrors = null;
    emit(AuthLoading());
    bool success = false;

    try {
      // Check internet connection before attempting registration
      final hasInternet = await ApiService.isApiAccessible();
      if (!hasInternet) {
        emit(AuthError(
            'Unable to connect to the server. Please try again later.'));
        return false;
      }

      final result = await ApiService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        gender: gender,
        level: level,
      );

      if (result['success']) {
        _user = DatabaseService.getCurrentUser();
        success = true;
        emit(AuthLoaded());
        if (context.mounted) {
          context.read<RestaurantCubit>().refreshRestaurants(context);
        }
      } else {
        _validationErrors = result['errors'] as Map<String, dynamic>?;
        emit(AuthError(result['message']));
      }
    } catch (e) {
      emit(AuthError(
          'Unable to connect to the server. Please try again later.'));
    }

    return success;
  }

  // Logout user
  Future<void> logout(BuildContext context) async {
    emit(AuthLoading());

    try {
      context.read<FavoriteCubit>().clearAllFavorites();
      // Try to logout from server if we have internet
      final hasInternet = await ApiService.isApiAccessible();
      if (hasInternet) {
        await ApiService.logout();
      }
    } finally {
      // Always clear local data regardless of server response
      await DatabaseService.deleteCurrentUser();

      _user = null;
      emit(AuthInitial());
    }
  }

  // Get user profile data
  Future<void> getProfile(BuildContext context) async {
    emit(AuthLoading());

    final connectivityService = context.read<ConnectivityService>();

    // Check if local user data exists
    final localUser = DatabaseService.getCurrentUser();
    final hasLocalData = localUser != null;

    // Check server availability first with a short timeout
    final serverIsAvailable = await ApiService.isApiAccessible();
    Map<String, dynamic> result = {};

    try {
      // If server is available, determine if we should use server data
      if (serverIsAvailable) {
        // Reset server status since it's available
        connectivityService.resetServerStatus();
        result = await ApiService.getProfile();

        if (result['success']) {
          _user = result['user'];
          emit(AuthLoaded());

          // Mark as refreshed
          connectivityService.markRefreshed();

          return;
        }
      }
    } finally {
      if (!serverIsAvailable || (serverIsAvailable && !result['success'])) {
        if (hasLocalData) {
          _user = localUser;
          emit(AuthLoaded());

          // Show toast if connectivity service is available
          if (context.mounted) {
            Fluttertoast.showToast(
              msg: 'Unable to connect to the server. Using cached data.',
              backgroundColor: Theme.of(context).colorScheme.warning,
              textColor: Theme.of(context).colorScheme.onWarning,
            );
          }
        } else {
          emit(AuthError(
              'Network connection required. Please check your connection and try again.'));
        }
      }
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? gender,
    String? level,
    String? password,
    String? passwordConfirmation,
    File? profilePhoto,
  }) async {
    emit(AuthLoading());
    bool success = false;

    try {
      // Check internet connection before attempting update
      final hasInternet = await ApiService.isApiAccessible();
      if (!hasInternet) {
        emit(AuthError(
            'Unable to connect to the server. Please try again later.'));
        return false;
      }

      final result = await ApiService.updateProfile(
        name: name,
        gender: gender,
        level: level,
        password: password,
        passwordConfirmation: passwordConfirmation,
        profilePhoto: profilePhoto,
      );

      if (result['success']) {
        _user = DatabaseService.getCurrentUser();
        success = true;
        emit(AuthLoaded());
      } else {
        emit(AuthError(result['message']));
      }
    } catch (e) {
      emit(AuthError(
          'Unable to connect to the server. Please try again later.'));
    }

    return success;
  }

  // Check if user is authenticated using only cached data (no API calls)
  bool checkCachedAuthentication() {
    // Check if we have a valid local user without making API calls
    final localUser = DatabaseService.getCurrentUser();
    _user = localUser; // Set the user from local cache

    if (localUser != null) {
      emit(AuthLoaded());
      return true;
    }

    return false;
  }
}
