// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installment_info_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstallmentInfoModel _$InstallmentInfoModelFromJson(
        Map<String, dynamic> json) =>
    InstallmentInfoModel(
      currentInstallment: (json['currentInstallment'] as num).toInt(),
      totalInstallments: (json['totalInstallments'] as num).toInt(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      installmentAmount: (json['installmentAmount'] as num).toDouble(),
      interestRate: (json['interestRate'] as num?)?.toDouble() ?? 0,
      parentExpenseId: json['parentExpenseId'] as String?,
    );

Map<String, dynamic> _$InstallmentInfoModelToJson(
        InstallmentInfoModel instance) =>
    <String, dynamic>{
      'currentInstallment': instance.currentInstallment,
      'totalInstallments': instance.totalInstallments,
      'totalAmount': instance.totalAmount,
      'installmentAmount': instance.installmentAmount,
      'interestRate': instance.interestRate,
      'parentExpenseId': instance.parentExpenseId,
    };
