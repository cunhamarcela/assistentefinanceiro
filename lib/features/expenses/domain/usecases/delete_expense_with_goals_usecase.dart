import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';
import '../../data/services/financial_profile_service.dart';

/// Use case aprimorado que deleta despesa E recalcula metas automaticamente
class DeleteExpenseWithGoalsUseCase {
  final ExpenseRepository repository;
  final FinancialProfileService profileService;

  DeleteExpenseWithGoalsUseCase({
    required this.repository,
    required this.profileService,
  });

  Future<void> call(String expenseId) async {
    try {
      // Buscar despesa antes de deletar para recalcular metas
      final expense = await repository.getExpenseById(expenseId);
      
      if (expense == null) {
        throw Exception('Despesa não encontrada');
      }

      // 1. Deletar a despesa do repositório
      await repository.deleteExpense(expenseId);
      print('✅ Despesa deletada: ${expense.description}');

      // 2. Recalcular metas financeiras da categoria afetada
      await _recalculateFinancialGoals(expense);
      print('✅ Metas financeiras recalculadas');

    } catch (e) {
      print('❌ Erro ao deletar despesa com metas: $e');
      throw Exception('Erro ao deletar despesa: $e');
    }
  }

  /// Recalcula as metas financeiras após deletar uma despesa
  Future<void> _recalculateFinancialGoals(Expense deletedExpense) async {
    try {
      await _updateCategoryGoal(deletedExpense.categoryId, deletedExpense.date);
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
        // Calcular novo total gasto na categoria (após deletar)
        final categoryExpenses = await _getCategoryExpensesForMonth(categoryId, currentMonth);
        final totalSpent = categoryExpenses.fold(0.0, (sum, exp) => sum + exp.amount);
        
        // Atualizar meta com novo valor
        await profileService.updateGoalSpentAmount(categoryId, totalSpent);
        
        print('🎯 Meta recalculada para ${categoryGoal.categoryName}: R\$ ${totalSpent.toStringAsFixed(2)}');
        
        // Mostrar notificação positiva se voltou para dentro do orçamento
        if (totalSpent <= categoryGoal.monthlyLimit && categoryGoal.currentSpent > categoryGoal.monthlyLimit) {
          _showBudgetBackOnTrackNotification(categoryGoal.categoryName);
        }
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

  /// Mostrar notificação de volta ao orçamento
  void _showBudgetBackOnTrackNotification(String categoryName) {
    Get.snackbar(
      '✅ Orçamento Controlado',
      'Seus gastos em $categoryName voltaram para dentro do orçamento!',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.primary,
      colorText: Get.theme.colorScheme.onPrimary,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }
}
