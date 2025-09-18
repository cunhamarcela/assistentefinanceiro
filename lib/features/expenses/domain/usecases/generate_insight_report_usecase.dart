import '../entities/insight_report.dart';
import '../repositories/insight_repository.dart';

/// Use case para gerar relatórios de insights financeiros
class GenerateInsightReportUseCase {
  final InsightRepository repository;

  GenerateInsightReportUseCase(this.repository);

  /// Gera relatório de gastos por categoria
  Future<InsightReport> generateCategoryReport({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _validateDateRange(startDate, endDate);
      
      return await repository.generateCategorySpendingReport(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('Erro ao gerar relatório de categorias: $e');
    }
  }

  /// Gera relatório de tendência de gastos
  Future<InsightReport> generateTrendReport({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _validateDateRange(startDate, endDate);
      
      return await repository.generateSpendingTrendReport(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('Erro ao gerar relatório de tendência: $e');
    }
  }

  /// Gera relatório de comparação mensal
  Future<InsightReport> generateMonthlyComparison({
    required String userId,
    int monthsToCompare = 3,
  }) async {
    try {
      if (monthsToCompare < 2 || monthsToCompare > 12) {
        throw Exception('Número de meses deve estar entre 2 e 12');
      }
      
      return await repository.generateMonthlyComparisonReport(
        userId: userId,
        monthsToCompare: monthsToCompare,
      );
    } catch (e) {
      throw Exception('Erro ao gerar comparação mensal: $e');
    }
  }

  /// Gera relatório personalizado
  Future<InsightReport> generateCustomReport({
    required String userId,
    required InsightReportType type,
    required Map<String, dynamic> parameters,
  }) async {
    try {
      _validateCustomParameters(type, parameters);
      
      return await repository.generateCustomReport(
        userId: userId,
        type: type,
        parameters: parameters,
      );
    } catch (e) {
      throw Exception('Erro ao gerar relatório personalizado: $e');
    }
  }

  /// Gera múltiplos relatórios em paralelo
  Future<List<InsightReport>> generateMultipleReports({
    required String userId,
    required List<InsightReportType> types,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _validateDateRange(startDate, endDate);
      
      final futures = types.map((type) {
        switch (type) {
          case InsightReportType.categorySpending:
            return generateCategoryReport(
              userId: userId,
              startDate: startDate,
              endDate: endDate,
            );
          case InsightReportType.spendingTrend:
            return generateTrendReport(
              userId: userId,
              startDate: startDate,
              endDate: endDate,
            );
          case InsightReportType.monthlyComparison:
            return generateMonthlyComparison(userId: userId);
          default:
            return generateCustomReport(
              userId: userId,
              type: type,
              parameters: {
                'start_date': startDate.toIso8601String(),
                'end_date': endDate.toIso8601String(),
              },
            );
        }
      });

      return await Future.wait(futures);
    } catch (e) {
      throw Exception('Erro ao gerar múltiplos relatórios: $e');
    }
  }

  /// Gera relatório baseado em período pré-definido
  Future<InsightReport> generatePeriodReport({
    required String userId,
    required InsightReportType type,
    required ReportPeriod period,
  }) async {
    final dateRange = _getDateRangeForPeriod(period);
    
    switch (type) {
      case InsightReportType.categorySpending:
        return generateCategoryReport(
          userId: userId,
          startDate: dateRange.start,
          endDate: dateRange.end,
        );
      case InsightReportType.spendingTrend:
        return generateTrendReport(
          userId: userId,
          startDate: dateRange.start,
          endDate: dateRange.end,
        );
      case InsightReportType.monthlyComparison:
        return generateMonthlyComparison(userId: userId);
      default:
        return generateCustomReport(
          userId: userId,
          type: type,
          parameters: {
            'period': period.name,
            'start_date': dateRange.start.toIso8601String(),
            'end_date': dateRange.end.toIso8601String(),
          },
        );
    }
  }

  /// Valida intervalo de datas
  void _validateDateRange(DateTime startDate, DateTime endDate) {
    if (startDate.isAfter(endDate)) {
      throw Exception('Data inicial deve ser anterior à data final');
    }
    
    if (endDate.isAfter(DateTime.now())) {
      throw Exception('Data final não pode ser no futuro');
    }
    
    final daysDifference = endDate.difference(startDate).inDays;
    if (daysDifference > 365) {
      throw Exception('Período não pode ser maior que 365 dias');
    }
  }

  /// Valida parâmetros de relatório personalizado
  void _validateCustomParameters(
    InsightReportType type,
    Map<String, dynamic> parameters,
  ) {
    switch (type) {
      case InsightReportType.categorySpending:
        if (!parameters.containsKey('start_date') || 
            !parameters.containsKey('end_date')) {
          throw Exception('Parâmetros start_date e end_date são obrigatórios');
        }
        break;
      case InsightReportType.spendingTrend:
        if (!parameters.containsKey('group_by')) {
          parameters['group_by'] = 'day'; // Valor padrão
        }
        break;
      default:
        break;
    }
  }

  /// Obtém intervalo de datas para período pré-definido
  DateRange _getDateRangeForPeriod(ReportPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (period) {
      case ReportPeriod.today:
        return DateRange(start: today, end: today);
      case ReportPeriod.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return DateRange(start: yesterday, end: yesterday);
      case ReportPeriod.thisWeek:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return DateRange(start: startOfWeek, end: today);
      case ReportPeriod.lastWeek:
        final endOfLastWeek = today.subtract(Duration(days: today.weekday));
        final startOfLastWeek = endOfLastWeek.subtract(const Duration(days: 6));
        return DateRange(start: startOfLastWeek, end: endOfLastWeek);
      case ReportPeriod.thisMonth:
        final startOfMonth = DateTime(today.year, today.month, 1);
        return DateRange(start: startOfMonth, end: today);
      case ReportPeriod.lastMonth:
        final startOfLastMonth = DateTime(today.year, today.month - 1, 1);
        final endOfLastMonth = DateTime(today.year, today.month, 0);
        return DateRange(start: startOfLastMonth, end: endOfLastMonth);
      case ReportPeriod.last30Days:
        final start = today.subtract(const Duration(days: 30));
        return DateRange(start: start, end: today);
      case ReportPeriod.last90Days:
        final start = today.subtract(const Duration(days: 90));
        return DateRange(start: start, end: today);
    }
  }
}

/// Períodos pré-definidos para relatórios
enum ReportPeriod {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  last30Days,
  last90Days,
}

/// Classe auxiliar para intervalo de datas
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
}
