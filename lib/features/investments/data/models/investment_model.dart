import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/investment.dart';

/// Model para persistência de investimentos
class InvestmentModel {
  final String id;
  final String userId;
  final double amount;
  final String description;
  final InvestmentType type;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? institution;
  final double? expectedReturn;
  final DateTime? maturityDate;

  const InvestmentModel({
    required this.id,
    required this.userId,
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

  /// Converter de entidade para model
  factory InvestmentModel.fromEntity(Investment entity, String userId) {
    return InvestmentModel(
      id: entity.id,
      userId: userId,
      amount: entity.amount,
      description: entity.description,
      type: entity.type,
      date: entity.date,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      institution: entity.institution,
      expectedReturn: entity.expectedReturn,
      maturityDate: entity.maturityDate,
    );
  }

  /// Converter para entidade
  Investment toEntity() {
    return Investment(
      id: id,
      amount: amount,
      description: description,
      type: type,
      date: date,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      institution: institution,
      expectedReturn: expectedReturn,
      maturityDate: maturityDate,
    );
  }

  /// Converter de Firestore
  factory InvestmentModel.fromFirestore(Map<String, dynamic> data) {
    return InvestmentModel(
      id: data['id'] as String,
      userId: data['userId'] as String,
      amount: (data['amount'] as num).toDouble(),
      description: data['description'] as String,
      type: InvestmentType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => InvestmentType.other,
      ),
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      institution: data['institution'] as String?,
      expectedReturn: data['expectedReturn'] != null
          ? (data['expectedReturn'] as num).toDouble()
          : null,
      maturityDate: data['maturityDate'] != null
          ? (data['maturityDate'] as Timestamp).toDate()
          : null,
    );
  }

  /// Converter para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'description': description,
      'type': type.name,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'institution': institution,
      'expectedReturn': expectedReturn,
      'maturityDate': maturityDate != null
          ? Timestamp.fromDate(maturityDate!)
          : null,
    };
  }

  /// Converter de SQLite
  factory InvestmentModel.fromSQLite(Map<String, dynamic> data) {
    return InvestmentModel(
      id: data['id'] as String,
      userId: data['userId'] as String,
      amount: (data['amount'] as num).toDouble(),
      description: data['description'] as String,
      type: InvestmentType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => InvestmentType.other,
      ),
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
      notes: data['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] as int),
      institution: data['institution'] as String?,
      expectedReturn: data['expectedReturn'] != null
          ? (data['expectedReturn'] as num).toDouble()
          : null,
      maturityDate: data['maturityDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['maturityDate'] as int)
          : null,
    );
  }

  /// Converter para SQLite
  Map<String, dynamic> toSQLite() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'description': description,
      'type': type.name,
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'institution': institution,
      'expectedReturn': expectedReturn,
      'maturityDate': maturityDate?.millisecondsSinceEpoch,
    };
  }

  InvestmentModel copyWith({
    String? id,
    String? userId,
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
    return InvestmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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
}



