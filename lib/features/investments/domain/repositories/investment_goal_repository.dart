import '../entities/investment.dart';
import '../entities/investment_goal.dart';

abstract class InvestmentGoalRepository {
  /// Salvar uma meta de investimento
  Future<void> saveGoal(InvestmentGoal goal);
  
  /// Salvar múltiplas metas
  Future<void> saveGoals(List<InvestmentGoal> goals);
  
  /// Buscar metas de um mês específico
  Future<List<InvestmentGoal>> getGoalsByMonth(DateTime month);
  
  /// Buscar meta por tipo e mês
  Future<InvestmentGoal?> getGoalByTypeAndMonth(InvestmentType? type, DateTime month);
  
  /// Buscar todas as metas do usuário
  Future<List<InvestmentGoal>> getAllGoals();
  
  /// Atualizar valor investido de uma meta
  Future<void> updateGoalInvestedAmount(InvestmentType? type, DateTime month, double newAmount);
  
  /// Deletar uma meta
  Future<void> deleteGoal(String goalId);
  
  /// Deletar todas as metas de um mês
  Future<void> deleteGoalsByMonth(DateTime month);
  
  /// Recalcular investimentos de todas as metas de um mês baseado nos investimentos existentes
  Future<List<InvestmentGoal>> recalculateGoalsInvested(DateTime month);
}

