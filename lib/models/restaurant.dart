class Restaurant {
  final int id;
  final String name;
  final String description;
  final String location;
  final String? imageUrl;
  final double latitude;
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
      latitude:double.parse( json['latitude']),
      longitude:double.parse( json['longitude']),
    );
  }
}
