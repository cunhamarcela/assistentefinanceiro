import '../entities/income.dart';

/// Repositório abstrato para gerenciar receitas
abstract class IncomeRepository {
  /// Adiciona uma nova receita
  Future<void> addIncome(Income income);
  
  /// Atualiza uma receita existente
  Future<void> updateIncome(Income income);
  
  /// Remove uma receita
  Future<void> deleteIncome(String id);
  
  /// Obtém uma receita por ID
  Future<Income?> getIncomeById(String id);
  
  /// Obtém todas as receitas do usuário
  Future<List<Income>> getAllIncomes();
  
  /// Obtém receitas por período
  Future<List<Income>> getIncomesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });
  
  /// Obtém receitas do mês atual
  Future<List<Income>> getCurrentMonthIncomes();
  
  /// Obtém receitas por tipo
  Future<List<Income>> getIncomesByType(IncomeType type);
  
  /// Obtém receitas recorrentes
  Future<List<Income>> getRecurringIncomes();
  
  /// Calcula total de receitas em um período
  Future<double> getTotalIncomeByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });
  
  /// Calcula total de receitas do mês atual
  Future<double> getCurrentMonthTotalIncome();
  
  /// Obtém receitas agrupadas por tipo
  Future<Map<IncomeType, double>> getIncomesByTypeGrouped({
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// Stream de receitas para atualizações em tempo real
  Stream<List<Income>> watchAllIncomes();
  
  /// Stream de receitas do mês atual
  Stream<List<Income>> watchCurrentMonthIncomes();
  
  /// Sincroniza dados locais com o servidor
  Future<void> syncWithServer();
  
  /// Limpa cache local
  Future<void> clearLocalCache();
}
