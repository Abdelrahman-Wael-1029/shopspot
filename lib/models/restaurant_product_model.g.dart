// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_product_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RestaurantProductAdapter extends TypeAdapter<RestaurantProduct> {
  @override
  final int typeId = 3;

  @override
  RestaurantProduct read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return RestaurantProduct(
      restaurantId: fields[0] as int,
      productId: fields[1] as int,
      price: fields[2] as int,
      status: fields[3] as String,
      rating: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, RestaurantProduct obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.restaurantId)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.rating);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestaurantProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
