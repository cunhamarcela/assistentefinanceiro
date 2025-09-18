import '../entities/insight_report.dart';
import '../entities/expense.dart';

/// Repositório abstrato para operações de relatórios e insights
abstract class InsightRepository {
  /// Gera relatório de gastos por categoria
  Future<InsightReport> generateCategorySpendingReport({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Gera relatório de tendência de gastos
  Future<InsightReport> generateSpendingTrendReport({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Gera relatório de comparação mensal
  Future<InsightReport> generateMonthlyComparisonReport({
    required String userId,
    required int monthsToCompare,
  });

  /// Gera relatório personalizado baseado em parâmetros
  Future<InsightReport> generateCustomReport({
    required String userId,
    required InsightReportType type,
    required Map<String, dynamic> parameters,
  });

  /// Salva um relatório gerado
  Future<void> saveReport(InsightReport report);

  /// Carrega um relatório por ID
  Future<InsightReport?> getReport(String reportId);

  /// Carrega todos os relatórios de um usuário
  Future<List<InsightReport>> getUserReports(String userId);

  /// Carrega relatórios por tipo
  Future<List<InsightReport>> getReportsByType(
    String userId,
    InsightReportType type,
  );

  /// Deleta um relatório
  Future<void> deleteReport(String reportId);

  /// Calcula estatísticas agregadas para um período
  Future<Map<String, dynamic>> calculatePeriodStats({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Calcula dados para gráfico de pizza (categorias)
  Future<List<ChartPoint>> calculateCategoryChartData({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Calcula dados para gráfico de linha (tendência temporal)
  Future<List<ChartPoint>> calculateTrendChartData({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required String groupBy, // 'day', 'week', 'month'
  });

  /// Calcula dados para gráfico de barras (comparação)
  Future<List<ChartPoint>> calculateComparisonChartData({
    required String userId,
    required List<DateTime> periods,
    required String groupBy,
  });

  /// Identifica padrões de gastos
  Future<List<InsightRecommendation>> analyzeSpendingPatterns({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Compara gastos com períodos anteriores
  Future<Map<String, dynamic>> compareWithPreviousPeriod({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Calcula projeções de gastos
  Future<Map<String, dynamic>> calculateSpendingProjections({
    required String userId,
    required int daysToProject,
  });

  /// Obtém insights em tempo real
  Future<List<Map<String, dynamic>>> getRealTimeInsights(String userId);

  /// Limpa relatórios antigos
  Future<void> clearOldReports(String userId, {int keepDays = 90});
}
