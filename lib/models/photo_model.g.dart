// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PhotoAdapter extends TypeAdapter<Photo> {
  @override
  final int typeId = 0;

  @override
  Photo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Photo(
      imagePath: fields[0] as String,
      dateTaken: fields[1] as DateTime,
      id: fields[2] as String,
      isStrip: fields[3] as bool,
      photoCount: fields[4] as int,
      individualPhotoPaths: (fields[5] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Photo obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.imagePath)
      ..writeByte(1)
      ..write(obj.dateTaken)
      ..writeByte(2)
      ..write(obj.id)
      ..writeByte(3)
      ..write(obj.isStrip)
      ..writeByte(4)
      ..write(obj.photoCount)
      ..writeByte(5)
      ..write(obj.individualPhotoPaths);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
