import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/insight_report.dart';
import '../../domain/usecases/generate_insight_report_usecase.dart';
import '../../domain/entities/financial_insight.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/services/auth_service.dart';

/// Controller para gerenciar relatórios visuais
class ReportsController extends GetxController {
  final GenerateInsightReportUseCase generateReportUseCase;
  final AnalyticsService analyticsService;
  late final AuthService _authService;

  ReportsController({
    required this.generateReportUseCase,
    required this.analyticsService,
  });

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
    _initializeReports();
  }

  /// Obtém o ID do usuário atual
  String? get _currentUserId => _authService.currentUser?.id;

  // Estados observáveis
  final RxList<InsightReport> reports = <InsightReport>[].obs;
  final Rx<InsightReport?> currentReport = Rx<InsightReport?>(null);
  final RxList<FinancialInsight> insights = <FinancialInsight>[].obs;
  
  // Estados de UI
  final RxBool isLoading = false.obs;
  final RxBool isGeneratingReport = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Filtros e configurações
  final Rx<ReportPeriod> selectedPeriod = ReportPeriod.thisMonth.obs;
  final Rx<InsightReportType> selectedReportType = InsightReportType.categorySpending.obs;


  /// Inicializa os relatórios
  Future<void> _initializeReports() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await Future.wait([
        loadReports(),
        generateDefaultReport(),
        loadInsights(),
      ]);

      // Registra evento de visualização
      await analyticsService.trackReportEvent(
        type: ReportEventType.viewed,
        reportType: selectedReportType.value.name,
        properties: {
          'period': selectedPeriod.value.name,
          'reports_count': reports.length,
        },
      );
    } catch (e) {
      errorMessage.value = 'Erro ao carregar relatórios: $e';
      _showError('Erro ao carregar relatórios', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Carrega relatórios existentes
  Future<void> loadReports() async {
    try {
      // TODO: Implementar carregamento de relatórios salvos
      // Por enquanto, lista vazia
      reports.clear();
    } catch (e) {
      print('Erro ao carregar relatórios: $e');
    }
  }

  /// Gera relatório padrão
  Future<void> generateDefaultReport() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        print('❌ Usuário não autenticado para gerar relatório');
        _createEmptyReport();
        return;
      }

      final report = await generateReportUseCase.generatePeriodReport(
        userId: userId,
        type: selectedReportType.value,
        period: selectedPeriod.value,
      );

      currentReport.value = report;
      
      if (!reports.any((r) => r.id == report.id)) {
        reports.add(report);
      }
      
      // Gerar insights após criar o relatório
      await loadInsights();
    } catch (e) {
      print('❌ Erro ao gerar relatório padrão: $e');
      // Cria relatório vazio para evitar erros de UI
      _createEmptyReport();
    }
  }

  /// Carrega insights financeiros
  Future<void> loadInsights() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        print('❌ Usuário não autenticado para carregar insights');
        insights.clear();
        return;
      }

      print('🔍 Carregando insights para usuário: $userId');

      // Gerar insights baseados nos dados reais do relatório atual
      final report = currentReport.value;
      if (report != null) {
        print('📊 Relatório disponível: ${report.title}');
        print('📊 Dados do gráfico: ${report.chartData.length} itens');
        print('📊 Total gasto: ${report.summary['total_amount']}');
        
        final generatedInsights = await _generateInsightsFromReport(report);
        insights.value = generatedInsights;
        
        print('💡 ${generatedInsights.length} insights gerados');
        for (final insight in generatedInsights) {
          print('💡 - ${insight.title}');
        }
      } else {
        print('⚠️ Nenhum relatório disponível para gerar insights');
        insights.clear();
      }
    } catch (e) {
      print('❌ Erro ao carregar insights: $e');
      insights.clear();
    }
  }

  /// Muda período do relatório
  Future<void> changePeriod(ReportPeriod period) async {
    if (selectedPeriod.value == period) return;

    selectedPeriod.value = period;
    await generateDefaultReport();

    // Registra evento de mudança de período
    await analyticsService.trackReportEvent(
      type: ReportEventType.generated,
      reportType: selectedReportType.value.name,
      properties: {
        'period': period.name,
        'trigger': 'period_change',
      },
    );
  }

  /// Muda tipo do relatório
  Future<void> changeReportType(InsightReportType type) async {
    if (selectedReportType.value == type) return;

    selectedReportType.value = type;
    await generateDefaultReport();

    // Registra evento de mudança de tipo
    await analyticsService.trackReportEvent(
      type: ReportEventType.generated,
      reportType: type.name,
      properties: {
        'period': selectedPeriod.value.name,
        'trigger': 'type_change',
      },
    );
  }

  /// Gera novo relatório
  Future<void> generateNewReport() async {
    try {
      isGeneratingReport.value = true;
      
      // TODO: Implementar seleção de parâmetros do relatório
      await generateDefaultReport();
      
      Get.snackbar(
        'Relatório Gerado',
        'Novo relatório criado com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      _showError('Erro ao gerar relatório', e.toString());
    } finally {
      isGeneratingReport.value = false;
    }
  }

  /// Atualiza relatórios
  Future<void> refreshReports() async {
    await _initializeReports();
  }

  /// Compartilha relatório atual
  Future<void> shareCurrentReport() async {
    final report = currentReport.value;
    if (report == null) return;

    try {
      // TODO: Implementar compartilhamento real
      Get.snackbar(
        'Compartilhar',
        'Funcionalidade de compartilhamento em desenvolvimento',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Registra evento de compartilhamento
      await analyticsService.trackReportEvent(
        type: ReportEventType.shared,
        reportType: report.type.name,
        properties: {
          'report_id': report.id,
          'period': selectedPeriod.value.name,
        },
      );
    } catch (e) {
      _showError('Erro ao compartilhar', e.toString());
    }
  }

  /// Exporta relatório atual
  Future<void> exportCurrentReport() async {
    final report = currentReport.value;
    if (report == null) return;

    try {
      // TODO: Implementar exportação real
      Get.snackbar(
        'Exportar',
        'Funcionalidade de exportação em desenvolvimento',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Registra evento de exportação
      await analyticsService.trackReportEvent(
        type: ReportEventType.exported,
        reportType: report.type.name,
        properties: {
          'report_id': report.id,
          'format': 'pdf',
        },
      );
    } catch (e) {
      _showError('Erro ao exportar', e.toString());
    }
  }

  /// Agenda relatório
  Future<void> scheduleReport() async {
    // TODO: Implementar agendamento de relatórios
    Get.snackbar(
      'Agendar',
      'Funcionalidade de agendamento em desenvolvimento',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Mostra configurações de relatório
  Future<void> showReportSettings() async {
    // TODO: Implementar configurações de relatório
    Get.snackbar(
      'Configurações',
      'Configurações de relatório em desenvolvimento',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Mostra detalhes do relatório
  Future<void> showReportDetails(InsightReport report) async {
    // TODO: Implementar tela de detalhes do relatório
    Get.snackbar(
      'Detalhes',
      'Detalhes do relatório: ${report.title}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Mostra detalhes do gráfico
  Future<void> showChartDetails(String chartType) async {
    // TODO: Implementar tela de detalhes do gráfico
    Get.snackbar(
      'Gráfico',
      'Detalhes do gráfico: $chartType',
      snackPosition: SnackPosition.BOTTOM,
    );

    // Registra evento de interação com gráfico
    await analyticsService.trackReportEvent(
      type: ReportEventType.chartInteracted,
      properties: {
        'chart_type': chartType,
        'report_type': selectedReportType.value.name,
      },
    );
  }

  /// Mostra todos os insights
  Future<void> showAllInsights() async {
    // TODO: Implementar tela de todos os insights
    Get.snackbar(
      'Insights',
      'Todos os insights financeiros',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Mostra detalhes do insight
  Future<void> showInsightDetails(FinancialInsight insight) async {
    // TODO: Implementar tela de detalhes do insight
    Get.snackbar(
      'Insight',
      insight.title,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Manipula ação do insight
  Future<void> handleInsightAction(FinancialInsight insight) async {
    if (insight.actionSuggestions.isEmpty) return;

    try {
      // TODO: Implementar navegação baseada na ação
      Get.snackbar(
        'Ação',
        'Executando: ${insight.actionSuggestions.first}',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Registra evento de clique no insight
      await analyticsService.trackReportEvent(
        type: ReportEventType.insightClicked,
        properties: {
          'insight_id': insight.id,
          'insight_type': insight.type.name,
          'action': insight.actionSuggestions.first,
        },
      );
    } catch (e) {
      _showError('Erro na ação', e.toString());
    }
  }

  /// Manipula ação da recomendação
  Future<void> handleRecommendationAction(InsightRecommendation recommendation) async {
    if (recommendation.actionText == null) return;

    try {
      // TODO: Implementar ações das recomendações
      Get.snackbar(
        'Recomendação',
        'Executando: ${recommendation.actionText}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _showError('Erro na recomendação', e.toString());
    }
  }

  /// Obtém dados do gráfico de categorias
  List<ChartPoint> get categoryChartData {
    final report = currentReport.value;
    if (report == null || report.type != InsightReportType.categorySpending) {
      return [];
    }
    return report.chartData;
  }

  /// Obtém dados do gráfico de tendência
  List<ChartPoint> get trendChartData {
    final report = currentReport.value;
    if (report == null || report.type != InsightReportType.spendingTrend) {
      return [];
    }
    return report.chartData;
  }

  /// Obtém dados do gráfico de comparação
  List<ChartPoint> get comparisonChartData {
    final report = currentReport.value;
    if (report == null || report.type != InsightReportType.monthlyComparison) {
      return [];
    }
    return report.chartData;
  }

  /// Obtém insights atuais
  List<FinancialInsight> get currentInsights => insights;

  /// Obtém recomendações atuais
  List<InsightRecommendation> get currentRecommendations {
    final report = currentReport.value;
    return report?.recommendations ?? [];
  }

  /// Cria relatório vazio
  void _createEmptyReport() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    currentReport.value = InsightReport(
      id: 'empty_${now.millisecondsSinceEpoch}',
      title: 'Relatório Vazio',
      description: 'Nenhum dado disponível para o período selecionado',
      type: selectedReportType.value,
      createdAt: now,
      periodStart: startOfMonth,
      periodEnd: now,
      chartData: [],
      summary: {
        'total_amount': 0.0,
        'transaction_count': 0,
        'daily_average': 0.0,
      },
      recommendations: [],
    );
  }

  /// Gera insights baseados no relatório atual
  Future<List<FinancialInsight>> _generateInsightsFromReport(InsightReport report) async {
    try {
      final insights = <FinancialInsight>[];
      final totalSpent = report.summary['total_amount'] as double? ?? 0.0;
      final transactionCount = report.summary['transaction_count'] as int? ?? 0;
      
      print('🔍 Analisando relatório para insights:');
      print('   - Total gasto: R\$ ${totalSpent.toStringAsFixed(2)}');
      print('   - Transações: $transactionCount');
      print('   - Categorias: ${report.chartData.length}');
      
      // Insight básico sobre total de gastos
      if (totalSpent > 0) {
        insights.add(FinancialInsight(
          id: 'total_spending_${DateTime.now().millisecondsSinceEpoch}',
          type: FinancialInsightType.categoryAnalysis,
          priority: FinancialInsightPriority.medium,
          title: 'Resumo dos Gastos 📊',
          description: 'Você gastou R\$ ${totalSpent.toStringAsFixed(2)} no período analisado, com um total de $transactionCount transações.',
          data: {
            'total_amount': totalSpent,
            'transaction_count': transactionCount,
            'average_per_transaction': transactionCount > 0 ? totalSpent / transactionCount : 0.0,
          },
          actionSuggestions: [
            'Monitore seus gastos regularmente',
            'Considere definir metas de orçamento',
            'Analise os padrões de gastos por categoria',
          ],
          createdAt: DateTime.now(),
          isRead: false,
        ));
      }
      
      // Analisar gastos por categoria
      if (report.chartData.isNotEmpty && totalSpent > 0) {
        final topCategory = report.chartData.first;
        final percentage = (topCategory.value / totalSpent) * 100;
        
        if (percentage > 60) { // Mais de 60% em uma categoria
          insights.add(FinancialInsight(
            id: 'excessive_spending_${DateTime.now().millisecondsSinceEpoch}',
            type: FinancialInsightType.budgetWarning,
            priority: FinancialInsightPriority.high,
            title: 'Concentração de Gastos: ${topCategory.label} ⚠️',
            description: 'Você gastou R\$ ${topCategory.value.toStringAsFixed(2)} em ${topCategory.label}, que representa ${percentage.round()}% do total. Considere diversificar seus gastos.',
            data: {
              'amount': topCategory.value,
              'category': topCategory.label,
              'percentage': percentage,
              'ideal_percentage': 40.0,
            },
            actionSuggestions: ['Revisar Gastos', 'Definir Limite'],
            createdAt: DateTime.now(),
            isRead: false,
          ));
        }
      }
      
      // Analisar tendência de gastos
      if (report.type == InsightReportType.spendingTrend) {
        final trend = report.summary['trend'] as double? ?? 0.0;
        if (trend > 0) {
          insights.add(FinancialInsight(
            id: 'trend_alert_${DateTime.now().millisecondsSinceEpoch}',
            type: FinancialInsightType.spendingPattern,
            priority: FinancialInsightPriority.medium,
            title: 'Tendência de Aumento nos Gastos 📈',
            description: 'Seus gastos aumentaram R\$ ${trend.toStringAsFixed(2)} nas últimas semanas. Fique atento para não sair do orçamento!',
            data: {'trend_type': 'increasing', 'amount': trend, 'period': 'últimas semanas'},
            actionSuggestions: ['Revisar Gastos', 'Ajustar Orçamento'],
            createdAt: DateTime.now(),
            isRead: false,
          ));
        }
      }
      
      // Sugerir oportunidades de economia
      if (report.chartData.length > 1) {
        final secondCategory = report.chartData[1];
        if (secondCategory.value > 200.0) { // Valor significativo
          insights.add(FinancialInsight(
            id: 'savings_opportunity_${DateTime.now().millisecondsSinceEpoch}',
            type: FinancialInsightType.savingsOpportunity,
            priority: FinancialInsightPriority.medium,
            title: 'Oportunidade de Economia em ${secondCategory.label} 💡',
            description: 'Analise seus gastos em ${secondCategory.label} para encontrar oportunidades de economia. Você poderia economizar até R\$ ${(secondCategory.value * 0.15).toStringAsFixed(2)}.',
            data: {
              'category': secondCategory.label,
              'current_amount': secondCategory.value,
              'potential_savings': secondCategory.value * 0.15,
              'savings_percentage': 15.0,
            },
            actionSuggestions: ['Analisar Gastos', 'Definir Meta'],
            createdAt: DateTime.now(),
            isRead: false,
          ));
        }
      }
      
      return insights;
    } catch (e) {
      print('❌ Erro ao gerar insights do relatório: $e');
      return [];
    }
  }

  /// Mostra erro
  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.error,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }
}
