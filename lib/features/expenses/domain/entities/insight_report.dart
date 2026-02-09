import 'package:equatable/equatable.dart';

/// Entidade que representa um relatório visual personalizado
class InsightReport extends Equatable {
  final String id;
  final String title;
  final String description;
  final InsightReportType type;
  final DateTime createdAt;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<ChartPoint> chartData;
  final Map<String, dynamic> summary;
  final List<InsightRecommendation> recommendations;
  final String? userId;

  const InsightReport({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.createdAt,
    required this.periodStart,
    required this.periodEnd,
    required this.chartData,
    required this.summary,
    required this.recommendations,
    this.userId,
  });

  /// Factory para criar relatório de gastos por categoria
  factory InsightReport.categorySpending({
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<ChartPoint> chartData,
    required Map<String, dynamic> summary,
    String? userId,
  }) {
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}_category_spending';
    
    return InsightReport(
      id: id,
      title: 'Gastos por Categoria',
      description: 'Análise detalhada dos seus gastos organizados por categoria '
                  'no período selecionado.',
      type: InsightReportType.categorySpending,
      createdAt: now,
      periodStart: periodStart,
      periodEnd: periodEnd,
      chartData: chartData,
      summary: summary,
      recommendations: _generateCategoryRecommendations(chartData, summary),
      userId: userId,
    );
  }

  /// Factory para criar relatório de tendência temporal
  factory InsightReport.spendingTrend({
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<ChartPoint> chartData,
    required Map<String, dynamic> summary,
    String? userId,
  }) {
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}_spending_trend';
    
    return InsightReport(
      id: id,
      title: 'Tendência de Gastos',
      description: 'Evolução dos seus gastos ao longo do tempo com análise '
                  'de padrões e tendências.',
      type: InsightReportType.spendingTrend,
      createdAt: now,
      periodStart: periodStart,
      periodEnd: periodEnd,
      chartData: chartData,
      summary: summary,
      recommendations: _generateTrendRecommendations(chartData, summary),
      userId: userId,
    );
  }

  /// Factory para criar relatório de comparação mensal
  factory InsightReport.monthlyComparison({
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<ChartPoint> chartData,
    required Map<String, dynamic> summary,
    String? userId,
  }) {
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}_monthly_comparison';
    
    return InsightReport(
      id: id,
      title: 'Comparação Mensal',
      description: 'Comparativo dos seus gastos entre diferentes meses '
                  'para identificar padrões sazonais.',
      type: InsightReportType.monthlyComparison,
      createdAt: now,
      periodStart: periodStart,
      periodEnd: periodEnd,
      chartData: chartData,
      summary: summary,
      recommendations: _generateComparisonRecommendations(chartData, summary),
      userId: userId,
    );
  }

  /// Cria uma cópia do relatório com novos valores
  InsightReport copyWith({
    String? id,
    String? title,
    String? description,
    InsightReportType? type,
    DateTime? createdAt,
    DateTime? periodStart,
    DateTime? periodEnd,
    List<ChartPoint>? chartData,
    Map<String, dynamic>? summary,
    List<InsightRecommendation>? recommendations,
    String? userId,
  }) {
    return InsightReport(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      chartData: chartData ?? this.chartData,
      summary: summary ?? this.summary,
      recommendations: recommendations ?? this.recommendations,
      userId: userId ?? this.userId,
    );
  }

  /// Retorna o total de gastos do período
  double get totalAmount {
    return summary['total_amount'] as double? ?? 0.0;
  }

  /// Retorna a média diária de gastos
  double get dailyAverage {
    return summary['daily_average'] as double? ?? 0.0;
  }

  /// Retorna o número de transações
  int get transactionCount {
    return summary['transaction_count'] as int? ?? 0;
  }

  /// Retorna a categoria com maior gasto
  String? get topCategory {
    return summary['top_category'] as String?;
  }

  /// Retorna o valor da categoria com maior gasto
  double get topCategoryAmount {
    return summary['top_category_amount'] as double? ?? 0.0;
  }

  /// Verifica se há dados para exibir
  bool get hasData => chartData.isNotEmpty;

  /// Verifica se há recomendações
  bool get hasRecommendations => recommendations.isNotEmpty;

  /// Retorna a duração do período em dias
  int get periodDays {
    return periodEnd.difference(periodStart).inDays + 1;
  }

  /// Retorna uma descrição formatada do período
  String get periodDescription {
    if (periodDays == 1) {
      return 'Dia ${periodStart.day}/${periodStart.month}/${periodStart.year}';
    } else if (periodDays <= 7) {
      return 'Semana de ${periodStart.day}/${periodStart.month} a ${periodEnd.day}/${periodEnd.month}';
    } else if (periodDays <= 31) {
      return 'Mês ${periodStart.month}/${periodStart.year}';
    } else {
      return 'Período de ${periodStart.day}/${periodStart.month}/${periodStart.year} a ${periodEnd.day}/${periodEnd.month}/${periodEnd.year}';
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        createdAt,
        periodStart,
        periodEnd,
        chartData,
        summary,
        recommendations,
        userId,
      ];

  @override
  String toString() {
    return 'InsightReport(id: $id, title: $title, type: $type, period: $periodDescription)';
  }

  /// Gera recomendações para relatório de categoria
  static List<InsightRecommendation> _generateCategoryRecommendations(
    List<ChartPoint> chartData,
    Map<String, dynamic> summary,
  ) {
    final recommendations = <InsightRecommendation>[];
    
    // Encontra a categoria com maior gasto
    if (chartData.isNotEmpty) {
      final sortedData = List<ChartPoint>.from(chartData)
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final topCategory = sortedData.first;
      if (topCategory.value > 0) {
        recommendations.add(
          InsightRecommendation(
            id: 'top_category_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Categoria com Maior Gasto',
            description: 'Você gastou R\$ ${topCategory.value.toStringAsFixed(2)} '
                        'em ${topCategory.label}. Considere revisar esses gastos.',
            priority: InsightRecommendationPriority.medium,
            actionText: 'Ver Detalhes',
            actionData: {'category': topCategory.label},
          ),
        );
      }
    }
    
    return recommendations;
  }

  /// Gera recomendações para relatório de tendência
  static List<InsightRecommendation> _generateTrendRecommendations(
    List<ChartPoint> chartData,
    Map<String, dynamic> summary,
  ) {
    final recommendations = <InsightRecommendation>[];
    
    if (chartData.length >= 2) {
      final firstValue = chartData.first.value;
      final lastValue = chartData.last.value;
      final trend = lastValue - firstValue;
      
      if (trend > 0) {
        recommendations.add(
          InsightRecommendation(
            id: 'increasing_trend_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Tendência de Aumento',
            description: 'Seus gastos aumentaram R\$ ${trend.toStringAsFixed(2)} '
                        'no período analisado.',
            priority: InsightRecommendationPriority.high,
            actionText: 'Criar Meta de Economia',
            actionData: {'suggested_amount': trend * 0.1},
          ),
        );
      }
    }
    
    return recommendations;
  }

  /// Gera recomendações para relatório de comparação
  static List<InsightRecommendation> _generateComparisonRecommendations(
    List<ChartPoint> chartData,
    Map<String, dynamic> summary,
  ) {
    final recommendations = <InsightRecommendation>[];
    
    // Implementar lógica de comparação
    if (chartData.length >= 2) {
      recommendations.add(
        InsightRecommendation(
          id: 'comparison_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Análise Comparativa',
          description: 'Compare seus gastos entre diferentes períodos '
                      'para identificar padrões.',
          priority: InsightRecommendationPriority.low,
          actionText: 'Ver Histórico',
          actionData: {},
        ),
      );
    }
    
    return recommendations;
  }
}

/// Ponto de dados para gráficos
class ChartPoint extends Equatable {
  final String label;
  final double value;
  final String? color;
  final Map<String, dynamic>? metadata;

  const ChartPoint({
    required this.label,
    required this.value,
    this.color,
    this.metadata,
  });

  @override
  List<Object?> get props => [label, value, color, metadata];

  @override
  String toString() {
    return 'ChartPoint(label: $label, value: $value)';
  }
}

/// Recomendação baseada em insights
class InsightRecommendation extends Equatable {
  final String id;
  final String title;
  final String description;
  final InsightRecommendationPriority priority;
  final String? actionText;
  final Map<String, dynamic>? actionData;

  const InsightRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    this.actionText,
    this.actionData,
  });

  @override
  List<Object?> get props => [id, title, description, priority, actionText, actionData];

  @override
  String toString() {
    return 'InsightRecommendation(id: $id, title: $title, priority: $priority)';
  }
}

/// Tipos de relatórios de insight
enum InsightReportType {
  categorySpending,
  spendingTrend,
  monthlyComparison,
  weeklyAnalysis,
  budgetProgress,
}

/// Prioridades das recomendações
enum InsightRecommendationPriority {
  low,
  medium,
  high,
  critical,
}

