import 'package:get/get.dart';
import '../../domain/entities/financial_insight.dart';
import '../../domain/entities/financial_goal.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/multi_period_comparison.dart';
import 'enhanced_insights_generator.dart';

/// Tipo de insight unificado que pode ser usado em qualquer tela
class UnifiedInsight {
  final String id;
  final String title;
  final String description;
  final UnifiedInsightType type;
  final UnifiedInsightPriority priority;
  final List<String> actionSuggestions;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final String? emoji;
  final String? actionText;

  const UnifiedInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    this.actionSuggestions = const [],
    this.data = const {},
    required this.createdAt,
    this.emoji,
    this.actionText,
  });

  /// Cria a partir de FinancialInsight
  factory UnifiedInsight.fromFinancialInsight(FinancialInsight insight) {
    return UnifiedInsight(
      id: insight.id,
      title: insight.title,
      description: insight.description,
      type: _mapFinancialInsightType(insight.type),
      priority: _mapFinancialInsightPriority(insight.priority),
      actionSuggestions: insight.actionSuggestions,
      data: insight.data,
      createdAt: insight.createdAt,
      emoji: _getEmojiForFinancialInsightType(insight.type),
    );
  }

  /// Cria a partir de ComparisonRecommendation
  factory UnifiedInsight.fromComparisonRecommendation(ComparisonRecommendation rec) {
    return UnifiedInsight(
      id: rec.id,
      title: rec.title,
      description: rec.description,
      type: _mapRecommendationType(rec.type),
      priority: _mapRecommendationPriority(rec.priority),
      actionSuggestions: [],
      data: rec.actionData ?? {},
      createdAt: DateTime.now(),
      emoji: rec.priority.emoji,
      actionText: rec.actionText,
    );
  }

  /// Cria um highlight como insight
  factory UnifiedInsight.fromHighlight(String highlight, int index) {
    return UnifiedInsight(
      id: 'highlight_$index',
      title: 'Destaque',
      description: highlight,
      type: UnifiedInsightType.highlight,
      priority: UnifiedInsightPriority.low,
      createdAt: DateTime.now(),
      emoji: '💡',
    );
  }

  static UnifiedInsightType _mapFinancialInsightType(FinancialInsightType type) {
    switch (type) {
      case FinancialInsightType.budgetWarning:
        return UnifiedInsightType.budgetWarning;
      case FinancialInsightType.budgetExceeded:
        return UnifiedInsightType.budgetExceeded;
      case FinancialInsightType.savingsOpportunity:
        return UnifiedInsightType.savingsOpportunity;
      case FinancialInsightType.spendingPattern:
        return UnifiedInsightType.spendingPattern;
      case FinancialInsightType.goalProgress:
        return UnifiedInsightType.goalProgress;
      default:
        return UnifiedInsightType.general;
    }
  }

  static UnifiedInsightPriority _mapFinancialInsightPriority(FinancialInsightPriority priority) {
    switch (priority) {
      case FinancialInsightPriority.urgent:
        return UnifiedInsightPriority.urgent;
      case FinancialInsightPriority.high:
        return UnifiedInsightPriority.high;
      case FinancialInsightPriority.medium:
        return UnifiedInsightPriority.medium;
      case FinancialInsightPriority.low:
        return UnifiedInsightPriority.low;
    }
  }

  static UnifiedInsightType _mapRecommendationType(RecommendationType type) {
    switch (type) {
      case RecommendationType.savingOpportunity:
        return UnifiedInsightType.savingsOpportunity;
      case RecommendationType.categoryAlert:
        return UnifiedInsightType.budgetWarning;
      case RecommendationType.trendWarning:
        return UnifiedInsightType.trendWarning;
      case RecommendationType.positiveReinforcement:
        return UnifiedInsightType.positiveReinforcement;
      case RecommendationType.actionNeeded:
        return UnifiedInsightType.actionNeeded;
    }
  }

  static UnifiedInsightPriority _mapRecommendationPriority(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.urgent:
        return UnifiedInsightPriority.urgent;
      case RecommendationPriority.high:
        return UnifiedInsightPriority.high;
      case RecommendationPriority.medium:
        return UnifiedInsightPriority.medium;
      case RecommendationPriority.low:
        return UnifiedInsightPriority.low;
    }
  }

  static String _getEmojiForFinancialInsightType(FinancialInsightType type) {
    switch (type) {
      case FinancialInsightType.budgetWarning:
        return '⚠️';
      case FinancialInsightType.budgetExceeded:
        return '🚨';
      case FinancialInsightType.savingsOpportunity:
        return '💰';
      case FinancialInsightType.spendingPattern:
        return '📊';
      case FinancialInsightType.goalProgress:
        return '🎯';
      default:
        return '💡';
    }
  }
}

/// Tipos de insight unificados
enum UnifiedInsightType {
  budgetWarning,
  budgetExceeded,
  savingsOpportunity,
  spendingPattern,
  goalProgress,
  trendWarning,
  positiveReinforcement,
  actionNeeded,
  highlight,
  general,
}

/// Prioridades de insight unificadas
enum UnifiedInsightPriority {
  urgent,
  high,
  medium,
  low,
}

extension UnifiedInsightPriorityExtension on UnifiedInsightPriority {
  String get displayName {
    switch (this) {
      case UnifiedInsightPriority.urgent:
        return 'Urgente';
      case UnifiedInsightPriority.high:
        return 'Alta';
      case UnifiedInsightPriority.medium:
        return 'Média';
      case UnifiedInsightPriority.low:
        return 'Baixa';
    }
  }

  String get emoji {
    switch (this) {
      case UnifiedInsightPriority.urgent:
        return '🚨';
      case UnifiedInsightPriority.high:
        return '⚠️';
      case UnifiedInsightPriority.medium:
        return '💡';
      case UnifiedInsightPriority.low:
        return 'ℹ️';
    }
  }

  int get weight {
    switch (this) {
      case UnifiedInsightPriority.urgent:
        return 4;
      case UnifiedInsightPriority.high:
        return 3;
      case UnifiedInsightPriority.medium:
        return 2;
      case UnifiedInsightPriority.low:
        return 1;
    }
  }
}

/// Serviço unificado para geração de insights
/// 
/// Este serviço combina:
/// - Insights do EnhancedInsightsGenerator (baseados em metas)
/// - Insights do ComparisonInsights (baseados em comparação de períodos)
/// - Insights contextuais adicionais
class UnifiedInsightsService extends GetxService {
  late final EnhancedInsightsGenerator _enhancedGenerator;

  @override
  void onInit() {
    super.onInit();
    _enhancedGenerator = Get.find<EnhancedInsightsGenerator>();
  }

  /// Gera insights unificados combinando todas as fontes
  List<UnifiedInsight> generateUnifiedInsights({
    List<FinancialGoal>? goals,
    List<Expense>? expenses,
    List<ExpenseCategory>? categories,
    MultiPeriodComparison? comparison,
    int maxInsights = 10,
  }) {
    final insights = <UnifiedInsight>[];
    final now = DateTime.now();

    // 1. Adiciona insights baseados em metas (se disponível)
    if (goals != null && expenses != null && categories != null) {
      final financialInsights = _enhancedGenerator.generateSmartInsights(
        goals: goals,
        expenses: expenses,
        categories: categories,
        referenceDate: now,
      );

      for (final insight in financialInsights) {
        insights.add(UnifiedInsight.fromFinancialInsight(insight));
      }
    }

    // 2. Adiciona insights da comparação multi-período (se disponível)
    if (comparison != null) {
      // Adiciona recomendações como insights
      for (final rec in comparison.insights.recommendations) {
        insights.add(UnifiedInsight.fromComparisonRecommendation(rec));
      }

      // Adiciona highlights como insights de baixa prioridade
      for (int i = 0; i < comparison.insights.highlights.length; i++) {
        insights.add(UnifiedInsight.fromHighlight(
          comparison.insights.highlights[i],
          i,
        ));
      }

      // Adiciona insight de tendência
      if (comparison.periods.isNotEmpty) {
        insights.add(_createTrendInsight(comparison));
      }
    }

    // 3. Remove duplicados baseado em IDs similares
    final uniqueInsights = _deduplicateInsights(insights);

    // 4. Ordena por prioridade e data
    uniqueInsights.sort((a, b) {
      final priorityComparison = b.priority.weight.compareTo(a.priority.weight);
      if (priorityComparison != 0) return priorityComparison;
      return b.createdAt.compareTo(a.createdAt);
    });

    return uniqueInsights.take(maxInsights).toList();
  }

  /// Gera insights apenas para relatórios (combinando metas e gastos)
  List<UnifiedInsight> generateReportInsights({
    required List<FinancialGoal> goals,
    required List<Expense> expenses,
    required List<ExpenseCategory> categories,
  }) {
    return generateUnifiedInsights(
      goals: goals,
      expenses: expenses,
      categories: categories,
      maxInsights: 8,
    );
  }

  /// Gera insights apenas para comparação de períodos
  List<UnifiedInsight> generateComparisonInsights({
    required MultiPeriodComparison comparison,
    List<FinancialGoal>? goals,
  }) {
    return generateUnifiedInsights(
      comparison: comparison,
      goals: goals,
      maxInsights: 6,
    );
  }

  /// Enriquece uma comparação com insights do sistema de metas
  MultiPeriodComparison enrichComparisonWithGoalInsights(
    MultiPeriodComparison comparison,
    List<FinancialGoal> goals,
    List<Expense> expenses,
    List<ExpenseCategory> categories,
  ) {
    // Gera insights do sistema de metas
    final goalInsights = _enhancedGenerator.generateSmartInsights(
      goals: goals,
      expenses: expenses,
      categories: categories,
    );

    // Converte para FinancialInsight e adiciona à comparação
    return comparison.copyWith(
      contextualInsights: goalInsights,
    );
  }

  /// Cria insight de tendência
  UnifiedInsight _createTrendInsight(MultiPeriodComparison comparison) {
    final trend = comparison.trend;
    
    String description;
    UnifiedInsightPriority priority;
    
    switch (trend) {
      case ComparisonTrend.increasing:
        description = 'Seus gastos estão aumentando. ${comparison.overallChangePercentage.toStringAsFixed(1)}% de variação no período.';
        priority = UnifiedInsightPriority.high;
        break;
      case ComparisonTrend.decreasing:
        description = 'Parabéns! Seus gastos diminuíram ${comparison.overallChangePercentage.abs().toStringAsFixed(1)}% no período.';
        priority = UnifiedInsightPriority.low;
        break;
      case ComparisonTrend.volatile:
        description = 'Seus gastos variam muito entre os períodos. Considere estabelecer um orçamento mais consistente.';
        priority = UnifiedInsightPriority.medium;
        break;
      case ComparisonTrend.stable:
        description = 'Seus gastos estão estáveis. Média de R\$ ${comparison.averageSpending.toStringAsFixed(2)} por mês.';
        priority = UnifiedInsightPriority.low;
        break;
    }

    return UnifiedInsight(
      id: 'trend_${comparison.id}',
      title: trend.displayName,
      description: description,
      type: UnifiedInsightType.trendWarning,
      priority: priority,
      createdAt: DateTime.now(),
      emoji: trend.emoji,
      data: {
        'trend': trend.name,
        'changePercentage': comparison.overallChangePercentage,
        'averageSpending': comparison.averageSpending,
      },
    );
  }

  /// Remove insights duplicados ou muito similares
  List<UnifiedInsight> _deduplicateInsights(List<UnifiedInsight> insights) {
    final seen = <String>{};
    final unique = <UnifiedInsight>[];

    for (final insight in insights) {
      // Cria uma chave baseada no tipo e dados relevantes
      final key = '${insight.type}_${insight.data['categoryId'] ?? ''}_${insight.data['categoryName'] ?? ''}';
      
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(insight);
      }
    }

    return unique;
  }
}



