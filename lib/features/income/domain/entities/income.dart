import 'package:equatable/equatable.dart';

/// Tipo de receita
enum IncomeType {
  salary,       // Salário
  freelance,    // Trabalho freelance
  investment,   // Investimentos
  rental,       // Aluguel
  gift,         // Presente/doação
  refund,       // Reembolso
  bonus,        // Bônus
  other,        // Outro
}

extension IncomeTypeExtension on IncomeType {
  String get displayName {
    switch (this) {
      case IncomeType.salary:
        return 'Salário';
      case IncomeType.freelance:
        return 'Freelance';
      case IncomeType.investment:
        return 'Investimento';
      case IncomeType.rental:
        return 'Aluguel';
      case IncomeType.gift:
        return 'Presente';
      case IncomeType.refund:
        return 'Reembolso';
      case IncomeType.bonus:
        return 'Bônus';
      case IncomeType.other:
        return 'Outro';
    }
  }

  String get icon {
    switch (this) {
      case IncomeType.salary:
        return '💼';
      case IncomeType.freelance:
        return '💻';
      case IncomeType.investment:
        return '📈';
      case IncomeType.rental:
        return '🏠';
      case IncomeType.gift:
        return '🎁';
      case IncomeType.refund:
        return '💵';
      case IncomeType.bonus:
        return '🎉';
      case IncomeType.other:
        return '💰';
    }
  }

  /// Cor associada ao tipo de receita (em HEX)
  int get colorValue {
    switch (this) {
      case IncomeType.salary:
        return 0xFF3CB371; // Verde
      case IncomeType.freelance:
        return 0xFF4A7FA7; // Azul
      case IncomeType.investment:
        return 0xFF9C27B0; // Roxo
      case IncomeType.rental:
        return 0xFFE9C46A; // Amarelo
      case IncomeType.gift:
        return 0xFFE76F51; // Coral
      case IncomeType.refund:
        return 0xFF26A69A; // Teal
      case IncomeType.bonus:
        return 0xFFFF9800; // Laranja
      case IncomeType.other:
        return 0xFF78909C; // Cinza azulado
    }
  }
}

/// Origem da receita
enum IncomeSource {
  manual,       // Criada manualmente
  aiAssistant,  // Criada pelo assistente de IA
  imported,     // Importada
  recurring,    // Gerada automaticamente (recorrente)
}

/// Entidade que representa uma receita/entrada de dinheiro
class Income extends Equatable {
  final String id;
  final double amount;
  final String description;
  final IncomeType type;
  final DateTime date;
  final String? notes;
  final bool isRecurring;
  final RecurrenceInfo? recurrenceInfo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final IncomeSource source;
  final String? aiParsedData;
  final double? aiConfidence;

  const Income({
    required this.id,
    required this.amount,
    required this.description,
    required this.type,
    required this.date,
    this.notes,
    this.isRecurring = false,
    this.recurrenceInfo,
    required this.createdAt,
    required this.updatedAt,
    this.source = IncomeSource.manual,
    this.aiParsedData,
    this.aiConfidence,
  });

  /// Factory para criar uma nova receita
  factory Income.create({
    required double amount,
    required String description,
    required IncomeType type,
    DateTime? date,
    String? notes,
    bool isRecurring = false,
    RecurrenceInfo? recurrenceInfo,
    IncomeSource source = IncomeSource.manual,
    String? aiParsedData,
    double? aiConfidence,
  }) {
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}_income_${amount.hashCode}';
    
    return Income(
      id: id,
      amount: amount,
      description: description,
      type: type,
      date: date ?? now,
      notes: notes,
      isRecurring: isRecurring,
      recurrenceInfo: recurrenceInfo,
      createdAt: now,
      updatedAt: now,
      source: source,
      aiParsedData: aiParsedData,
      aiConfidence: aiConfidence,
    );
  }

  /// Cria uma cópia com novos valores
  Income copyWith({
    String? id,
    double? amount,
    String? description,
    IncomeType? type,
    DateTime? date,
    String? notes,
    bool? isRecurring,
    RecurrenceInfo? recurrenceInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
    IncomeSource? source,
    String? aiParsedData,
    double? aiConfidence,
  }) {
    return Income(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      type: type ?? this.type,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceInfo: recurrenceInfo ?? this.recurrenceInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      source: source ?? this.source,
      aiParsedData: aiParsedData ?? this.aiParsedData,
      aiConfidence: aiConfidence ?? this.aiConfidence,
    );
  }

  /// Verifica se a receita é de hoje
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// Verifica se a receita é deste mês
  bool get isThisMonth {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Verifica se a receita é desta semana
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Retorna o mês da receita no formato MM/yyyy
  String get monthYear {
    return '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Verifica se foi criada pelo assistente de IA
  bool get isFromAi => source == IncomeSource.aiAssistant;

  /// Verifica se foi criada manualmente
  bool get isManual => source == IncomeSource.manual;

  @override
  List<Object?> get props => [
        id,
        amount,
        description,
        type,
        date,
        notes,
        isRecurring,
        recurrenceInfo,
        createdAt,
        updatedAt,
        source,
        aiParsedData,
        aiConfidence,
      ];

  @override
  String toString() {
    return 'Income(id: $id, amount: $amount, description: $description, type: ${type.name}, date: $date)';
  }
}

/// Frequência de recorrência
enum RecurrenceFrequency {
  daily,
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly,
}

extension RecurrenceFrequencyExtension on RecurrenceFrequency {
  String get displayName {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Diário';
      case RecurrenceFrequency.weekly:
        return 'Semanal';
      case RecurrenceFrequency.biweekly:
        return 'Quinzenal';
      case RecurrenceFrequency.monthly:
        return 'Mensal';
      case RecurrenceFrequency.quarterly:
        return 'Trimestral';
      case RecurrenceFrequency.yearly:
        return 'Anual';
    }
  }

  /// Dias entre recorrências
  int get intervalDays {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 1;
      case RecurrenceFrequency.weekly:
        return 7;
      case RecurrenceFrequency.biweekly:
        return 14;
      case RecurrenceFrequency.monthly:
        return 30;
      case RecurrenceFrequency.quarterly:
        return 90;
      case RecurrenceFrequency.yearly:
        return 365;
    }
  }
}

/// Informações de recorrência
class RecurrenceInfo extends Equatable {
  final RecurrenceFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final int? dayOfMonth; // Para recorrências mensais
  final int? dayOfWeek; // Para recorrências semanais (1-7)
  final bool isActive;

  const RecurrenceInfo({
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.dayOfMonth,
    this.dayOfWeek,
    this.isActive = true,
  });

  /// Calcula a próxima data de recorrência
  DateTime getNextDate(DateTime fromDate) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return fromDate.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return fromDate.add(const Duration(days: 7));
      case RecurrenceFrequency.biweekly:
        return fromDate.add(const Duration(days: 14));
      case RecurrenceFrequency.monthly:
        return DateTime(
          fromDate.year,
          fromDate.month + 1,
          dayOfMonth ?? fromDate.day,
        );
      case RecurrenceFrequency.quarterly:
        return DateTime(
          fromDate.year,
          fromDate.month + 3,
          dayOfMonth ?? fromDate.day,
        );
      case RecurrenceFrequency.yearly:
        return DateTime(
          fromDate.year + 1,
          fromDate.month,
          fromDate.day,
        );
    }
  }

  /// Verifica se a recorrência ainda está ativa
  bool get isCurrentlyActive {
    if (!isActive) return false;
    if (endDate == null) return true;
    return DateTime.now().isBefore(endDate!);
  }

  RecurrenceInfo copyWith({
    RecurrenceFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    int? dayOfMonth,
    int? dayOfWeek,
    bool? isActive,
  }) {
    return RecurrenceInfo(
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'frequency': frequency.name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'dayOfMonth': dayOfMonth,
    'dayOfWeek': dayOfWeek,
    'isActive': isActive,
  };

  factory RecurrenceInfo.fromJson(Map<String, dynamic> json) {
    return RecurrenceInfo(
      frequency: RecurrenceFrequency.values.firstWhere(
        (f) => f.name == json['frequency'],
        orElse: () => RecurrenceFrequency.monthly,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate'] as String) 
          : null,
      dayOfMonth: json['dayOfMonth'] as int?,
      dayOfWeek: json['dayOfWeek'] as int?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        frequency,
        startDate,
        endDate,
        dayOfMonth,
        dayOfWeek,
        isActive,
      ];
}