import '../entities/financial_goal.dart';

/// Repositório abstrato para metas financeiras
abstract class FinancialGoalsRepository {
  /// Salvar uma meta financeira
  Future<void> saveGoal(FinancialGoal goal);
  
  /// Salvar múltiplas metas
  Future<void> saveGoals(List<FinancialGoal> goals);
  
  /// Buscar metas de um mês específico
  Future<List<FinancialGoal>> getGoalsByMonth(DateTime month);
  
  /// Buscar meta por categoria e mês
  Future<FinancialGoal?> getGoalByCategoryAndMonth(String categoryId, DateTime month);
  
  /// Buscar todas as metas do usuário
  Future<List<FinancialGoal>> getAllGoals();
  
  /// Atualizar valor gasto de uma meta
  Future<void> updateGoalSpentAmount(String categoryId, DateTime month, double newAmount);
  
  /// Deletar uma meta
  Future<void> deleteGoal(String goalId);
  
  /// Deletar todas as metas de um mês
  Future<void> deleteGoalsByMonth(DateTime month);
  
  /// Criar metas baseadas no perfil financeiro
  Future<List<FinancialGoal>> createGoalsFromProfile(Map<String, double> categoryBudgets, DateTime month);

  /// Recalcular gastos de todas as metas de um mês baseado nas despesas existentes
  Future<List<FinancialGoal>> recalculateGoalsSpent(DateTime month);
}

