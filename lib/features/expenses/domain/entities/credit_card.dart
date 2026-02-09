import 'package:equatable/equatable.dart';

/// Entidade que representa um cartão de crédito
class CreditCard extends Equatable {
  final String id;
  final String name;
  final String lastFourDigits;
  final int closingDay; // Dia de fechamento da fatura (1-31)
  final int dueDay; // Dia de vencimento da fatura (1-31)
  final double? limit; // Limite do cartão (opcional)
  final String? flag; // Bandeira (Visa, Mastercard, etc)
  final String? color; // Cor para identificação visual
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CreditCard({
    required this.id,
    required this.name,
    required this.lastFourDigits,
    required this.closingDay,
    required this.dueDay,
    this.limit,
    this.flag,
    this.color,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory para criar um novo cartão
  factory CreditCard.create({
    required String name,
    required String lastFourDigits,
    required int closingDay,
    required int dueDay,
    double? limit,
    String? flag,
    String? color,
  }) {
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}_${name.hashCode}';
    
    return CreditCard(
      id: id,
      name: name,
      lastFourDigits: lastFourDigits,
      closingDay: closingDay,
      dueDay: dueDay,
      limit: limit,
      flag: flag,
      color: color,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Cria uma cópia do cartão com novos valores
  CreditCard copyWith({
    String? id,
    String? name,
    String? lastFourDigits,
    int? closingDay,
    int? dueDay,
    double? limit,
    String? flag,
    String? color,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreditCard(
      id: id ?? this.id,
      name: name ?? this.name,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      closingDay: closingDay ?? this.closingDay,
      dueDay: dueDay ?? this.dueDay,
      limit: limit ?? this.limit,
      flag: flag ?? this.flag,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Retorna o nome do cartão formatado com os últimos 4 dígitos
  String get displayName => '$name •••• $lastFourDigits';

  /// Calcula o limite disponível baseado no limite e gastos
  double availableLimit(double usedAmount) {
    if (limit == null) return double.infinity;
    return limit! - usedAmount;
  }

  /// Verifica se o cartão está ativo
  bool get isAvailable => isActive;

  @override
  List<Object?> get props => [
        id,
        name,
        lastFourDigits,
        closingDay,
        dueDay,
        limit,
        flag,
        color,
        isActive,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'CreditCard(id: $id, name: $name, lastFourDigits: $lastFourDigits)';
  }
}

