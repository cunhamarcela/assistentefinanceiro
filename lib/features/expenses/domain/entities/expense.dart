import 'package:equatable/equatable.dart';
import 'installment_info.dart';

/// Tipo de pagamento da despesa
enum PaymentType {
  cash,        // Dinheiro
  debit,       // Débito
  credit,      // Crédito
  pix,         // PIX
  other,       // Outro
}

/// Origem/fonte da despesa
enum ExpenseSource {
  manual,       // Criada manualmente pelo usuário
  aiAssistant,  // Criada pelo assistente de IA via chat
  imported,     // Importada de arquivo ou integração
}

extension ExpenseSourceExtension on ExpenseSource {
  String get displayName {
    switch (this) {
      case ExpenseSource.manual:
        return 'Manual';
      case ExpenseSource.aiAssistant:
        return 'Assistente IA';
      case ExpenseSource.imported:
        return 'Importada';
    }
  }

  String get icon {
    switch (this) {
      case ExpenseSource.manual:
        return '✏️';
      case ExpenseSource.aiAssistant:
        return '🤖';
      case ExpenseSource.imported:
        return '📥';
    }
  }
}

class Expense extends Equatable {
  final String id;
  final double amount;
  final String description;
  final String categoryId;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Campos para pagamento com cartão
  final PaymentType paymentType;
  final String? creditCardId; // ID do cartão de crédito usado
  final InstallmentInfo? installmentInfo; // Informações de parcelamento
  
  // Campos para rastreamento de origem e IA
  final ExpenseSource source; // Origem da despesa (manual, IA, importada)
  final String? aiParsedData; // JSON com dados extraídos pela IA (opcional)
  final double? aiConfidence; // Score de confiança do parsing da IA (0.0 a 1.0)

  const Expense({
    required this.id,
    required this.amount,
    required this.description,
    required this.categoryId,
    required this.date,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.paymentType = PaymentType.cash,
    this.creditCardId,
    this.installmentInfo,
    this.source = ExpenseSource.manual,
    this.aiParsedData,
    this.aiConfidence,
  });

  /// Factory para criar uma nova despesa
  factory Expense.create({
    required double amount,
    required String description,
    required String categoryId,
    DateTime? date,
    String? notes,
    PaymentType paymentType = PaymentType.cash,
    String? creditCardId,
    InstallmentInfo? installmentInfo,
    ExpenseSource source = ExpenseSource.manual,
    String? aiParsedData,
    double? aiConfidence,
  }) {
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}_${amount.hashCode}';
    
    return Expense(
      id: id,
      amount: amount,
      description: description,
      categoryId: categoryId,
      date: date ?? now,
      notes: notes,
      createdAt: now,
      updatedAt: now,
      paymentType: paymentType,
      creditCardId: creditCardId,
      installmentInfo: installmentInfo,
      source: source,
      aiParsedData: aiParsedData,
      aiConfidence: aiConfidence,
    );
  }

  /// Cria uma cópia da despesa com novos valores
  Expense copyWith({
    String? id,
    double? amount,
    String? description,
    String? categoryId,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    PaymentType? paymentType,
    String? creditCardId,
    InstallmentInfo? installmentInfo,
    ExpenseSource? source,
    String? aiParsedData,
    double? aiConfidence,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      paymentType: paymentType ?? this.paymentType,
      creditCardId: creditCardId ?? this.creditCardId,
      installmentInfo: installmentInfo ?? this.installmentInfo,
      source: source ?? this.source,
      aiParsedData: aiParsedData ?? this.aiParsedData,
      aiConfidence: aiConfidence ?? this.aiConfidence,
    );
  }

  /// Verifica se a despesa é de hoje
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// Verifica se a despesa é deste mês
  bool get isThisMonth {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Verifica se a despesa é desta semana
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Retorna o mês da despesa no formato MM/yyyy
  String get monthYear {
    return '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Verifica se é uma despesa parcelada
  bool get isInstallment => installmentInfo != null && installmentInfo!.isInstallment;

  /// Verifica se foi pago com cartão de crédito
  bool get isCreditCard => paymentType == PaymentType.credit;

  /// Verifica se é uma parcela (não é a despesa original)
  bool get isInstallmentPart => installmentInfo?.parentExpenseId != null;

  /// Verifica se foi criada pelo assistente de IA
  bool get isFromAi => source == ExpenseSource.aiAssistant;

  /// Verifica se foi criada manualmente
  bool get isManual => source == ExpenseSource.manual;

  /// Verifica se foi importada
  bool get isImported => source == ExpenseSource.imported;

  /// Verifica se tem dados de parsing da IA
  bool get hasAiData => aiParsedData != null && aiParsedData!.isNotEmpty;

  /// Verifica se a confiança da IA é alta (>= 80%)
  bool get hasHighAiConfidence => aiConfidence != null && aiConfidence! >= 0.8;

  @override
  List<Object?> get props => [
        id,
        amount,
        description,
        categoryId,
        date,
        notes,
        createdAt,
        updatedAt,
        paymentType,
        creditCardId,
        installmentInfo,
        source,
        aiParsedData,
        aiConfidence,
      ];

  @override
  String toString() {
    return 'Expense(id: $id, amount: $amount, description: $description, categoryId: $categoryId, date: $date, source: ${source.name})';
  }
}
