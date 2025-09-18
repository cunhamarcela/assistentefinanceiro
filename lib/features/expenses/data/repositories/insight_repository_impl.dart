import '../../domain/entities/insight_report.dart';
import '../../domain/repositories/insight_repository.dart';
import '../datasources/reports_local_datasource.dart';
import '../datasources/reports_remote_datasource.dart';

/// Implementação do repositório de insights e relatórios
class InsightRepositoryImpl implements InsightRepository {
  final ReportsLocalDataSource localDataSource;
  final ReportsRemoteDataSource remoteDataSource;

  InsightRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<InsightReport> generateCategorySpendingReport({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Gera relatório usando dados locais (mais rápido)
      final report = await localDataSource.generateCategorySpendingReport(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      // Salva relatório localmente para cache
      await localDataSource.saveReport(report);

      // Sincroniza com Firestore em background (não bloqueia)
      _syncReportInBackground(report);

      return report;
    } catch (e) {
      print('❌ Erro ao gerar relatório de categorias: $e');
      throw Exception('Erro ao gerar relatório de categorias: $e');
    }
  }

  @override
  Future<InsightReport> generateSpendingTrendReport({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final report = await localDataSource.generateSpendingTrendReport(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      await localDataSource.saveReport(report);
      _syncReportInBackground(report);

      return report;
    } catch (e) {
      print('❌ Erro ao gerar relatório de tendência: $e');
      throw Exception('Erro ao gerar relatório de tendência: $e');
    }
  }

  @override
  Future<InsightReport> generateMonthlyComparisonReport({
    required String userId,
    required int monthsToCompare,
  }) async {
    try {
      final report = await localDataSource.generateMonthlyComparisonReport(
        userId: userId,
        monthsToCompare: monthsToCompare,
      );

      await localDataSource.saveReport(report);
      _syncReportInBackground(report);

      return report;
    } catch (e) {
      print('❌ Erro ao gerar relatório de comparação: $e');
      throw Exception('Erro ao gerar relatório de comparação: $e');
    }
  }

  @override
  Future<InsightReport> generateCustomReport({
    required String userId,
    required InsightReportType type,
    required Map<String, dynamic> parameters,
  }) async {
    try {
      switch (type) {
        case InsightReportType.categorySpending:
          final startDate = DateTime.parse(parameters['start_date'] as String);
          final endDate = DateTime.parse(parameters['end_date'] as String);
          return await generateCategorySpendingReport(
            userId: userId,
            startDate: startDate,
            endDate: endDate,
          );

        case InsightReportType.spendingTrend:
          final startDate = DateTime.parse(parameters['start_date'] as String);
          final endDate = DateTime.parse(parameters['end_date'] as String);
          return await generateSpendingTrendReport(
            userId: userId,
            startDate: startDate,
            endDate: endDate,
          );

        case InsightReportType.monthlyComparison:
          final monthsToCompare = parameters['months_to_compare'] as int? ?? 6;
          return await generateMonthlyComparisonReport(
            userId: userId,
            monthsToCompare: monthsToCompare,
          );

        default:
          throw Exception('Tipo de relatório não suportado: $type');
      }
    } catch (e) {
      print('❌ Erro ao gerar relatório personalizado: $e');
      throw Exception('Erro ao gerar relatório personalizado: $e');
    }
  }

  @override
  Future<void> saveReport(InsightReport report) async {
    try {
      // Salva localmente primeiro
      await localDataSource.saveReport(report);
      
      // Sincroniza com remoto em background
      _syncReportInBackground(report);
    } catch (e) {
      print('❌ Erro ao salvar relatório: $e');
      throw Exception('Erro ao salvar relatório: $e');
    }
  }

  @override
  Future<InsightReport?> getReport(String reportId) async {
    try {
      // Busca primeiro no cache local
      final localReport = await localDataSource.getReport(reportId);
      if (localReport != null) {
        return localReport;
      }

      // Se não encontrar localmente, busca no remoto
      final remoteReport = await remoteDataSource.getReport(reportId);
      if (remoteReport != null) {
        // Salva no cache local para próximas consultas
        await localDataSource.saveReport(remoteReport);
        return remoteReport;
      }

      return null;
    } catch (e) {
      print('❌ Erro ao buscar relatório: $e');
      return null;
    }
  }

  @override
  Future<List<InsightReport>> getUserReports(String userId) async {
    try {
      // Busca relatórios locais
      final localReports = await localDataSource.getUserReports(userId);
      
      // TODO: Sincronizar com relatórios remotos em background
      // _syncRemoteReportsInBackground(userId);
      
      return localReports;
    } catch (e) {
      print('❌ Erro ao buscar relatórios do usuário: $e');
      return [];
    }
  }

  @override
  Future<List<InsightReport>> getReportsByType(
    String userId,
    InsightReportType type,
  ) async {
    try {
      final allReports = await getUserReports(userId);
      return allReports.where((report) => report.type == type).toList();
    } catch (e) {
      print('❌ Erro ao buscar relatórios por tipo: $e');
      return [];
    }
  }

  @override
  Future<void> deleteReport(String reportId) async {
    try {
      // Remove localmente
      await localDataSource.deleteReport(reportId);
      
      // Remove do remoto
      try {
        await remoteDataSource.deleteReport(reportId);
      } catch (e) {
        print('⚠️ Erro ao deletar relatório remoto (continuando): $e');
      }
    } catch (e) {
      print('❌ Erro ao deletar relatório: $e');
      throw Exception('Erro ao deletar relatório: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> calculatePeriodStats({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await localDataSource.calculatePeriodStats(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('❌ Erro ao calcular estatísticas do período: $e');
      return {};
    }
  }

  @override
  Future<List<ChartPoint>> calculateCategoryChartData({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await localDataSource.calculateCategoryChartData(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('❌ Erro ao calcular dados do gráfico de categorias: $e');
      return [];
    }
  }

  @override
  Future<List<ChartPoint>> calculateTrendChartData({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required String groupBy,
  }) async {
    try {
      return await localDataSource.calculateTrendChartData(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        groupBy: groupBy,
      );
    } catch (e) {
      print('❌ Erro ao calcular dados do gráfico de tendência: $e');
      return [];
    }
  }

  @override
  Future<List<ChartPoint>> calculateComparisonChartData({
    required String userId,
    required List<DateTime> periods,
    required String groupBy,
  }) async {
    try {
      return await localDataSource.calculateComparisonChartData(
        userId: userId,
        periods: periods,
        groupBy: groupBy,
      );
    } catch (e) {
      print('❌ Erro ao calcular dados do gráfico de comparação: $e');
      return [];
    }
  }

  @override
  Future<List<InsightRecommendation>> analyzeSpendingPatterns({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Usa análise remota (com IA) quando disponível
      return await remoteDataSource.analyzeSpendingPatterns(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('❌ Erro ao analisar padrões de gastos: $e');
      // Fallback para recomendações básicas locais
      return _generateBasicRecommendations(userId, startDate, endDate);
    }
  }

  @override
  Future<Map<String, dynamic>> compareWithPreviousPeriod({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await remoteDataSource.compareWithPreviousPeriod(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('❌ Erro ao comparar com período anterior: $e');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> calculateSpendingProjections({
    required String userId,
    required int daysToProject,
  }) async {
    try {
      return await remoteDataSource.calculateSpendingProjections(
        userId: userId,
        daysToProject: daysToProject,
      );
    } catch (e) {
      print('❌ Erro ao calcular projeções: $e');
      return {};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRealTimeInsights(String userId) async {
    try {
      return await remoteDataSource.getRealTimeInsights(userId);
    } catch (e) {
      print('❌ Erro ao buscar insights em tempo real: $e');
      return [];
    }
  }

  @override
  Future<void> clearOldReports(String userId, {int keepDays = 90}) async {
    try {
      // Limpa relatórios locais antigos
      final allReports = await localDataSource.getUserReports(userId);
      final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
      
      for (final report in allReports) {
        if (report.createdAt.isBefore(cutoffDate)) {
          await localDataSource.deleteReport(report.id);
        }
      }

      print('✅ Relatórios antigos removidos (mais de $keepDays dias)');
    } catch (e) {
      print('❌ Erro ao limpar relatórios antigos: $e');
    }
  }

  // Métodos auxiliares privados
  
  /// Sincroniza relatório com Firestore em background
  void _syncReportInBackground(InsightReport report) {
    Future.delayed(Duration.zero, () async {
      try {
        await remoteDataSource.syncReport(report);
        print('✅ Relatório sincronizado em background: ${report.id}');
      } catch (e) {
        print('⚠️ Erro ao sincronizar relatório em background: $e');
      }
    });
  }

  /// Gera recomendações básicas como fallback
  Future<List<InsightRecommendation>> _generateBasicRecommendations(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final stats = await calculatePeriodStats(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      final recommendations = <InsightRecommendation>[];
      final totalAmount = stats['total_amount'] as double? ?? 0.0;

      if (totalAmount > 0) {
        recommendations.add(InsightRecommendation(
          id: 'basic_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Análise do Período',
          description: 'Você gastou R\$ ${totalAmount.toStringAsFixed(2)} '
                      'no período analisado. Continue acompanhando seus gastos '
                      'para manter o controle financeiro.',
          priority: InsightRecommendationPriority.low,
          actionText: 'Ver Detalhes',
          actionData: {'total_amount': totalAmount},
        ));
      }

      return recommendations;
    } catch (e) {
      print('❌ Erro ao gerar recomendações básicas: $e');
      return [];
    }
  }
}
