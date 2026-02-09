import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/investment.dart';
import '../../domain/entities/investment_goal.dart';

/// Model para persistência de metas de investimento
class InvestmentGoalModel {
  final String id;
  final String userId;
  final InvestmentType? type;
  final String? typeName;
  final double monthlyTarget;
  final double currentInvested;
  final DateTime month;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvestmentGoalModel({
    required this.id,
    required this.userId,
    this.type,
    this.typeName,
    required this.monthlyTarget,
    required this.currentInvested,
    required this.month,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Converter de entidade para model
  factory InvestmentGoalModel.fromEntity(InvestmentGoal entity, String userId) {
    return InvestmentGoalModel(
      id: entity.id,
      userId: userId,
      type: entity.type,
      typeName: entity.typeName,
      monthlyTarget: entity.monthlyTarget,
      currentInvested: entity.currentInvested,
      month: entity.month,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Converter para entidade
  InvestmentGoal toEntity() {
    return InvestmentGoal(
      id: id,
      type: type,
      typeName: typeName,
      monthlyTarget: monthlyTarget,
      currentInvested: currentInvested,
      month: month,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Converter de Firestore
  factory InvestmentGoalModel.fromFirestore(Map<String, dynamic> data) {
    return InvestmentGoalModel(
      id: data['id'] as String,
      userId: data['userId'] as String,
      type: data['type'] != null
          ? InvestmentType.values.firstWhere(
              (e) => e.name == data['type'],
              orElse: () => InvestmentType.other,
            )
          : null,
      typeName: data['typeName'] as String?,
      monthlyTarget: (data['monthlyTarget'] as num).toDouble(),
      currentInvested: (data['currentInvested'] as num).toDouble(),
      month: (data['month'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Converter para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'type': type?.name,
      'typeName': typeName,
      'monthlyTarget': monthlyTarget,
      'currentInvested': currentInvested,
      'month': Timestamp.fromDate(month),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Converter de SQLite
  factory InvestmentGoalModel.fromSQLite(Map<String, dynamic> data) {
    return InvestmentGoalModel(
      id: data['id'] as String,
      userId: data['userId'] as String,
      type: data['type'] != null
          ? InvestmentType.values.firstWhere(
              (e) => e.name == data['type'],
              orElse: () => InvestmentType.other,
            )
          : null,
      typeName: data['typeName'] as String?,
      monthlyTarget: (data['monthlyTarget'] as num).toDouble(),
      currentInvested: (data['currentInvested'] as num).toDouble(),
      month: DateTime.fromMillisecondsSinceEpoch(data['month'] as int),
      isActive: (data['isActive'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] as int),
    );
  }

  /// Converter para SQLite
  Map<String, dynamic> toSQLite() {
    return {
      'id': id,
      'userId': userId,
      'type': type?.name,
      'typeName': typeName,
      'monthlyTarget': monthlyTarget,
      'currentInvested': currentInvested,
      'month': month.millisecondsSinceEpoch,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  InvestmentGoalModel copyWith({
    String? id,
    String? userId,
    InvestmentType? type,
    String? typeName,
    double? monthlyTarget,
    double? currentInvested,
    DateTime? month,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvestmentGoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      typeName: typeName ?? this.typeName,
      monthlyTarget: monthlyTarget ?? this.monthlyTarget,
      currentInvested: currentInvested ?? this.currentInvested,
      month: month ?? this.month,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

