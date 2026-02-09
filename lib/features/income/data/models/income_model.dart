import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/income.dart';

/// Model para serialização do Income
class IncomeModel extends Income {
  const IncomeModel({
    required super.id,
    required super.amount,
    required super.description,
    required super.type,
    required super.date,
    super.notes,
    super.isRecurring,
    super.recurrenceInfo,
    required super.createdAt,
    required super.updatedAt,
    super.source,
    super.aiParsedData,
    super.aiConfidence,
  });

  /// Factory para criar IncomeModel a partir de Entity
  factory IncomeModel.fromEntity(Income income) {
    return IncomeModel(
      id: income.id,
      amount: income.amount,
      description: income.description,
      type: income.type,
      date: income.date,
      notes: income.notes,
      isRecurring: income.isRecurring,
      recurrenceInfo: income.recurrenceInfo,
      createdAt: income.createdAt,
      updatedAt: income.updatedAt,
      source: income.source,
      aiParsedData: income.aiParsedData,
      aiConfidence: income.aiConfidence,
    );
  }

  /// Converte para Entity
  Income toEntity() {
    return Income(
      id: id,
      amount: amount,
      description: description,
      type: type,
      date: date,
      notes: notes,
      isRecurring: isRecurring,
      recurrenceInfo: recurrenceInfo,
      createdAt: createdAt,
      updatedAt: updatedAt,
      source: source,
      aiParsedData: aiParsedData,
      aiConfidence: aiConfidence,
    );
  }

  /// Factory para criar nova receita
  factory IncomeModel.create({
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
    final income = Income.create(
      amount: amount,
      description: description,
      type: type,
      date: date,
      notes: notes,
      isRecurring: isRecurring,
      recurrenceInfo: recurrenceInfo,
      source: source,
      aiParsedData: aiParsedData,
      aiConfidence: aiConfidence,
    );
    
    return IncomeModel.fromEntity(income);
  }

  /// Factory para criar a partir de JSON
  factory IncomeModel.fromJson(Map<String, dynamic> json) {
    return IncomeModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      type: IncomeType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => IncomeType.other,
      ),
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurrenceInfo: json['recurrenceInfo'] != null
          ? RecurrenceInfo.fromJson(json['recurrenceInfo'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      source: json['source'] != null
          ? IncomeSource.values.firstWhere(
              (s) => s.name == json['source'],
              orElse: () => IncomeSource.manual,
            )
          : IncomeSource.manual,
      aiParsedData: json['aiParsedData'] as String?,
      aiConfidence: (json['aiConfidence'] as num?)?.toDouble(),
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'type': type.name,
      'date': date.toIso8601String(),
      'notes': notes,
      'isRecurring': isRecurring,
      'recurrenceInfo': recurrenceInfo?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'source': source.name,
      'aiParsedData': aiParsedData,
      'aiConfidence': aiConfidence,
    };
  }

  /// Factory para criar a partir de Firestore
  factory IncomeModel.fromFirestore(Map<String, dynamic> map) {
    return IncomeModel(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      type: IncomeType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => IncomeType.other,
      ),
      date: (map['date'] as Timestamp).toDate(),
      notes: map['notes'] as String?,
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurrenceInfo: map['recurrenceInfo'] != null
          ? RecurrenceInfo.fromJson(map['recurrenceInfo'] as Map<String, dynamic>)
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      source: map['source'] != null
          ? IncomeSource.values.firstWhere(
              (s) => s.name == map['source'],
              orElse: () => IncomeSource.manual,
            )
          : IncomeSource.manual,
      aiParsedData: map['aiParsedData'] as String?,
      aiConfidence: (map['aiConfidence'] as num?)?.toDouble(),
    );
  }

  /// Converte para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'type': type.name,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'isRecurring': isRecurring,
      'recurrenceInfo': recurrenceInfo?.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'source': source.name,
      'aiParsedData': aiParsedData,
      'aiConfidence': aiConfidence,
      'searchTerms': _generateSearchTerms(),
    };
  }

  /// Factory para criar a partir de SQLite
  factory IncomeModel.fromSQLite(Map<String, dynamic> map) {
    return IncomeModel(
      id: map['id'] as String,
      amount: map['amount'] as double,
      description: map['description'] as String,
      type: IncomeType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => IncomeType.other,
      ),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      notes: map['notes'] as String?,
      isRecurring: (map['isRecurring'] as int? ?? 0) == 1,
      recurrenceInfo: map['recurrenceInfo'] != null
          ? RecurrenceInfo.fromJson(
              jsonDecode(map['recurrenceInfo'] as String) as Map<String, dynamic>)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      source: map['source'] != null
          ? IncomeSource.values.firstWhere(
              (s) => s.name == map['source'],
              orElse: () => IncomeSource.manual,
            )
          : IncomeSource.manual,
      aiParsedData: map['aiParsedData'] as String?,
      aiConfidence: map['aiConfidence'] as double?,
    );
  }

  /// Converte para SQLite
  Map<String, dynamic> toSQLite() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'type': type.name,
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
      'isRecurring': isRecurring ? 1 : 0,
      'recurrenceInfo': recurrenceInfo != null 
          ? jsonEncode(recurrenceInfo!.toJson()) 
          : null,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'source': source.name,
      'aiParsedData': aiParsedData,
      'aiConfidence': aiConfidence,
    };
  }

  /// Cria uma cópia com novos valores
  @override
  IncomeModel copyWith({
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
    return IncomeModel(
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

  /// Gera termos de busca para Firestore
  List<String> _generateSearchTerms() {
    final terms = <String>[];
    
    // Adiciona palavras da descrição
    terms.addAll(description.toLowerCase().split(' '));
    
    // Adiciona tipo
    terms.add(type.name.toLowerCase());
    terms.add(type.displayName.toLowerCase());
    
    // Adiciona palavras das notas se existirem
    if (notes != null && notes!.isNotEmpty) {
      terms.addAll(notes!.toLowerCase().split(' '));
    }
    
    // Remove termos vazios e duplicados
    return terms.where((term) => term.isNotEmpty).toSet().toList();
  }
}
