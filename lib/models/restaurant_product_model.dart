import 'package:hive/hive.dart';

part 'package:shopspot/models/restaurant_product_model.g.dart';

@HiveType(typeId: 3)
class RestaurantProduct extends HiveObject {
  @HiveField(0)
  final int restaurantId;

  @HiveField(1)
  final int productId;

  @HiveField(2)
  final int price;

  @HiveField(3)
  final String status;

  @HiveField(4)
  final double rating;

  RestaurantProduct({
    required this.restaurantId,
    required this.productId,
    required this.price,
    required this.status,
    required this.rating,
  });

  // Generate a unique key for this relationship
  String get uniqueKey => '$restaurantId:$productId';
  
  factory RestaurantProduct.fromJson(Map<String, dynamic> json) {
    return RestaurantProduct(
      restaurantId: json['restaurant_id'],
      productId: json['product_id'],
      price: json['price'],
      status: json['status'],
      rating: double.parse(json['rating'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'restaurant_id': restaurantId,
      'product_id': productId,
      'price': price,
      'status': status,
      'rating': rating,
    };
  }
}