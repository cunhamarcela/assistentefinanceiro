import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/financial_goal.dart';

/// Model para persistência de metas financeiras
class FinancialGoalModel {
  final String id;
  final String userId;
  final String categoryId;
  final String categoryName;
  final double monthlyLimit;
  final double currentSpent;
  final DateTime month;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FinancialGoalModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.monthlyLimit,
    required this.currentSpent,
    required this.month,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Converter de entidade para model
  factory FinancialGoalModel.fromEntity(FinancialGoal entity, String userId) {
    return FinancialGoalModel(
      id: entity.id,
      userId: userId,
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      monthlyLimit: entity.monthlyLimit,
      currentSpent: entity.currentSpent,
      month: entity.month,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Converter para entidade
  FinancialGoal toEntity() {
    return FinancialGoal(
      id: id,
      categoryId: categoryId,
      categoryName: categoryName,
      monthlyLimit: monthlyLimit,
      currentSpent: currentSpent,
      month: month,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Converter de Firestore
  factory FinancialGoalModel.fromFirestore(Map<String, dynamic> data) {
    return FinancialGoalModel(
      id: data['id'] as String,
      userId: data['userId'] as String,
      categoryId: data['categoryId'] as String,
      categoryName: data['categoryName'] as String,
      monthlyLimit: (data['monthlyLimit'] as num).toDouble(),
      currentSpent: (data['currentSpent'] as num).toDouble(),
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
      'categoryId': categoryId,
      'categoryName': categoryName,
      'monthlyLimit': monthlyLimit,
      'currentSpent': currentSpent,
      'month': Timestamp.fromDate(month),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Converter de SQLite
  factory FinancialGoalModel.fromSQLite(Map<String, dynamic> data) {
    return FinancialGoalModel(
      id: data['id'] as String,
      userId: data['userId'] as String,
      categoryId: data['categoryId'] as String,
      categoryName: data['categoryName'] as String,
      monthlyLimit: (data['monthlyLimit'] as num).toDouble(),
      currentSpent: (data['currentSpent'] as num).toDouble(),
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
      'categoryId': categoryId,
      'categoryName': categoryName,
      'monthlyLimit': monthlyLimit,
      'currentSpent': currentSpent,
      'month': month.millisecondsSinceEpoch,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  FinancialGoalModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? categoryName,
    double? monthlyLimit,
    double? currentSpent,
    DateTime? month,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinancialGoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      currentSpent: currentSpent ?? this.currentSpent,
      month: month ?? this.month,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Atualizar valor gasto
  FinancialGoalModel updateSpentAmount(double newAmount) {
    return copyWith(
      currentSpent: newAmount,
      updatedAt: DateTime.now(),
    );
  }
}
