import 'package:hive/hive.dart';

part 'restaurant_product_cache.g.dart';

@HiveType(typeId: 4) 
class RestaurantProductCache extends HiveObject {
  @HiveField(0)
  final List<int> productIds;

  RestaurantProductCache({required this.productIds});
}
