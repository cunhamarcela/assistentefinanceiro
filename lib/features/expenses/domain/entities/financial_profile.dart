/// Entidade que representa o perfil financeiro do usuário
class FinancialProfile {
  final String id;
  final String userId;
  final double monthlyIncome;
  final double totalBudget;
  final Map<String, double> categoryBudgets; // categoryId -> valor
  final DateTime createdAt;
  final DateTime updatedAt;

  const FinancialProfile({
    required this.id,
    required this.userId,
    required this.monthlyIncome,
    required this.totalBudget,
    required this.categoryBudgets,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Percentual do orçamento total alocado
  double get budgetAllocationPercentage {
    if (monthlyIncome <= 0) return 0.0;
    return totalBudget / monthlyIncome;
  }

  /// Valor não alocado do orçamento
  double get unallocatedBudget {
    final allocatedSum = categoryBudgets.values.fold(0.0, (sum, value) => sum + value);
    return totalBudget - allocatedSum;
  }

  /// Se o orçamento está balanceado (soma das categorias = orçamento total)
  bool get isBalanced => unallocatedBudget.abs() < 0.01; // Tolerância de 1 centavo

  /// Percentual de cada categoria no orçamento total
  Map<String, double> get categoryPercentages {
    if (totalBudget <= 0) return {};
    
    return categoryBudgets.map(
      (categoryId, amount) => MapEntry(categoryId, amount / totalBudget),
    );
  }

  FinancialProfile copyWith({
    String? id,
    String? userId,
    double? monthlyIncome,
    double? totalBudget,
    Map<String, double>? categoryBudgets,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinancialProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      totalBudget: totalBudget ?? this.totalBudget,
      categoryBudgets: categoryBudgets ?? Map.from(this.categoryBudgets),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Atualizar orçamento de uma categoria específica
  FinancialProfile updateCategoryBudget(String categoryId, double amount) {
    final newBudgets = Map<String, double>.from(categoryBudgets);
    if (amount > 0) {
      newBudgets[categoryId] = amount;
    } else {
      newBudgets.remove(categoryId);
    }

    return copyWith(
      categoryBudgets: newBudgets,
      updatedAt: DateTime.now(),
    );
  }

  /// Remover categoria do orçamento
  FinancialProfile removeCategoryBudget(String categoryId) {
    final newBudgets = Map<String, double>.from(categoryBudgets);
    newBudgets.remove(categoryId);

    return copyWith(
      categoryBudgets: newBudgets,
      updatedAt: DateTime.now(),
    );
  }
}
