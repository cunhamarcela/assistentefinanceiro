import 'package:equatable/equatable.dart';

/// Dados de comparação entre gastos reais e orçamento planejado
class BudgetComparisonData extends Equatable {
  final double totalBudget; // Orçamento total do período
  final double totalSpent; // Total gasto no período
  final double budgetAdherence; // % de aderência (0-100+)
  final int goalsCount; // Número de metas ativas
  final int goalsExceeded; // Número de metas excedidas
  final int goalsOnTrack; // Número de metas no caminho certo
  final Map<String, CategoryBudgetComparison> categoryComparisons; // Comparação por categoria

  const BudgetComparisonData({
    required this.totalBudget,
    required this.totalSpent,
    required this.budgetAdherence,
    required this.goalsCount,
    required this.goalsExceeded,
    required this.goalsOnTrack,
    required this.categoryComparisons,
  });

  /// Valor restante do orçamento
  double get remainingBudget => totalBudget - totalSpent;

  /// Se o orçamento foi excedido
  bool get isExceeded => totalSpent > totalBudget;

  /// Percentual de metas excedidas
  double get exceededGoalsPercentage {
    if (goalsCount == 0) return 0.0;
    return (goalsExceeded / goalsCount) * 100;
  }

  /// Percentual de metas no caminho certo
  double get onTrackGoalsPercentage {
    if (goalsCount == 0) return 0.0;
    return (goalsOnTrack / goalsCount) * 100;
  }

  @override
  List<Object?> get props => [
        totalBudget,
        totalSpent,
        budgetAdherence,
        goalsCount,
        goalsExceeded,
        goalsOnTrack,
        categoryComparisons,
      ];
}

/// Comparação de orçamento por categoria
class CategoryBudgetComparison extends Equatable {
  final String categoryId;
  final String categoryName;
  final double budgetLimit; // Limite da meta
  final double spent; // Gasto real
  final double adherence; // % de aderência
  final bool isExceeded; // Se excedeu o limite

  const CategoryBudgetComparison({
    required this.categoryId,
    required this.categoryName,
    required this.budgetLimit,
    required this.spent,
    required this.adherence,
    required this.isExceeded,
  });

  /// Valor excedido (se houver)
  double get excessAmount => isExceeded ? spent - budgetLimit : 0.0;

  /// Valor restante (se não excedeu)
  double get remainingAmount => isExceeded ? 0.0 : budgetLimit - spent;

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        budgetLimit,
        spent,
        adherence,
        isExceeded,
      ];
}



