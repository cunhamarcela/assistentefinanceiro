/// Entidade que representa uma meta financeira
class FinancialGoal {
  final String id;
  final String categoryId;
  final String categoryName;
  final double monthlyLimit;
  final double currentSpent;
  final DateTime month;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FinancialGoal({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.monthlyLimit,
    required this.currentSpent,
    required this.month,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Percentual gasto da meta (0.0 a 1.0+)
  double get progressPercentage => monthlyLimit > 0 ? currentSpent / monthlyLimit : 0.0;

  /// Valor restante da meta
  double get remainingAmount => monthlyLimit - currentSpent;

  /// Se a meta foi excedida
  bool get isExceeded => currentSpent > monthlyLimit;

  /// Status da meta baseado no percentual gasto
  FinancialGoalStatus get status {
    if (!isActive) return FinancialGoalStatus.inactive;
    if (progressPercentage >= 1.0) return FinancialGoalStatus.exceeded;
    if (progressPercentage >= 0.8) return FinancialGoalStatus.warning;
    if (progressPercentage >= 0.5) return FinancialGoalStatus.onTrack;
    return FinancialGoalStatus.good;
  }

  FinancialGoal copyWith({
    String? id,
    String? categoryId,
    String? categoryName,
    double? monthlyLimit,
    double? currentSpent,
    DateTime? month,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinancialGoal(
      id: id ?? this.id,
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
}

/// Status de uma meta financeira
enum FinancialGoalStatus {
  good,      // 0-50% gasto
  onTrack,   // 50-80% gasto
  warning,   // 80-100% gasto
  exceeded,  // >100% gasto
  inactive,  // Meta desativada
}

extension FinancialGoalStatusExtension on FinancialGoalStatus {
  String get displayName {
    switch (this) {
      case FinancialGoalStatus.good:
        return 'Dentro do Orçamento';
      case FinancialGoalStatus.onTrack:
        return 'No Caminho Certo';
      case FinancialGoalStatus.warning:
        return 'Atenção';
      case FinancialGoalStatus.exceeded:
        return 'Orçamento Excedido';
      case FinancialGoalStatus.inactive:
        return 'Inativa';
    }
  }

  String get description {
    switch (this) {
      case FinancialGoalStatus.good:
        return 'Você está gastando bem menos que o planejado';
      case FinancialGoalStatus.onTrack:
        return 'Seus gastos estão dentro do esperado';
      case FinancialGoalStatus.warning:
        return 'Cuidado! Você já gastou quase todo o orçamento';
      case FinancialGoalStatus.exceeded:
        return 'Você excedeu o orçamento planejado';
      case FinancialGoalStatus.inactive:
        return 'Meta não está ativa';
    }
  }
}
