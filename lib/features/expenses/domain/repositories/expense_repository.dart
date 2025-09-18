import '../entities/expense.dart';
import '../entities/category.dart';

abstract class ExpenseRepository {
  /// Adiciona uma nova despesa
  Future<void> addExpense(Expense expense);
  
  /// Atualiza uma despesa existente
  Future<void> updateExpense(Expense expense);
  
  /// Remove uma despesa
  Future<void> deleteExpense(String id);
  
  /// Busca despesa por ID
  Future<Expense?> getExpenseById(String id);
  
  /// Busca todas as despesas
  Future<List<Expense>> getAllExpenses();
  
  /// Busca despesas por período
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end);
  
  /// Busca despesas por categoria
  Future<List<Expense>> getExpensesByCategory(String categoryId);
  
  /// Busca despesas do mês atual
  Future<List<Expense>> getCurrentMonthExpenses();
  
  /// Busca despesas de hoje
  Future<List<Expense>> getTodayExpenses();
  
  /// Calcula total de gastos por período
  Future<double> getTotalByDateRange(DateTime start, DateTime end);
  
  /// Calcula total de gastos por categoria
  Future<double> getTotalByCategory(String categoryId);
  
  /// Busca despesas por texto (descrição)
  Future<List<Expense>> searchExpenses(String query);
  
  /// Categorias
  Future<List<ExpenseCategory>> getAllCategories();
  Future<void> addCategory(ExpenseCategory category);
  Future<void> updateCategory(ExpenseCategory category);
  Future<void> deleteCategory(String id);
  Future<ExpenseCategory?> getCategoryById(String id);
  
  /// Categorização automática
  Future<String> suggestCategory(String description);
}
