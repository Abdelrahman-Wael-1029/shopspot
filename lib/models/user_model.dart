import 'package:hive/hive.dart';

part 'package:shopspot/models/user_model.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  final int? id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String email;
  
  @HiveField(3)
  final String? gender;
  
  @HiveField(4)
  final String? level;
  
  @HiveField(5)
  final String? profilePhoto;
  
  @HiveField(6)
  final String? profilePhotoUrl; // Full URL to profile photo
  
  @HiveField(7)
  final String? token;

  User({
    this.id,
    required this.name,
    required this.email,
    this.gender,
    this.level,
    this.profilePhoto,
    this.profilePhotoUrl,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      gender: json['gender'],
      level: json['level'],
      profilePhoto: json['profile_photo'],
      profilePhotoUrl: json['profile_photo_url'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'gender': gender,
      'level': level,
      'profile_photo': profilePhoto,
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? gender,
    String? level,
    String? profilePhoto,
    String? profilePhotoUrl,
    String? token,
    DateTime? lastSyncTime,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      level: level ?? this.level,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      token: token ?? this.token,
    );
  }
}
