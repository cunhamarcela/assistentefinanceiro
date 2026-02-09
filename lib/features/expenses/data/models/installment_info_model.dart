import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/installment_info.dart';

part 'installment_info_model.g.dart';

@JsonSerializable()
class InstallmentInfoModel extends InstallmentInfo {
  const InstallmentInfoModel({
    required super.currentInstallment,
    required super.totalInstallments,
    required super.totalAmount,
    required super.installmentAmount,
    super.interestRate,
    super.parentExpenseId,
  });

  /// Factory para criar InstallmentInfoModel a partir de JSON
  factory InstallmentInfoModel.fromJson(Map<String, dynamic> json) =>
      _$InstallmentInfoModelFromJson(json);

  /// Converte InstallmentInfoModel para JSON
  Map<String, dynamic> toJson() => _$InstallmentInfoModelToJson(this);

  /// Factory para criar InstallmentInfoModel a partir de Entity
  factory InstallmentInfoModel.fromEntity(InstallmentInfo info) {
    return InstallmentInfoModel(
      currentInstallment: info.currentInstallment,
      totalInstallments: info.totalInstallments,
      totalAmount: info.totalAmount,
      installmentAmount: info.installmentAmount,
      interestRate: info.interestRate,
      parentExpenseId: info.parentExpenseId,
    );
  }

  /// Converte InstallmentInfoModel para Entity
  InstallmentInfo toEntity() {
    return InstallmentInfo(
      currentInstallment: currentInstallment,
      totalInstallments: totalInstallments,
      totalAmount: totalAmount,
      installmentAmount: installmentAmount,
      interestRate: interestRate,
      parentExpenseId: parentExpenseId,
    );
  }

  /// Cria uma cópia com novos valores
  InstallmentInfoModel copyWith({
    int? currentInstallment,
    int? totalInstallments,
    double? totalAmount,
    double? installmentAmount,
    double? interestRate,
    String? parentExpenseId,
  }) {
    return InstallmentInfoModel(
      currentInstallment: currentInstallment ?? this.currentInstallment,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      totalAmount: totalAmount ?? this.totalAmount,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      interestRate: interestRate ?? this.interestRate,
      parentExpenseId: parentExpenseId ?? this.parentExpenseId,
    );
  }
}

