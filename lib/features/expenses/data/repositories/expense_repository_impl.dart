import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_datasource.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource localDataSource;

  ExpenseRepositoryImpl(this.localDataSource);

  @override
  Future<void> addExpense(Expense expense) async {
    final expenseModel = ExpenseModel.fromEntity(expense);
    await localDataSource.insertExpense(expenseModel);
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final expenseModel = ExpenseModel.fromEntity(expense);
    await localDataSource.updateExpense(expenseModel);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await localDataSource.deleteExpense(id);
  }

  @override
  Future<Expense?> getExpenseById(String id) async {
    final expenseModel = await localDataSource.getExpenseById(id);
    return expenseModel?.toEntity();
  }

  @override
  Future<List<Expense>> getAllExpenses() async {
    final expenseModels = await localDataSource.getAllExpenses();
    return expenseModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    final expenseModels = await localDataSource.getExpensesByDateRange(start, end);
    return expenseModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Expense>> getExpensesByCategory(String categoryId) async {
    final expenseModels = await localDataSource.getExpensesByCategory(categoryId);
    return expenseModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Expense>> getCurrentMonthExpenses() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    return getExpensesByDateRange(startOfMonth, endOfMonth);
  }

  @override
  Future<List<Expense>> getTodayExpenses() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return getExpensesByDateRange(startOfDay, endOfDay);
  }

  @override
  Future<double> getTotalByDateRange(DateTime start, DateTime end) async {
    return localDataSource.getTotalByDateRange(start, end);
  }

  @override
  Future<double> getTotalByCategory(String categoryId) async {
    return localDataSource.getTotalByCategory(categoryId);
  }

  @override
  Future<List<Expense>> searchExpenses(String query) async {
    final expenseModels = await localDataSource.searchExpenses(query);
    return expenseModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<ExpenseCategory>> getAllCategories() async {
    final categoryModels = await localDataSource.getAllCategories();
    return categoryModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> addCategory(ExpenseCategory category) async {
    final categoryModel = CategoryModel.fromEntity(category);
    await localDataSource.insertCategory(categoryModel);
  }

  @override
  Future<void> updateCategory(ExpenseCategory category) async {
    final categoryModel = CategoryModel.fromEntity(category);
    await localDataSource.updateCategory(categoryModel);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await localDataSource.deleteCategory(id);
  }

  @override
  Future<ExpenseCategory?> getCategoryById(String id) async {
    final categoryModel = await localDataSource.getCategoryById(id);
    return categoryModel?.toEntity();
  }

  @override
  Future<String> suggestCategory(String description) async {
    final categories = await getAllCategories();
    final lowerDescription = description.toLowerCase();

    // Procura por correspondências nas palavras-chave
    for (final category in categories) {
      if (category.matchesDescription(lowerDescription)) {
        return category.id;
      }
    }

    // Se não encontrou correspondência, retorna "outros"
    return 'outros';
  }
}
