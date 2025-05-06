abstract class ProductState {}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {}

class ProductError extends ProductState {
  final String message;

  ProductError(this.message);
}