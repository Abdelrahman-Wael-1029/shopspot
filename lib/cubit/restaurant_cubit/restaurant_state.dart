abstract class RestaurantState {}

class RestaurantInitial extends RestaurantState {}

class RestaurantLoading extends RestaurantState {}

class RestaurantLoaded extends RestaurantState {}

class RestaurantError extends RestaurantState {
  final String message;

  RestaurantError(this.message);
}
