import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class GetExpensesUseCase {
  final ExpenseRepository repository;

  GetExpensesUseCase(this.repository);

  /// Busca todas as despesas
  Future<List<Expense>> getAllExpenses() async {
    final expenses = await repository.getAllExpenses();
    // Ordena por data decrescente (mais recentes primeiro)
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  /// Busca despesas do mês atual
  Future<List<Expense>> getCurrentMonthExpenses() async {
    final expenses = await repository.getCurrentMonthExpenses();
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  /// Busca despesas de hoje
  Future<List<Expense>> getTodayExpenses() async {
    final expenses = await repository.getTodayExpenses();
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  /// Busca despesas por período
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    final expenses = await repository.getExpensesByDateRange(start, end);
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  /// Busca despesas por categoria
  Future<List<Expense>> getExpensesByCategory(String categoryId) async {
    final expenses = await repository.getExpensesByCategory(categoryId);
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  /// Busca despesas por texto
  Future<List<Expense>> searchExpenses(String query) async {
    if (query.trim().isEmpty) {
      return getAllExpenses();
    }
    
    final expenses = await repository.searchExpenses(query.trim());
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  /// Calcula estatísticas básicas
  Future<ExpenseStats> getExpenseStats() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final results = await Future.wait([
      repository.getTotalByDateRange(startOfMonth, endOfMonth),
      repository.getTotalByDateRange(startOfWeek, endOfWeek),
      repository.getTotalByDateRange(
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day, 23, 59, 59),
      ),
      repository.getExpensesByDateRange(startOfMonth, endOfMonth),
    ]);

    final totalMonth = results[0] as double;
    final totalWeek = results[1] as double;
    final totalToday = results[2] as double;
    final monthlyExpenses = results[3] as List<Expense>;

    // Calcula gastos por categoria do mês
    final Map<String, double> categoryTotals = {};
    for (final expense in monthlyExpenses) {
      categoryTotals[expense.categoryId] = 
          (categoryTotals[expense.categoryId] ?? 0) + expense.amount;
    }

    return ExpenseStats(
      totalMonth: totalMonth,
      totalWeek: totalWeek,
      totalToday: totalToday,
      expenseCount: monthlyExpenses.length,
      categoryTotals: categoryTotals,
      averagePerDay: monthlyExpenses.isEmpty ? 0 : totalMonth / now.day,
    );
  }
}

class ExpenseStats {
  final double totalMonth;
  final double totalWeek;
  final double totalToday;
  final int expenseCount;
  final Map<String, double> categoryTotals;
  final double averagePerDay;

  ExpenseStats({
    required this.totalMonth,
    required this.totalWeek,
    required this.totalToday,
    required this.expenseCount,
    required this.categoryTotals,
    required this.averagePerDay,
  });
}
