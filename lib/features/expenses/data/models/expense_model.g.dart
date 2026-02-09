// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpenseModel _$ExpenseModelFromJson(Map<String, dynamic> json) => ExpenseModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      categoryId: json['categoryId'] as String,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      paymentType:
          $enumDecodeNullable(_$PaymentTypeEnumMap, json['paymentType']) ??
              PaymentType.cash,
      creditCardId: json['creditCardId'] as String?,
      installmentInfo: ExpenseModel._installmentInfoFromJson(
          json['installmentInfo'] as Map<String, dynamic>?),
    );

Map<String, dynamic> _$ExpenseModelToJson(ExpenseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'description': instance.description,
      'categoryId': instance.categoryId,
      'date': instance.date.toIso8601String(),
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'paymentType': _$PaymentTypeEnumMap[instance.paymentType]!,
      'creditCardId': instance.creditCardId,
      'installmentInfo':
          ExpenseModel._installmentInfoToJson(instance.installmentInfo),
    };

const _$PaymentTypeEnumMap = {
  PaymentType.cash: 'cash',
  PaymentType.debit: 'debit',
  PaymentType.credit: 'credit',
  PaymentType.pix: 'pix',
  PaymentType.other: 'other',
};
