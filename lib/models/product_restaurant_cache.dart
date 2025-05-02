import 'package:hive/hive.dart';

part 'product_restaurant_cache.g.dart';

@HiveType(typeId: 3) // Make sure this ID doesn't conflict with existing types
class ProductRestaurantCache {
  @HiveField(0)
  final Map<String, List<int>> productRestaurantsMap;

  ProductRestaurantCache({required this.productRestaurantsMap});
}