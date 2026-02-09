import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../../domain/entities/financial_profile.dart';

/// Model para persistência do perfil financeiro
class FinancialProfileModel {
  final String id;
  final String userId;
  final double monthlyIncome;
  final double totalBudget;
  final double monthlyInvestmentGoal;
  final Map<String, double> categoryBudgets;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FinancialProfileModel({
    required this.id,
    required this.userId,
    required this.monthlyIncome,
    required this.totalBudget,
    this.monthlyInvestmentGoal = 0.0,
    required this.categoryBudgets,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Converter de entidade para model
  factory FinancialProfileModel.fromEntity(FinancialProfile entity) {
    return FinancialProfileModel(
      id: entity.id,
      userId: entity.userId,
      monthlyIncome: entity.monthlyIncome,
      totalBudget: entity.totalBudget,
      monthlyInvestmentGoal: entity.monthlyInvestmentGoal,
      categoryBudgets: Map.from(entity.categoryBudgets),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Converter para entidade
  FinancialProfile toEntity() {
    return FinancialProfile(
      id: id,
      userId: userId,
      monthlyIncome: monthlyIncome,
      totalBudget: totalBudget,
      monthlyInvestmentGoal: monthlyInvestmentGoal,
      categoryBudgets: Map.from(categoryBudgets),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Converter de Firestore
  factory FinancialProfileModel.fromFirestore(Map<String, dynamic> data) {
    // Converter categoryBudgets de Map<String, dynamic> para Map<String, double>
    final budgetsData = data['categoryBudgets'] as Map<String, dynamic>? ?? {};
    final categoryBudgets = budgetsData.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    return FinancialProfileModel(
      id: data['id'] as String,
      userId: data['userId'] as String,
      monthlyIncome: (data['monthlyIncome'] as num).toDouble(),
      totalBudget: (data['totalBudget'] as num).toDouble(),
      monthlyInvestmentGoal: (data['monthlyInvestmentGoal'] as num?)?.toDouble() ?? 0.0,
      categoryBudgets: categoryBudgets,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Converter para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'monthlyIncome': monthlyIncome,
      'totalBudget': totalBudget,
      'monthlyInvestmentGoal': monthlyInvestmentGoal,
      'categoryBudgets': categoryBudgets,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Converter de SQLite
  factory FinancialProfileModel.fromSQLite(Map<String, dynamic> data) {
    // Decodificar JSON string para Map
    final budgetsJson = data['categoryBudgets'] as String? ?? '{}';
    final budgetsData = jsonDecode(budgetsJson) as Map<String, dynamic>;
    final categoryBudgets = budgetsData.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    return FinancialProfileModel(
      id: data['id'] as String,
      userId: data['userId'] as String,
      monthlyIncome: (data['monthlyIncome'] as num).toDouble(),
      totalBudget: (data['totalBudget'] as num).toDouble(),
      monthlyInvestmentGoal: (data['monthlyInvestmentGoal'] as num?)?.toDouble() ?? 0.0,
      categoryBudgets: categoryBudgets,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] as int),
    );
  }

  /// Converter para SQLite
  Map<String, dynamic> toSQLite() {
    return {
      'id': id,
      'userId': userId,
      'monthlyIncome': monthlyIncome,
      'totalBudget': totalBudget,
      'monthlyInvestmentGoal': monthlyInvestmentGoal,
      'categoryBudgets': jsonEncode(categoryBudgets),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  FinancialProfileModel copyWith({
    String? id,
    String? userId,
    double? monthlyIncome,
    double? totalBudget,
    double? monthlyInvestmentGoal,
    Map<String, double>? categoryBudgets,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinancialProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      totalBudget: totalBudget ?? this.totalBudget,
      monthlyInvestmentGoal: monthlyInvestmentGoal ?? this.monthlyInvestmentGoal,
      categoryBudgets: categoryBudgets ?? Map.from(this.categoryBudgets),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Criar perfil padrão para novo usuário
  factory FinancialProfileModel.createDefault(String userId) {
    final now = DateTime.now();
    return FinancialProfileModel(
      id: 'profile_$userId',
      userId: userId,
      monthlyIncome: 0.0,
      totalBudget: 0.0,
      monthlyInvestmentGoal: 0.0,
      categoryBudgets: {},
      createdAt: now,
      updatedAt: now,
    );
  }
}
