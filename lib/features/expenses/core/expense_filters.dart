import '../domain/entities/expense.dart';

/// Helper para filtrar despesas, excluindo investimentos
class ExpenseFilters {
  /// ID da categoria de investimentos (caso ainda exista em dados antigos)
  static const String investmentCategoryId = 'investimentos';

  /// Filtra despesas excluindo investimentos
  /// 
  /// Investimentos não devem ser contabilizados como despesas.
  /// Este filtro garante que mesmo se houver dados antigos com categoria
  /// "investimentos", eles não sejam incluídos nos cálculos de despesas.
  static List<Expense> excludeInvestments(List<Expense> expenses) {
    return expenses.where((expense) => expense.categoryId != investmentCategoryId).toList();
  }

  /// Verifica se uma despesa é um investimento
  static bool isInvestment(Expense expense) {
    return expense.categoryId == investmentCategoryId;
  }

  /// Filtra apenas investimentos (para migração de dados)
  static List<Expense> getInvestmentsOnly(List<Expense> expenses) {
    return expenses.where((expense) => expense.categoryId == investmentCategoryId).toList();
  }
}



