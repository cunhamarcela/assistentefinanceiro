// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      createdAt: _dateTimeFromJson((json['createdAt'] as num).toInt()),
      lastLogin:
          _dateTimeFromJsonNullable((json['lastLogin'] as num?)?.toInt()),
      emailVerified: json['emailVerified'] as bool,
      phoneNumber: json['phoneNumber'] as String?,
      customClaims: json['customClaims'] as Map<String, dynamic>?,
      updatedAt:
          _dateTimeFromJsonNullable((json['updatedAt'] as num?)?.toInt()),
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'photoUrl': instance.photoUrl,
      'createdAt': _dateTimeToJson(instance.createdAt),
      'lastLogin': _dateTimeToJsonNullable(instance.lastLogin),
      'emailVerified': instance.emailVerified,
      'phoneNumber': instance.phoneNumber,
      'customClaims': instance.customClaims,
      'updatedAt': _dateTimeToJsonNullable(instance.updatedAt),
    };
