import 'package:hive/hive.dart';
import '../models/product.dart';

part 'restaurant_product_cache.g.dart';

@HiveType(typeId: 4) // اختر رقم لا يتعارض
class RestaurantProductCache extends HiveObject {
  @HiveField(0)
  final List<int> productIds;

  RestaurantProductCache({required this.productIds});
}
