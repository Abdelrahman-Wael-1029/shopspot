import 'package:hive/hive.dart';

part 'restaurant.g.dart'; 

@HiveType(typeId: 2)
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
  final String? imageUrl;

  @HiveField(5)
  final double latitude;

  @HiveField(6)
  final double longitude;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: json['location'] ?? '',
      imageUrl: json['imageUrl'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
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
    };
  }
}
