
// State classes
abstract class IndexState {}

class IndexInitial extends IndexState {}

class IndexLoading extends IndexState {}

class IndexLoaded extends IndexState {}

class IndexError extends IndexState {
  final String message;

  IndexError(this.message);
}