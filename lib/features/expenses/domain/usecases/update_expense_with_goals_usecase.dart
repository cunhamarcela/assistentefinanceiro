import '../entities/expense.dart';
import '../repositories/expense_repository.dart';
import '../../data/services/financial_profile_service.dart';
import 'package:get/get.dart';

/// Use case aprimorado que atualiza despesa E recalcula metas automaticamente
class UpdateExpenseWithGoalsUseCase {
  final ExpenseRepository repository;
  final FinancialProfileService profileService;

  UpdateExpenseWithGoalsUseCase({
    required this.repository,
    required this.profileService,
  });

  Future<void> call(Expense expense) async {
    try {
      // Buscar despesa original para comparar mudanças
      final originalExpense = await repository.getExpenseById(expense.id);
      
      // 1. Atualizar a despesa no repositório
      await repository.updateExpense(expense);
      print('✅ Despesa atualizada: ${expense.description}');

      // 2. Recalcular metas financeiras para as categorias afetadas
      await _recalculateFinancialGoals(expense, originalExpense);
      print('✅ Metas financeiras recalculadas');

    } catch (e) {
      print('❌ Erro ao atualizar despesa com metas: $e');
      throw Exception('Erro ao atualizar despesa: $e');
    }
  }

  /// Recalcula as metas financeiras após atualizar uma despesa
  Future<void> _recalculateFinancialGoals(Expense updatedExpense, Expense? originalExpense) async {
    try {
      final categoriesToUpdate = <String>{};
      
      // Adicionar categoria da despesa atualizada
      categoriesToUpdate.add(updatedExpense.categoryId);
      
      // Se a categoria mudou, também atualizar a categoria original
      if (originalExpense != null && originalExpense.categoryId != updatedExpense.categoryId) {
        categoriesToUpdate.add(originalExpense.categoryId);
      }

      // Recalcular para cada categoria afetada
      for (final categoryId in categoriesToUpdate) {
        await _updateCategoryGoal(categoryId, updatedExpense.date);
      }

    } catch (e) {
      print('❌ Erro ao recalcular metas financeiras: $e');
      // Não falhar a operação principal se houver erro nas metas
    }
  }

  /// Atualiza a meta de uma categoria específica
  Future<void> _updateCategoryGoal(String categoryId, DateTime expenseDate) async {
    try {
      final currentMonth = DateTime(expenseDate.year, expenseDate.month);
      
      // Buscar metas do mês
      final goals = await profileService.getFinancialGoals(currentMonth);
      
      // Encontrar meta da categoria
      final categoryGoal = goals.firstWhereOrNull(
        (goal) => goal.categoryId == categoryId && goal.isActive,
      );
      
      if (categoryGoal != null) {
        // Calcular novo total gasto na categoria
        final categoryExpenses = await _getCategoryExpensesForMonth(categoryId, currentMonth);
        final totalSpent = categoryExpenses.fold(0.0, (sum, exp) => sum + exp.amount);
        
        // Atualizar meta com novo valor
        await profileService.updateGoalSpentAmount(categoryId, totalSpent);
        
        print('🎯 Meta recalculada para ${categoryGoal.categoryName}: R\$ ${totalSpent.toStringAsFixed(2)}');
      }
    } catch (e) {
      print('❌ Erro ao atualizar meta da categoria $categoryId: $e');
    }
  }

  /// Buscar despesas de uma categoria em um mês específico
  Future<List<Expense>> _getCategoryExpensesForMonth(String categoryId, DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      
      final allExpenses = await repository.getExpensesByDateRange(startOfMonth, endOfMonth);
      
      return allExpenses.where((expense) => expense.categoryId == categoryId).toList();
    } catch (e) {
      print('❌ Erro ao buscar despesas da categoria: $e');
      return [];
    }
  }
}
