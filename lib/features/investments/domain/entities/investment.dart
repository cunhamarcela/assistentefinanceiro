import 'package:equatable/equatable.dart';

/// Tipo de investimento
enum InvestmentType {
  savings,        // Poupança
  fixedIncome,    // Renda Fixa (CDB, Tesouro Direto, etc.)
  stocks,         // Ações
  funds,          // Fundos de Investimento
  realEstate,     // Imóveis
  crypto,          // Criptomoedas
  other,          // Outros
}

extension InvestmentTypeExtension on InvestmentType {
  String get displayName {
    switch (this) {
      case InvestmentType.savings:
        return 'Poupança';
      case InvestmentType.fixedIncome:
        return 'Renda Fixa';
      case InvestmentType.stocks:
        return 'Ações';
      case InvestmentType.funds:
        return 'Fundos';
      case InvestmentType.realEstate:
        return 'Imóveis';
      case InvestmentType.crypto:
        return 'Criptomoedas';
      case InvestmentType.other:
        return 'Outros';
    }
  }

  String get icon {
    switch (this) {
      case InvestmentType.savings:
        return '💰';
      case InvestmentType.fixedIncome:
        return '📈';
      case InvestmentType.stocks:
        return '📊';
      case InvestmentType.funds:
        return '🏦';
      case InvestmentType.realEstate:
        return '🏠';
      case InvestmentType.crypto:
        return '₿';
      case InvestmentType.other:
        return '💼';
    }
  }
}

/// Entidade que representa um investimento
class Investment extends Equatable {
  final String id;
  final double amount;
  final String description;
  final InvestmentType type;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Campos opcionais para detalhes do investimento
  final String? institution; // Instituição financeira
  final double? expectedReturn; // Retorno esperado (anual %)
  final DateTime? maturityDate; // Data de vencimento (se aplicável)

  const Investment({
    required this.id,
    required this.amount,
    required this.description,
    required this.type,
    required this.date,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.institution,
    this.expectedReturn,
    this.maturityDate,
  });

  /// Factory para criar um novo investimento
  factory Investment.create({
    required double amount,
    required String description,
    required InvestmentType type,
    DateTime? date,
    String? notes,
    String? institution,
    double? expectedReturn,
    DateTime? maturityDate,
  }) {
    final now = DateTime.now();
    final id = 'inv_${now.millisecondsSinceEpoch}_${amount.hashCode}';
    
    return Investment(
      id: id,
      amount: amount,
      description: description,
      type: type,
      date: date ?? now,
      notes: notes,
      createdAt: now,
      updatedAt: now,
      institution: institution,
      expectedReturn: expectedReturn,
      maturityDate: maturityDate,
    );
  }

  /// Cria uma cópia do investimento com novos valores
  Investment copyWith({
    String? id,
    double? amount,
    String? description,
    InvestmentType? type,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? institution,
    double? expectedReturn,
    DateTime? maturityDate,
  }) {
    return Investment(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      type: type ?? this.type,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      institution: institution ?? this.institution,
      expectedReturn: expectedReturn ?? this.expectedReturn,
      maturityDate: maturityDate ?? this.maturityDate,
    );
  }

  /// Verifica se o investimento é de hoje
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// Verifica se o investimento é deste mês
  bool get isThisMonth {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Retorna o mês do investimento no formato MM/yyyy
  String get monthYear {
    return '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Verifica se tem data de vencimento
  bool get hasMaturityDate => maturityDate != null;

  /// Verifica se está vencido
  bool get isMatured {
    if (maturityDate == null) return false;
    return DateTime.now().isAfter(maturityDate!);
  }

  /// Retorna o retorno esperado anual em valor (se aplicável)
  double? get expectedReturnAmount {
    if (expectedReturn == null) return null;
    return amount * (expectedReturn! / 100);
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        description,
        type,
        date,
        notes,
        createdAt,
        updatedAt,
        institution,
        expectedReturn,
        maturityDate,
      ];

  @override
  String toString() {
    return 'Investment(id: $id, amount: $amount, description: $description, type: ${type.name}, date: $date)';
  }
}



