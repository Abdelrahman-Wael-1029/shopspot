import 'package:hive/hive.dart';

part 'package:shopspot/models/restaurant_model.g.dart';

@HiveType(typeId: 1)
class Restaurant extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String location;

  @HiveField(4)
  final String imageUrl;

  @HiveField(5)
  final double latitude;

  @HiveField(6)
  final double longitude;

  @HiveField(7)
  bool isFavorite = false;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    this.isFavorite = false,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: json['location'],
      imageUrl: json['imageUrl'],
      latitude: double.parse(json['latitude']),
      longitude: double.parse(json['longitude']),
      isFavorite: json['is_favorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'is_favorite': isFavorite,
    };
  }

  static from(Restaurant restaurant) {
    return Restaurant(
      id: restaurant.id,
      name: restaurant.name,
      description: restaurant.description,
      location: restaurant.location,
      imageUrl: restaurant.imageUrl,
      latitude: restaurant.latitude,
      longitude: restaurant.longitude,
      isFavorite: restaurant.isFavorite,
    );
  }

  @override
  // ignore: hash_and_equals
  operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Restaurant && id == other.id;
  }
}
