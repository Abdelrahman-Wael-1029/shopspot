// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_restaurant_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductRestaurantCacheAdapter
    extends TypeAdapter<ProductRestaurantCache> {
  @override
  final int typeId = 3;

  @override
  ProductRestaurantCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductRestaurantCache(
      productRestaurantsMap: (fields[0] as Map).map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<int>())),
    );
  }

  @override
  void write(BinaryWriter writer, ProductRestaurantCache obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.productRestaurantsMap);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductRestaurantCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
