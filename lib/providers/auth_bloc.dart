import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shopspot/providers/auth_state.dart';
import 'package:shopspot/providers/connectivity_provider.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';



class AuthBloc extends Cubit<AuthState> {
  AuthBloc() : super(AuthInitial());

  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final hasInternet = await ApiService.isApiAccessible();
      if (!hasInternet) {
        emit(AuthFailure('Unable to connect to the server.'));
      }

      final result = await ApiService.login(email, password);
      if (result['success']) {
        _currentUser = DatabaseService.getCurrentUser();
        emit(AuthSuccess());
      } else {
        emit(AuthFailure(result['message'] ?? 'Login failed', validationErrors: result['errors']));
      }
    } catch (_) {
      emit(AuthFailure('Login failed. Please try again.'));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? gender,
    String? level,
  }) async {
    emit(AuthLoading());
    try {
      final hasInternet = await ApiService.isApiAccessible();
      if (!hasInternet) {
        emit(AuthFailure('Unable to connect to the server.'));
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
        _currentUser = DatabaseService.getCurrentUser();
        emit(AuthSuccess());
      } else {
        emit(AuthFailure(result['message'] ?? 'Registration failed', validationErrors: result['errors']));
      }
    } catch (_) {
      emit(AuthFailure('Registration failed. Please try again.'));
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      final hasInternet = await ApiService.isApiAccessible();
      if (hasInternet) await ApiService.logout();
    } catch (_) {}
    await DatabaseService.deleteCurrentUser();
    _currentUser = null;
    emit(AuthLoggedOut());
  }

  Future<void> getProfile(BuildContext context) async {
    emit(ProfileLoading());
    final connectivityProvider =
        Provider.of<ConnectivityProvider>(context, listen: false);

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
        connectivityProvider.resetServerStatus();
        result = await ApiService.getProfile();

        if (result['success']) {
          _currentUser = result['user'];
          _currentUser = null;

          // Mark as refreshed
          connectivityProvider.markRefreshed();

          
          emit(ProfileSuccess());
          return;
        }
      }
    } catch (e) {
      emit(ProfileFailure('Failed to fetch profile.'));
      // Do nothing
    } finally {
      String?error;
      if (!serverIsAvailable || (serverIsAvailable && !result['success'])) {
        if (hasLocalData) {
          _currentUser = localUser;
          error = null; // Don't show error if we have cached data

          // Show toast if connectivity service is available
          if (context.mounted) {
            Fluttertoast.showToast(
              msg: 'Unable to connect to the server. Using cached data.',
              backgroundColor: Colors.orange,
            );
          }
        } else {
          error =
              'Network connection required. Please check your connection and try again.';
        }
      }
      emit(ProfileFailure(error ?? 'Failed to fetch profile.'));
    }
  }

  Future<void> updateProfile({
    String? name,
    String? gender,
    String? level,
    String? password,
    String? passwordConfirmation,
    File? profilePhoto,
  }) async {
    emit(ProfileLoading());
    try {
      final hasInternet = await ApiService.isApiAccessible();
      if (!hasInternet) {
        emit(AuthFailure('Unable to connect to the server.'));
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
        _currentUser = DatabaseService.getCurrentUser();
        emit(ProfileSuccess());
      } else {
        emit(AuthFailure(result['message'] ?? 'Update failed', validationErrors: result['errors']));
      }
    } catch (_) {
      emit(ProfileFailure('Failed to update profile.'));
    }
  }

  bool checkCachedAuthentication() {
    final localUser = DatabaseService.getCurrentUser();
    _currentUser = localUser;
    return localUser != null;
  }
}
