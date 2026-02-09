import '../entities/multi_period_comparison.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';
import '../../data/services/smart_comparison_service.dart';

/// Use case para gerar comparação entre múltiplos períodos
/// 
/// Agora delega para o SmartComparisonService que integra com
/// todas as funcionalidades do app (metas, insights, gamificação).
/// 
/// Mantém fallback para o sistema antigo caso o serviço não esteja disponível.
class GenerateMultiPeriodComparisonUseCase {
  final ExpenseRepository repository;
  final SmartComparisonService? smartComparisonService;

  GenerateMultiPeriodComparisonUseCase(
    this.repository, {
    this.smartComparisonService,
  });

  /// Gera comparação para um tipo de período específico
  /// 
  /// Se o SmartComparisonService estiver disponível, usa o sistema
  /// integrado com metas, insights e gamificação.
  /// Caso contrário, usa o sistema legado.
  Future<MultiPeriodComparison> execute({
    required String userId,
    required ComparisonPeriodType periodType,
    bool forceRefresh = false,
  }) async {
    // Usa o serviço inteligente se disponível
    if (smartComparisonService != null) {
      return await smartComparisonService!.generateEnhancedComparison(
        userId: userId,
        periodType: periodType,
        forceRefresh: forceRefresh,
      );
    }
    
    // Fallback para o sistema legado
    return await _executeLegacy(userId: userId, periodType: periodType);
  }

  /// Sistema legado de comparação (mantido para compatibilidade)
  Future<MultiPeriodComparison> _executeLegacy({
    required String userId,
    required ComparisonPeriodType periodType,
  }) async {
    // Calcula datas baseado no tipo de período
    final periods = _generatePeriods(periodType);
    
    // Busca gastos para cada período
    final periodDataList = <PeriodData>[];
    
    for (final period in periods) {
      final expenses = await repository.getExpensesByDateRange(
        period['start']!,
        period['end']!,
      );
      
      final periodData = _calculatePeriodData(
        expenses,
        period['start']!,
        period['end']!,
      );
      
      periodDataList.add(periodData);
    }

    // Gera insights e tendência
    final insights = _generateInsights(periodDataList, periodType);
    final trend = _calculateTrend(periodDataList);

    return MultiPeriodComparison(
      id: '${DateTime.now().millisecondsSinceEpoch}_$userId',
      userId: userId,
      createdAt: DateTime.now(),
      periodType: periodType,
      periods: periodDataList,
      insights: insights,
      trend: trend,
    );
  }

  /// Gera lista de períodos baseado no tipo
  List<Map<String, DateTime>> _generatePeriods(ComparisonPeriodType type) {
    final now = DateTime.now();
    final periods = <Map<String, DateTime>>[];
    final monthCount = type.monthCount;

    for (int i = monthCount - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      
      periods.add({
        'start': startDate,
        'end': endDate,
      });
    }

    return periods;
  }

  /// Calcula dados de um período
  PeriodData _calculatePeriodData(
    List<Expense> expenses,
    DateTime startDate,
    DateTime endDate,
  ) {
    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final transactionCount = expenses.length;
    
    // Agrupa por categoria
    final categoryBreakdown = <String, double>{};
    for (final expense in expenses) {
      categoryBreakdown[expense.categoryId] =
          (categoryBreakdown[expense.categoryId] ?? 0.0) + expense.amount;
    }

    // Encontra categoria com maior gasto
    String? topCategory;
    double? topCategoryAmount;
    if (categoryBreakdown.isNotEmpty) {
      final sortedEntries = categoryBreakdown.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topCategory = sortedEntries.first.key;
      topCategoryAmount = sortedEntries.first.value;
    }

    final periodDays = endDate.difference(startDate).inDays + 1;
    final averagePerDay = totalSpent / periodDays;

    return PeriodData(
      startDate: startDate,
      endDate: endDate,
      totalSpent: totalSpent,
      transactionCount: transactionCount,
      categoryBreakdown: categoryBreakdown,
      averagePerDay: averagePerDay,
      topCategory: topCategory,
      topCategoryAmount: topCategoryAmount,
    );
  }

  /// Gera insights baseados nos dados dos períodos
  ComparisonInsights _generateInsights(
    List<PeriodData> periods,
    ComparisonPeriodType periodType,
  ) {
    if (periods.isEmpty) {
      return ComparisonInsights(
        summary: 'Sem dados suficientes para análise',
        highlights: [],
        recommendations: [],
        score: ComparisonScore(
          overallScore: 0,
          improvementScore: 0,
          consistencyScore: 0,
          grade: 'F',
        ),
      );
    }

    final highlights = <String>[];
    final recommendations = <ComparisonRecommendation>[];

    // Análise de tendência
    if (periods.length >= 2) {
      final first = periods.first.totalSpent;
      final last = periods.last.totalSpent;
      final change = first > 0 ? ((last - first) / first * 100) : 0.0;

      if (change > 20) {
        highlights.add('Seus gastos aumentaram ${change.toStringAsFixed(1)}% no período');
        recommendations.add(ComparisonRecommendation(
          id: 'high_increase_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Gastos Crescentes',
          description: 'Seus gastos têm aumentado significativamente. '
              'Considere revisar seu orçamento.',
          type: RecommendationType.trendWarning,
          priority: RecommendationPriority.high,
          actionText: 'Revisar Orçamento',
        ));
      } else if (change < -10) {
        highlights.add('Parabéns! Você reduziu seus gastos em ${change.abs().toStringAsFixed(1)}%');
        recommendations.add(ComparisonRecommendation(
          id: 'reduction_success_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Ótimo Progresso!',
          description: 'Você está economizando mais! Continue assim.',
          type: RecommendationType.positiveReinforcement,
          priority: RecommendationPriority.medium,
          actionText: 'Ver Detalhes',
        ));
      }
    }

    // Análise de categoria mais cara
    final allCategories = <String, double>{};
    for (final period in periods) {
      period.categoryBreakdown.forEach((cat, amount) {
        allCategories[cat] = (allCategories[cat] ?? 0.0) + amount;
      });
    }

    if (allCategories.isNotEmpty) {
      final topEntry = allCategories.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      highlights.add('Maior gasto: R\$ ${topEntry.value.toStringAsFixed(2)}');
      
      recommendations.add(ComparisonRecommendation(
        id: 'top_category_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Categoria de Maior Gasto',
        description: 'Considere criar uma meta de redução para esta categoria.',
        type: RecommendationType.savingOpportunity,
        priority: RecommendationPriority.medium,
        actionText: 'Criar Meta',
        actionData: {'categoryId': topEntry.key},
      ));
    }

    // Calcula score
    final score = _calculateScore(periods);

    // Summary
    final avg = periods.fold(0.0, (s, p) => s + p.totalSpent) / periods.length;
    final summary = 'Média de R\$ ${avg.toStringAsFixed(2)} por mês nos últimos '
        '${periodType.displayName.toLowerCase()}';

    return ComparisonInsights(
      summary: summary,
      highlights: highlights,
      recommendations: recommendations,
      score: score,
    );
  }

  /// Calcula score de desempenho
  ComparisonScore _calculateScore(List<PeriodData> periods) {
    if (periods.isEmpty) {
      return const ComparisonScore(
        overallScore: 0,
        improvementScore: 0,
        consistencyScore: 0,
        grade: 'F',
      );
    }

    // Score de melhoria (se está diminuindo gastos)
    double improvementScore = 50.0;
    if (periods.length >= 2) {
      final first = periods.first.totalSpent;
      final last = periods.last.totalSpent;
      if (first > 0) {
        final improvement = ((first - last) / first) * 100;
        improvementScore = (50 + improvement).clamp(0, 100);
      }
    }

    // Score de consistência (menor variação é melhor)
    final avg = periods.fold(0.0, (s, p) => s + p.totalSpent) / periods.length;
    final variance = periods.fold(0.0, (s, p) {
      final diff = p.totalSpent - avg;
      return s + (diff * diff);
    }) / periods.length;
    final stdDev = _sqrt(variance);
    final coefficientOfVariation = avg > 0 ? (stdDev / avg) : 0.0;
    final consistencyScore = (100 - (coefficientOfVariation * 100)).clamp(0.0, 100.0);

    final overallScore = (improvementScore + consistencyScore) / 2;

    // Determina nota
    String grade;
    if (overallScore >= 90) {
      grade = 'A+';
    } else if (overallScore >= 85) {
      grade = 'A';
    } else if (overallScore >= 80) {
      grade = 'B+';
    } else if (overallScore >= 70) {
      grade = 'B';
    } else if (overallScore >= 60) {
      grade = 'C';
    } else if (overallScore >= 50) {
      grade = 'D';
    } else {
      grade = 'F';
    }

    return ComparisonScore(
      overallScore: overallScore,
      improvementScore: improvementScore,
      consistencyScore: consistencyScore,
      grade: grade,
    );
  }

  /// Calcula tendência geral
  ComparisonTrend _calculateTrend(List<PeriodData> periods) {
    if (periods.length < 2) return ComparisonTrend.stable;

    final values = periods.map((p) => p.totalSpent).toList();
    
    // Calcula coeficiente de variação
    final avg = values.fold(0.0, (s, v) => s + v) / values.length;
    final variance = values.fold(0.0, (s, v) {
      final diff = v - avg;
      return s + (diff * diff);
    }) / values.length;
    final stdDev = _sqrt(variance);
    final coefficientOfVariation = avg > 0 ? (stdDev / avg) : 0.0;

    // Se variação muito alta, é volátil
    if (coefficientOfVariation > 0.3) return ComparisonTrend.volatile;

    // Analisa tendência (regressão linear simples)
    final n = values.length;
    final x = List.generate(n, (i) => i.toDouble());
    final xMean = x.fold(0.0, (s, v) => s + v) / n;
    final yMean = values.fold(0.0, (s, v) => s + v) / n;

    var numerator = 0.0;
    var denominator = 0.0;
    for (var i = 0; i < n; i++) {
      numerator += (x[i] - xMean) * (values[i] - yMean);
      denominator += (x[i] - xMean) * (x[i] - xMean);
    }

    final slope = denominator != 0 ? numerator / denominator : 0.0;

    // Determina tendência baseado na inclinação
    if (slope > avg * 0.05) return ComparisonTrend.increasing;
    if (slope < -avg * 0.05) return ComparisonTrend.decreasing;
    return ComparisonTrend.stable;
  }

  /// Função auxiliar para raiz quadrada
  double _sqrt(double value) {
    if (value <= 0) return 0.0;
    var x = value;
    var last = 0.0;
    while ((x - last).abs() > 0.0001) {
      last = x;
      x = (x + value / x) / 2;
    }
    return x;
  }
}
