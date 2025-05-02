// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RestaurantAdapter extends TypeAdapter<Restaurant> {
  @override
  final int typeId = 2;

  @override
  Restaurant read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Restaurant(
      id: fields[0] as int,
      name: fields[1] as String,
      description: fields[2] as String,
      location: fields[3] as String,
      imageUrl: fields[4] as String?,
      latitude: fields[5] as double,
      longitude: fields[6] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Restaurant obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.location)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.latitude)
      ..writeByte(6)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestaurantAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
