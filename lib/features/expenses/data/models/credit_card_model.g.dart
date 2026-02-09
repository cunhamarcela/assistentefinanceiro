// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_card_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreditCardModel _$CreditCardModelFromJson(Map<String, dynamic> json) =>
    CreditCardModel(
      id: json['id'] as String,
      name: json['name'] as String,
      lastFourDigits: json['lastFourDigits'] as String,
      closingDay: (json['closingDay'] as num).toInt(),
      dueDay: (json['dueDay'] as num).toInt(),
      limit: (json['limit'] as num?)?.toDouble(),
      flag: json['flag'] as String?,
      color: json['color'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$CreditCardModelToJson(CreditCardModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'lastFourDigits': instance.lastFourDigits,
      'closingDay': instance.closingDay,
      'dueDay': instance.dueDay,
      'limit': instance.limit,
      'flag': instance.flag,
      'color': instance.color,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
