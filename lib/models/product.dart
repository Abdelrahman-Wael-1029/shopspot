import 'package:hive/hive.dart';

part 'product.g.dart'; 

@HiveType(typeId: 1) 
class Product extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}
