import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';
import '../../data/services/financial_profile_service.dart';

/// Use case aprimorado que adiciona despesa E atualiza metas automaticamente
class AddExpenseWithGoalsUseCase {
  final ExpenseRepository repository;
  final FinancialProfileService profileService;

  AddExpenseWithGoalsUseCase({
    required this.repository,
    required this.profileService,
  });

  Future<void> call({
    required double amount,
    required String description,
    String? categoryId,
    DateTime? date,
    String? notes,
  }) async {
    // Validações
    if (amount <= 0) {
      throw ArgumentError('O valor deve ser maior que zero');
    }
    
    if (description.trim().isEmpty) {
      throw ArgumentError('A descrição não pode estar vazia');
    }
    
    if (description.length > 100) {
      throw ArgumentError('A descrição deve ter no máximo 100 caracteres');
    }

    // Se não foi fornecida uma categoria, sugere uma automaticamente
    String finalCategoryId = categoryId ?? await repository.suggestCategory(description);
    
    // Se ainda não tiver categoria, usa "outros"
    if (finalCategoryId.isEmpty) {
      finalCategoryId = 'outros';
    }

    // Cria a despesa
    final expense = Expense.create(
      amount: amount,
      description: description.trim(),
      categoryId: finalCategoryId,
      date: date,
      notes: notes?.trim(),
    );

    try {
      // 1. Salva a despesa no repositório
      await repository.addExpense(expense);
      print('✅ Despesa salva: ${expense.description}');

      // 2. Atualiza as metas financeiras automaticamente
      await _updateFinancialGoals(expense);
      print('✅ Metas financeiras atualizadas');

    } catch (e) {
      print('❌ Erro ao adicionar despesa com metas: $e');
      throw Exception('Erro ao adicionar despesa: $e');
    }
  }

  /// Atualiza as metas financeiras após adicionar uma despesa
  Future<void> _updateFinancialGoals(Expense expense) async {
    try {
      final expenseDate = expense.date;
      final currentMonth = DateTime(expenseDate.year, expenseDate.month);
      
      // Buscar metas do mês da despesa
      final goals = await profileService.getFinancialGoals(currentMonth);
      
      // Encontrar meta da categoria da despesa
      final categoryGoal = goals.firstWhereOrNull(
        (goal) => goal.categoryId == expense.categoryId && goal.isActive,
      );
      
      if (categoryGoal != null) {
        // Calcular novo total gasto na categoria
        final categoryExpenses = await _getCategoryExpensesForMonth(
          expense.categoryId, 
          currentMonth,
        );
        
        final totalSpent = categoryExpenses.fold(0.0, (sum, exp) => sum + exp.amount);
        
        // Atualizar meta com novo valor
        await profileService.updateGoalSpentAmount(expense.categoryId, totalSpent);
        
        print('🎯 Meta atualizada para ${categoryGoal.categoryName}: R\$ ${totalSpent.toStringAsFixed(2)}');
        
        // Verificar se excedeu orçamento e notificar
        if (totalSpent > categoryGoal.monthlyLimit) {
          final excess = totalSpent - categoryGoal.monthlyLimit;
          print('⚠️ Orçamento excedido em ${categoryGoal.categoryName}: +R\$ ${excess.toStringAsFixed(2)}');
          
          // Mostrar notificação para o usuário
          _showBudgetExceededNotification(categoryGoal.categoryName, excess);
        } else if (totalSpent >= categoryGoal.monthlyLimit * 0.8) {
          final remaining = categoryGoal.monthlyLimit - totalSpent;
          print('🔔 Próximo do limite em ${categoryGoal.categoryName}: R\$ ${remaining.toStringAsFixed(2)} restantes');
          
          // Mostrar alerta de proximidade do limite
          _showBudgetWarningNotification(categoryGoal.categoryName, remaining);
        }
      } else {
        print('ℹ️ Nenhuma meta encontrada para categoria: ${expense.categoryId}');
      }
    } catch (e) {
      print('❌ Erro ao atualizar metas financeiras: $e');
      // Não falhar a operação principal se houver erro nas metas
    }
  }

  /// Buscar despesas de uma categoria em um mês específico
  Future<List<Expense>> _getCategoryExpensesForMonth(
    String categoryId, 
    DateTime month,
  ) async {
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

  /// Mostrar notificação de orçamento excedido
  void _showBudgetExceededNotification(String categoryName, double excess) {
    Get.snackbar(
      '⚠️ Orçamento Excedido',
      'Você excedeu o orçamento de $categoryName em R\$ ${excess.toStringAsFixed(2)}',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
      duration: const Duration(seconds: 5),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// Mostrar alerta de proximidade do limite
  void _showBudgetWarningNotification(String categoryName, double remaining) {
    Get.snackbar(
      '🔔 Atenção ao Orçamento',
      'Restam apenas R\$ ${remaining.toStringAsFixed(2)} no orçamento de $categoryName',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.tertiary,
      colorText: Get.theme.colorScheme.onTertiary,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }
}
