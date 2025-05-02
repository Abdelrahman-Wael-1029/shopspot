// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_product_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RestaurantProductCacheAdapter
    extends TypeAdapter<RestaurantProductCache> {
  @override
  final int typeId = 4;

  @override
  RestaurantProductCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RestaurantProductCache(
      productIds: (fields[0] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, RestaurantProductCache obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.productIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestaurantProductCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
