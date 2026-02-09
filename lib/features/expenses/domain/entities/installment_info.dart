import 'package:equatable/equatable.dart';

/// Informações sobre parcelamento de uma despesa
class InstallmentInfo extends Equatable {
  final int currentInstallment; // Parcela atual (ex: 1 de 12)
  final int totalInstallments; // Total de parcelas
  final double totalAmount; // Valor total da compra
  final double installmentAmount; // Valor de cada parcela
  final double interestRate; // Taxa de juros (0 = sem juros)
  final String? parentExpenseId; // ID da despesa original (para parcelas)

  const InstallmentInfo({
    required this.currentInstallment,
    required this.totalInstallments,
    required this.totalAmount,
    required this.installmentAmount,
    this.interestRate = 0,
    this.parentExpenseId,
  });

  /// Verifica se a compra é parcelada
  bool get isInstallment => totalInstallments > 1;

  /// Verifica se tem juros
  bool get hasInterest => interestRate > 0;

  /// Verifica se é a primeira parcela
  bool get isFirstInstallment => currentInstallment == 1;

  /// Verifica se é a última parcela
  bool get isLastInstallment => currentInstallment == totalInstallments;

  /// Calcula o valor total com juros
  double get totalAmountWithInterest {
    if (!hasInterest) return totalAmount;
    return installmentAmount * totalInstallments;
  }

  /// Retorna o texto formatado da parcela (ex: "3/12")
  String get displayText => '$currentInstallment/$totalInstallments';

  /// Cria uma cópia com novos valores
  InstallmentInfo copyWith({
    int? currentInstallment,
    int? totalInstallments,
    double? totalAmount,
    double? installmentAmount,
    double? interestRate,
    String? parentExpenseId,
  }) {
    return InstallmentInfo(
      currentInstallment: currentInstallment ?? this.currentInstallment,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      totalAmount: totalAmount ?? this.totalAmount,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      interestRate: interestRate ?? this.interestRate,
      parentExpenseId: parentExpenseId ?? this.parentExpenseId,
    );
  }

  @override
  List<Object?> get props => [
        currentInstallment,
        totalInstallments,
        totalAmount,
        installmentAmount,
        interestRate,
        parentExpenseId,
      ];

  @override
  String toString() {
    return 'InstallmentInfo($displayText - R\$ $installmentAmount${hasInterest ? ' com juros' : ''})';
  }
}

