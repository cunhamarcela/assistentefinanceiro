import '../entities/investment.dart';

abstract class InvestmentRepository {
  /// Adiciona um novo investimento
  Future<void> addInvestment(Investment investment);
  
  /// Atualiza um investimento existente
  Future<void> updateInvestment(Investment investment);
  
  /// Remove um investimento
  Future<void> deleteInvestment(String id);
  
  /// Busca investimento por ID
  Future<Investment?> getInvestmentById(String id);
  
  /// Busca todos os investimentos
  Future<List<Investment>> getAllInvestments();
  
  /// Busca investimentos por período
  Future<List<Investment>> getInvestmentsByDateRange(DateTime start, DateTime end);
  
  /// Busca investimentos por tipo
  Future<List<Investment>> getInvestmentsByType(InvestmentType type);
  
  /// Busca investimentos do mês atual
  Future<List<Investment>> getCurrentMonthInvestments();
  
  /// Calcula total investido por período
  Future<double> getTotalByDateRange(DateTime start, DateTime end);
  
  /// Calcula total investido por tipo
  Future<double> getTotalByType(InvestmentType type);
  
  /// Busca investimentos por texto (descrição)
  Future<List<Investment>> searchInvestments(String query);
}



