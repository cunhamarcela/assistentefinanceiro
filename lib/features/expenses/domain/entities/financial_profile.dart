/// Entidade que representa o perfil financeiro do usuário
class FinancialProfile {
  final String id;
  final String userId;
  final double monthlyIncome;
  final double totalBudget;
  final double monthlyInvestmentGoal; // Meta mensal de investimento
  final Map<String, double> categoryBudgets; // categoryId -> valor
  final DateTime createdAt;
  final DateTime updatedAt;

  const FinancialProfile({
    required this.id,
    required this.userId,
    required this.monthlyIncome,
    required this.totalBudget,
    this.monthlyInvestmentGoal = 0.0,
    required this.categoryBudgets,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Orçamento máximo disponível para despesas (renda - meta de investimento)
  /// Este é o valor que o usuário pode gastar sem comprometer sua meta de investimento
  double get availableBudgetForExpenses {
    return monthlyIncome - monthlyInvestmentGoal;
  }

  /// Percentual da renda destinado a investimentos
  double get investmentPercentage {
    if (monthlyIncome <= 0) return 0.0;
    return (monthlyInvestmentGoal / monthlyIncome) * 100;
  }

  /// Percentual da renda destinado a despesas (100% - investimentos)
  double get expensesPercentage {
    if (monthlyIncome <= 0) return 0.0;
    return 100 - investmentPercentage;
  }

  /// Verifica se o orçamento de despesas está dentro do limite
  bool get isBudgetWithinLimit {
    return totalBudget <= availableBudgetForExpenses;
  }

  /// Percentual do orçamento total alocado (em relação à renda disponível para despesas)
  double get budgetAllocationPercentage {
    if (availableBudgetForExpenses <= 0) return 0.0;
    return totalBudget / availableBudgetForExpenses;
  }

  /// Valor não alocado do orçamento de despesas
  double get unallocatedBudget {
    final allocatedSum = categoryBudgets.values.fold(0.0, (sum, value) => sum + value);
    return totalBudget - allocatedSum;
  }

  /// Margem restante após orçamento de despesas (disponível - totalBudget)
  double get remainingMargin {
    return availableBudgetForExpenses - totalBudget;
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
    double? monthlyInvestmentGoal,
    Map<String, double>? categoryBudgets,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinancialProfile(
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
