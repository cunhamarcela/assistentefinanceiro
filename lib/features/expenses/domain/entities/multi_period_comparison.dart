import 'package:equatable/equatable.dart';
import 'budget_comparison_data.dart';
import 'enhanced_score.dart';
import 'gamification_impact.dart';
import 'financial_insight.dart';
import '../../../onboarding/data/models/onboarding_question_model.dart';

/// Entidade para comparação de gastos entre múltiplos períodos
class MultiPeriodComparison extends Equatable {
  final String id;
  final String userId;
  final DateTime createdAt;
  final ComparisonPeriodType periodType;
  final List<PeriodData> periods;
  final ComparisonInsights insights;
  final ComparisonTrend trend;
  
  // Novos campos para integração
  final BudgetComparisonData? budgetComparison; // Comparação vs orçamento
  final List<FinancialInsight> contextualInsights; // Insights do EnhancedInsightsGenerator
  final GamificationImpact? gamificationImpact; // Impacto em pontos/badges
  final OnboardingProfileModel? onboardingContext; // Contexto do onboarding
  final EnhancedScore? enhancedScore; // Score expandido

  const MultiPeriodComparison({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.periodType,
    required this.periods,
    required this.insights,
    required this.trend,
    this.budgetComparison,
    this.contextualInsights = const [],
    this.gamificationImpact,
    this.onboardingContext,
    this.enhancedScore,
  });

  /// Calcula a média de gastos de todos os períodos
  double get averageSpending {
    if (periods.isEmpty) return 0.0;
    final total = periods.fold(0.0, (sum, period) => sum + period.totalSpent);
    return total / periods.length;
  }

  /// Encontra o período com maior gasto
  PeriodData? get highestSpendingPeriod {
    if (periods.isEmpty) return null;
    return periods.reduce((a, b) => a.totalSpent > b.totalSpent ? a : b);
  }

  /// Encontra o período com menor gasto
  PeriodData? get lowestSpendingPeriod {
    if (periods.isEmpty) return null;
    return periods.reduce((a, b) => a.totalSpent < b.totalSpent ? a : b);
  }

  /// Calcula a variação percentual entre primeiro e último período
  double get overallChangePercentage {
    if (periods.length < 2) return 0.0;
    final first = periods.first.totalSpent;
    final last = periods.last.totalSpent;
    if (first == 0) return 0.0;
    return ((last - first) / first) * 100;
  }

  /// Verifica se há tendência de crescimento
  bool get isIncreasingTrend => trend == ComparisonTrend.increasing;

  /// Verifica se há tendência de decrescimento
  bool get isDecreasingTrend => trend == ComparisonTrend.decreasing;

  /// Verifica se está estável
  bool get isStableTrend => trend == ComparisonTrend.stable;

  @override
  List<Object?> get props => [
        id,
        userId,
        createdAt,
        periodType,
        periods,
        insights,
        trend,
        budgetComparison,
        contextualInsights,
        gamificationImpact,
        onboardingContext,
        enhancedScore,
      ];

  MultiPeriodComparison copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    ComparisonPeriodType? periodType,
    List<PeriodData>? periods,
    ComparisonInsights? insights,
    ComparisonTrend? trend,
    BudgetComparisonData? budgetComparison,
    List<FinancialInsight>? contextualInsights,
    GamificationImpact? gamificationImpact,
    OnboardingProfileModel? onboardingContext,
    EnhancedScore? enhancedScore,
  }) {
    return MultiPeriodComparison(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      periodType: periodType ?? this.periodType,
      periods: periods ?? this.periods,
      insights: insights ?? this.insights,
      trend: trend ?? this.trend,
      budgetComparison: budgetComparison ?? this.budgetComparison,
      contextualInsights: contextualInsights ?? this.contextualInsights,
      gamificationImpact: gamificationImpact ?? this.gamificationImpact,
      onboardingContext: onboardingContext ?? this.onboardingContext,
      enhancedScore: enhancedScore ?? this.enhancedScore,
    );
  }
}

/// Dados de um período específico
class PeriodData extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final double totalSpent;
  final int transactionCount;
  final Map<String, double> categoryBreakdown;
  final double averagePerDay;
  final String? topCategory;
  final double? topCategoryAmount;
  
  // Novos campos para integração com orçamento
  final double? budgetLimit; // Orçamento do período
  final double? budgetAdherence; // % de aderência ao orçamento (0-100+)
  final Map<String, CategoryPeriodData> categoryDetails; // Detalhes por categoria

  const PeriodData({
    required this.startDate,
    required this.endDate,
    required this.totalSpent,
    required this.transactionCount,
    required this.categoryBreakdown,
    required this.averagePerDay,
    this.topCategory,
    this.topCategoryAmount,
    this.budgetLimit,
    this.budgetAdherence,
    this.categoryDetails = const {},
  });

  /// Retorna o nome do período formatado
  String get periodName {
    final month = _getMonthName(startDate.month);
    return '$month/${startDate.year}';
  }

  /// Retorna o nome curto do período
  String get shortPeriodName {
    return '${_getMonthAbbr(startDate.month)}/${startDate.year.toString().substring(2)}';
  }

  /// Número de dias no período
  int get periodDays => endDate.difference(startDate).inDays + 1;

  String _getMonthName(int month) {
    const months = [
      '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return months[month];
  }

  String _getMonthAbbr(int month) {
    const months = [
      '', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return months[month];
  }

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        totalSpent,
        transactionCount,
        categoryBreakdown,
        averagePerDay,
        topCategory,
        topCategoryAmount,
        budgetLimit,
        budgetAdherence,
        categoryDetails,
      ];
}

/// Detalhes de uma categoria em um período específico
class CategoryPeriodData extends Equatable {
  final String categoryId;
  final String categoryName;
  final double spent; // Gasto real
  final double? limit; // Limite da meta (se houver)
  final double? adherence; // % de aderência (se houver meta)
  final bool? isExceeded; // Se excedeu o limite

  const CategoryPeriodData({
    required this.categoryId,
    required this.categoryName,
    required this.spent,
    this.limit,
    this.adherence,
    this.isExceeded,
  });

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        spent,
        limit,
        adherence,
        isExceeded,
      ];
}

/// Insights gerados pela comparação
class ComparisonInsights extends Equatable {
  final String summary;
  final List<String> highlights;
  final List<ComparisonRecommendation> recommendations;
  final ComparisonScore score;

  const ComparisonInsights({
    required this.summary,
    required this.highlights,
    required this.recommendations,
    required this.score,
  });

  @override
  List<Object?> get props => [summary, highlights, recommendations, score];
}

/// Recomendação baseada na comparação
class ComparisonRecommendation extends Equatable {
  final String id;
  final String title;
  final String description;
  final RecommendationType type;
  final RecommendationPriority priority;
  final String? actionText;
  final Map<String, dynamic>? actionData;

  const ComparisonRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    this.actionText,
    this.actionData,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        priority,
        actionText,
        actionData,
      ];
}

/// Pontuação da comparação (para gamificação)
class ComparisonScore extends Equatable {
  final double overallScore; // 0 a 100
  final double improvementScore; // 0 a 100
  final double consistencyScore; // 0 a 100
  final String grade; // A+, A, B+, B, C, D, F

  const ComparisonScore({
    required this.overallScore,
    required this.improvementScore,
    required this.consistencyScore,
    required this.grade,
  });

  /// Retorna cor baseada na nota
  /// 
  /// @deprecated Use `ScoreColorHelper.getGradeColor(grade)` ou a extension 
  /// `score.gradeColorToken` da camada de apresentação para obter a cor 
  /// do Design System. Esta propriedade retorna strings HEX para 
  /// compatibilidade retroativa mas viola as Cursor Rules.
  /// 
  /// Veja: `lib/features/expenses/presentation/helpers/score_color_helper.dart`
  @Deprecated('Use ScoreColorHelper.getGradeColor(grade) na apresentação')
  String get gradeColor {
    switch (grade) {
      case 'A+':
      case 'A':
        return '#3CB371'; // colorSuccess
      case 'B+':
      case 'B':
        return '#1A3D63'; // colorBrandPrimary
      case 'C':
        return '#E9C46A'; // colorWarning
      case 'D':
        return '#FF9500'; // Orange
      case 'F':
        return '#E76F51'; // colorError
      default:
        return '#4A7FA7'; // colorTextMuted
    }
  }

  /// Retorna emoji baseado na nota
  String get gradeEmoji {
    switch (grade) {
      case 'A+':
      case 'A':
        return '🎉';
      case 'B+':
      case 'B':
        return '👍';
      case 'C':
        return '💪';
      case 'D':
        return '⚠️';
      case 'F':
        return '🚨';
      default:
        return '📊';
    }
  }

  @override
  List<Object?> get props => [
        overallScore,
        improvementScore,
        consistencyScore,
        grade,
      ];
}

/// Tipo de período de comparação
enum ComparisonPeriodType {
  threeMonths,
  sixMonths,
  twelveMonths,
  custom,
}

extension ComparisonPeriodTypeExtension on ComparisonPeriodType {
  String get displayName {
    switch (this) {
      case ComparisonPeriodType.threeMonths:
        return '3 Meses';
      case ComparisonPeriodType.sixMonths:
        return '6 Meses';
      case ComparisonPeriodType.twelveMonths:
        return '12 Meses';
      case ComparisonPeriodType.custom:
        return 'Personalizado';
    }
  }

  int get monthCount {
    switch (this) {
      case ComparisonPeriodType.threeMonths:
        return 3;
      case ComparisonPeriodType.sixMonths:
        return 6;
      case ComparisonPeriodType.twelveMonths:
        return 12;
      case ComparisonPeriodType.custom:
        return 0;
    }
  }

  String get emoji {
    switch (this) {
      case ComparisonPeriodType.threeMonths:
        return '📊';
      case ComparisonPeriodType.sixMonths:
        return '📈';
      case ComparisonPeriodType.twelveMonths:
        return '🎯';
      case ComparisonPeriodType.custom:
        return '⚙️';
    }
  }
}

/// Tendência da comparação
enum ComparisonTrend {
  increasing, // Gastos aumentando
  decreasing, // Gastos diminuindo
  stable, // Gastos estáveis
  volatile, // Gastos muito variáveis
}

extension ComparisonTrendExtension on ComparisonTrend {
  String get displayName {
    switch (this) {
      case ComparisonTrend.increasing:
        return 'Crescente';
      case ComparisonTrend.decreasing:
        return 'Decrescente';
      case ComparisonTrend.stable:
        return 'Estável';
      case ComparisonTrend.volatile:
        return 'Variável';
    }
  }

  String get emoji {
    switch (this) {
      case ComparisonTrend.increasing:
        return '📈';
      case ComparisonTrend.decreasing:
        return '📉';
      case ComparisonTrend.stable:
        return '➡️';
      case ComparisonTrend.volatile:
        return '📊';
    }
  }

  String get description {
    switch (this) {
      case ComparisonTrend.increasing:
        return 'Seus gastos estão aumentando ao longo do tempo';
      case ComparisonTrend.decreasing:
        return 'Seus gastos estão diminuindo - parabéns!';
      case ComparisonTrend.stable:
        return 'Seus gastos mantêm um padrão consistente';
      case ComparisonTrend.volatile:
        return 'Seus gastos variam bastante entre períodos';
    }
  }
}

/// Tipo de recomendação
enum RecommendationType {
  savingOpportunity,
  categoryAlert,
  trendWarning,
  positiveReinforcement,
  actionNeeded,
}

/// Prioridade da recomendação
enum RecommendationPriority {
  low,
  medium,
  high,
  urgent,
}

extension RecommendationPriorityExtension on RecommendationPriority {
  String get displayName {
    switch (this) {
      case RecommendationPriority.low:
        return 'Baixa';
      case RecommendationPriority.medium:
        return 'Média';
      case RecommendationPriority.high:
        return 'Alta';
      case RecommendationPriority.urgent:
        return 'Urgente';
    }
  }

  String get emoji {
    switch (this) {
      case RecommendationPriority.low:
        return 'ℹ️';
      case RecommendationPriority.medium:
        return '💡';
      case RecommendationPriority.high:
        return '⚠️';
      case RecommendationPriority.urgent:
        return '🚨';
    }
  }
}



