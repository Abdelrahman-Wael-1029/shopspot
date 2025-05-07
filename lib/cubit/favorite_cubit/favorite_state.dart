abstract class FavoriteState {}

class FavoriteInitial extends FavoriteState {}

class FavoriteLoading extends FavoriteState {}

class FavoriteLoaded extends FavoriteState {}

class FavoriteError extends FavoriteState {
  final String message;

  FavoriteError(this.message);
}
