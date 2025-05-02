abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {}

class AuthFailure extends AuthState {
  final String message;
  final Map<String, dynamic>? validationErrors;

  AuthFailure(this.message, {this.validationErrors});
}

class ProfileLoading extends AuthState {}

class ProfileSuccess extends AuthState {}

class ProfileFailure extends AuthState {final String message;
  final Map<String, dynamic>? validationErrors;

  ProfileFailure(this.message, {this.validationErrors});}

class AuthLoggedOut extends AuthState {}