import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:get/get.dart';
import '../../../../core/services/financial_context_service.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../onboarding/data/services/onboarding_service.dart';
import '../../../onboarding/data/models/onboarding_question_model.dart';
import '../../domain/entities/multi_period_comparison.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/financial_goal.dart';
import '../../domain/entities/financial_profile.dart';
import '../../domain/entities/financial_insight.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/budget_comparison_data.dart';
import '../../domain/entities/enhanced_score.dart';
import '../../domain/entities/gamification_impact.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/repositories/financial_goals_repository.dart';
import '../services/financial_profile_service.dart';
import '../services/enhanced_insights_generator.dart';

/// Serviço inteligente de comparações multi-período
/// 
/// Integra com todos os sistemas do app para gerar comparações
/// contextualizadas e acionáveis:
/// - FinancialContextService (contexto completo)
/// - FinancialProfileService (orçamentos)
/// - FinancialGoalsRepository (metas)
/// - EnhancedInsightsGenerator (insights inteligentes)
/// - OnboardingService (perfil do usuário)
class SmartComparisonService extends GetxService {
  late final ExpenseRepository _expenseRepository;
  late final FinancialGoalsRepository _goalsRepository;
  late final FinancialProfileService _profileService;
  late final FinancialContextService _contextService;
  late final EnhancedInsightsGenerator _insightsGenerator;
  late final OnboardingService _onboardingService;

  // Cache
  MultiPeriodComparison? _cachedComparison;
  DateTime? _lastCacheTime;
  ComparisonPeriodType? _cachedPeriodType;
  static const Duration _cacheExpiration = Duration(minutes: 5);

  @override
  void onInit() {
    super.onInit();
    _initializeDependencies();
  }

  void _initializeDependencies() {
    // #region agent log
    _debugLog('H1', 'smart_comparison_service.dart:50', 'Starting _initializeDependencies');
    // #endregion
    try {
      _expenseRepository = Get.find<ExpenseRepository>();
      // #region agent log
      _debugLog('H1', 'smart_comparison_service.dart:52', 'Found ExpenseRepository');
      // #endregion
    } catch (e) {
      // #region agent log
      _debugLog('H1', 'smart_comparison_service.dart:55', 'FAILED ExpenseRepository', {'error': e.toString()});
      // #endregion
      rethrow;
    }
    try {
      _goalsRepository = Get.find<FinancialGoalsRepository>();
      // #region agent log
      _debugLog('H1', 'smart_comparison_service.dart:61', 'Found FinancialGoalsRepository');
      // #endregion
    } catch (e) {
      // #region agent log
      _debugLog('H1', 'smart_comparison_service.dart:64', 'FAILED FinancialGoalsRepository', {'error': e.toString()});
      // #endregion
      rethrow;
    }
    try {
      _profileService = Get.find<FinancialProfileService>();
      // #region agent log
      _debugLog('H1', 'smart_comparison_service.dart:70', 'Found FinancialProfileService');
      // #endregion
    } catch (e) {
      // #region agent log
      _debugLog('H1', 'smart_comparison_service.dart:73', 'FAILED FinancialProfileService', {'error': e.toString()});
      // #endregion
      rethrow;
    }
    try {
      _contextService = Get.find<FinancialContextService>();
      // #region agent log
      _debugLog('H1', 'smart_comparison_service.dart:79', 'Found FinancialContextService');
      // #endregion
    } catch (e) {
      // #region agent log
      _debugLog('H1', 'smart_comparison_service.dart:82', 'FAILED FinancialContextService', {'error': e.toString()});
      // #endregion
      rethrow;
    }
    try {
      _insightsGenerator = Get.find<EnhancedInsightsGenerator>();
      // #region agent log
      _debugLog('H1', 'smart_comparison_service.dart:88', 'Found EnhancedInsightsGenerator');
      // #endregion
    } catch (e) {
      // #region agent log
      _debugLog('H1', 'smart_comparison_service.dart:91', 'FAILED EnhancedInsightsGenerator', {'error': e.toString()});
      // #endregion
      rethrow;
    }
    try {
      _onboardingService = Get.find<OnboardingService>();
      // #region agent log
      _debugLog('H1', 'smart_comparison_service.dart:97', 'Found OnboardingService');
      // #endregion
    } catch (e) {
      // #region agent log
      _debugLog('H1', 'smart_comparison_service.dart:100', 'FAILED OnboardingService', {'error': e.toString()});
      // #endregion
      rethrow;
    }
    // #region agent log
    _debugLog('H1', 'smart_comparison_service.dart:104', 'All dependencies initialized successfully');
    // #endregion
  }
  
  // #region agent log
  void _debugLog(String hypothesisId, String location, String message, [Map<String, dynamic>? data]) {
    try {
      final logFile = File('/Users/marcelacunha/meus_apps/assistente_financeiro/.cursor/debug.log');
      final payload = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sessionId': 'debug-session',
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        if (data != null) 'data': data,
      };
      logFile.writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
    } catch (_) {}
  }
  // #endregion

  /// Gera uma comparação completa e integrada entre múltiplos períodos
  Future<MultiPeriodComparison> generateEnhancedComparison({
    required String userId,
    required ComparisonPeriodType periodType,
    bool forceRefresh = false,
  }) async {
    final opId = AppLogger.startOp(FeatureTag.expenses, 'generate_enhanced_comparison');

    try {
      // Verificar cache
      if (!forceRefresh && _isValidCache(periodType)) {
        AppLogger.debug(FeatureTag.expenses, 'Usando comparação em cache');
        return _cachedComparison!;
      }

      AppLogger.debug(FeatureTag.expenses, 'Gerando nova comparação', data: {
        'periodType': periodType.displayName,
      });

      // 1-2. Obter contexto, perfil e onboarding EM PARALELO (com timeout)
      final contextFuture = _contextService.getContext(forceRefresh: forceRefresh).catchError((e) {
        AppLogger.warning(FeatureTag.expenses, 'Erro ao obter contexto', data: {'error': e.toString()});
        return FinancialContext(); // Retorna contexto vazio em caso de erro
      });
      final profileFuture = _profileService.getFinancialProfile()
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      final onboardingFuture = _onboardingService.getOnboardingProfile()
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      
      final results = await Future.wait([contextFuture, profileFuture, onboardingFuture]);
      final context = results[0] as FinancialContext;
      final financialProfile = results[1] as FinancialProfile?;
      final onboardingProfile = results[2] as OnboardingProfileModel?;
      
      // 3. Gerar lista de períodos
      final periods = _generatePeriods(periodType);
      
      // 4. Processar dados de cada período EM PARALELO
      final periodDataList = <PeriodData>[];
      final allGoals = <FinancialGoal>[];
      final allExpenses = <Expense>[];
      
      // Buscar todos os dados em paralelo
      final periodFutures = periods.map((period) async {
        final expensesFuture = _expenseRepository.getExpensesByDateRange(
          period['start']!,
          period['end']!,
        ).timeout(const Duration(seconds: 2), onTimeout: () => <Expense>[]);
        
        final goalsFuture = _goalsRepository.getGoalsByMonth(period['start']!)
            .timeout(const Duration(seconds: 2), onTimeout: () => <FinancialGoal>[]);
        
        final periodResults = await Future.wait([expensesFuture, goalsFuture]);
        return {
          'expenses': periodResults[0] as List<Expense>,
          'goals': periodResults[1] as List<FinancialGoal>,
          'start': period['start']!,
          'end': period['end']!,
        };
      }).toList();
      
      final allPeriodData = await Future.wait(periodFutures);
      
      for (final periodResult in allPeriodData) {
        final expenses = periodResult['expenses'] as List<Expense>;
        final monthGoals = periodResult['goals'] as List<FinancialGoal>;
        final startDate = periodResult['start'] as DateTime;
        final endDate = periodResult['end'] as DateTime;
        
        allExpenses.addAll(expenses);
        allGoals.addAll(monthGoals);
        
        final periodData = await _calculateEnhancedPeriodData(
          expenses: expenses,
          goals: monthGoals,
          profile: financialProfile,
          startDate: startDate,
          endDate: endDate,
        );
        
        periodDataList.add(periodData);
      }
      
      // 5. Calcular tendência
      final trend = _calculateTrend(periodDataList);
      
      // 6. Gerar insights base (compatibilidade)
      final baseInsights = _generateBaseInsights(periodDataList, periodType);
      
      // 7. Calcular score base
      final baseScore = _calculateBaseScore(periodDataList);
      
      // 8. Gerar dados de comparação de orçamento
      final budgetComparison = _calculateBudgetComparison(
        periodDataList,
        allGoals,
        financialProfile,
      );
      
      // 9. Calcular score expandido
      final enhancedScore = _calculateEnhancedScore(
        baseScore: baseScore,
        budgetComparison: budgetComparison,
        goals: allGoals,
      );
      
      // 10. Gerar insights contextuais usando EnhancedInsightsGenerator
      final categories = await _expenseRepository.getAllCategories();
      final contextualInsights = _generateContextualInsights(
        goals: context.goals.isNotEmpty ? context.goals : allGoals,
        expenses: allExpenses,
        categories: categories,
        periodDataList: periodDataList,
      );
      
      // 11. Calcular impacto na gamificação
      final gamificationImpact = _calculateGamificationImpact(
        enhancedScore: enhancedScore,
        periodType: periodType,
        budgetComparison: budgetComparison,
      );
      
      // 12. Criar comparação completa
      final comparison = MultiPeriodComparison(
        id: '${DateTime.now().millisecondsSinceEpoch}_$userId',
        userId: userId,
        createdAt: DateTime.now(),
        periodType: periodType,
        periods: periodDataList,
        insights: baseInsights,
        trend: trend,
        budgetComparison: budgetComparison,
        contextualInsights: contextualInsights,
        gamificationImpact: gamificationImpact,
        onboardingContext: onboardingProfile,
        enhancedScore: enhancedScore,
      );
      
      // Atualizar cache
      _cachedComparison = comparison;
      _lastCacheTime = DateTime.now();
      _cachedPeriodType = periodType;
      
      AppLogger.completeOp(opId, message: 'Comparação gerada com sucesso', data: {
        'periods': periodDataList.length,
        'insights': contextualInsights.length,
        'score': enhancedScore.overallScore,
        'grade': enhancedScore.grade,
      });
      
      return comparison;
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao gerar comparação', exception: e);
      rethrow;
    }
  }

  /// Verifica se o cache é válido
  bool _isValidCache(ComparisonPeriodType periodType) {
    if (_cachedComparison == null || _lastCacheTime == null) return false;
    if (_cachedPeriodType != periodType) return false;
    
    final elapsed = DateTime.now().difference(_lastCacheTime!);
    return elapsed < _cacheExpiration;
  }

  /// Invalida o cache
  void invalidateCache() {
    _cachedComparison = null;
    _lastCacheTime = null;
    _cachedPeriodType = null;
    AppLogger.debug(FeatureTag.expenses, 'Cache de comparação invalidado');
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

  /// Calcula dados expandidos de um período
  Future<PeriodData> _calculateEnhancedPeriodData({
    required List<Expense> expenses,
    required List<FinancialGoal> goals,
    required FinancialProfile? profile,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
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

    // Calcular orçamento e aderência
    double? budgetLimit;
    double? budgetAdherence;
    
    if (profile != null && profile.totalBudget > 0) {
      budgetLimit = profile.totalBudget;
      budgetAdherence = (totalSpent / budgetLimit) * 100;
    }

    // Calcular detalhes por categoria
    final categoryDetails = <String, CategoryPeriodData>{};
    final categories = await _expenseRepository.getAllCategories();
    
    for (final entry in categoryBreakdown.entries) {
      final categoryId = entry.key;
      final spent = entry.value;
      
      // Encontrar meta da categoria
      final goal = goals.firstWhereOrNull((g) => g.categoryId == categoryId);
      final category = _findCategoryById(categoryId, categories);
      
      double? limit;
      double? adherence;
      bool? isExceeded;
      
      if (goal != null) {
        limit = goal.monthlyLimit;
        adherence = (spent / limit) * 100;
        isExceeded = spent > limit;
      }
      
      categoryDetails[categoryId] = CategoryPeriodData(
        categoryId: categoryId,
        categoryName: category?.name ?? _getCategoryNameFromId(categoryId),
        spent: spent,
        limit: limit,
        adherence: adherence,
        isExceeded: isExceeded,
      );
    }

    return PeriodData(
      startDate: startDate,
      endDate: endDate,
      totalSpent: totalSpent,
      transactionCount: transactionCount,
      categoryBreakdown: categoryBreakdown,
      averagePerDay: averagePerDay,
      topCategory: topCategory,
      topCategoryAmount: topCategoryAmount,
      budgetLimit: budgetLimit,
      budgetAdherence: budgetAdherence,
      categoryDetails: categoryDetails,
    );
  }

  /// Calcula comparação com orçamento
  BudgetComparisonData? _calculateBudgetComparison(
    List<PeriodData> periods,
    List<FinancialGoal> goals,
    FinancialProfile? profile,
  ) {
    if (profile == null || profile.totalBudget <= 0) return null;
    if (periods.isEmpty) return null;

    // Usar período mais recente como referência
    final latestPeriod = periods.last;
    final totalSpent = latestPeriod.totalSpent;
    final totalBudget = profile.totalBudget;
    final budgetAdherence = (totalSpent / totalBudget) * 100;

    // Contar metas
    final activeGoals = goals.where((g) => g.isActive).toList();
    final exceededGoals = activeGoals.where((g) => g.isExceeded).length;
    final onTrackGoals = activeGoals.where((g) => 
      g.status == FinancialGoalStatus.good || 
      g.status == FinancialGoalStatus.onTrack
    ).length;

    // Calcular comparação por categoria
    final categoryComparisons = <String, CategoryBudgetComparison>{};
    
    for (final goal in activeGoals) {
      final spent = latestPeriod.categoryBreakdown[goal.categoryId] ?? 0.0;
      
      categoryComparisons[goal.categoryId] = CategoryBudgetComparison(
        categoryId: goal.categoryId,
        categoryName: goal.categoryName,
        budgetLimit: goal.monthlyLimit,
        spent: spent,
        adherence: goal.monthlyLimit > 0 ? (spent / goal.monthlyLimit) * 100 : 0,
        isExceeded: spent > goal.monthlyLimit,
      );
    }

    return BudgetComparisonData(
      totalBudget: totalBudget,
      totalSpent: totalSpent,
      budgetAdherence: budgetAdherence,
      goalsCount: activeGoals.length,
      goalsExceeded: exceededGoals,
      goalsOnTrack: onTrackGoals,
      categoryComparisons: categoryComparisons,
    );
  }

  /// Calcula score base (compatibilidade com sistema antigo)
  ComparisonScore _calculateBaseScore(List<PeriodData> periods) {
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

  /// Calcula score expandido com aderência ao orçamento
  EnhancedScore _calculateEnhancedScore({
    required ComparisonScore baseScore,
    required BudgetComparisonData? budgetComparison,
    required List<FinancialGoal> goals,
  }) {
    // Score de aderência ao orçamento (0-100)
    double budgetAdherenceScore = 50.0;
    if (budgetComparison != null) {
      // Quanto menor a aderência (menos gastou vs orçamento), melhor
      // Se gastou 80% do orçamento, score = 100 - 80 + 30 = 50
      // Se gastou 50% do orçamento, score = 100 - 50 + 30 = 80
      // Se gastou 120% do orçamento, score = 100 - 120 + 30 = 10
      budgetAdherenceScore = (130 - budgetComparison.budgetAdherence).clamp(0, 100);
    }

    // Score de performance vs metas (0-100)
    double goalPerformanceScore = 50.0;
    if (goals.isNotEmpty) {
      final activeGoals = goals.where((g) => g.isActive).toList();
      if (activeGoals.isNotEmpty) {
        final onTrackCount = activeGoals.where((g) => 
          g.status == FinancialGoalStatus.good || 
          g.status == FinancialGoalStatus.onTrack
        ).length;
        goalPerformanceScore = (onTrackCount / activeGoals.length) * 100;
      }
    }

    // Score geral combinado (ponderado)
    // baseScore: 30%, budgetAdherence: 40%, goalPerformance: 30%
    final overallScore = (
      baseScore.overallScore * 0.3 +
      budgetAdherenceScore * 0.4 +
      goalPerformanceScore * 0.3
    );

    // Determina nota final
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

    return EnhancedScore(
      baseScore: baseScore,
      budgetAdherenceScore: budgetAdherenceScore,
      goalPerformanceScore: goalPerformanceScore,
      overallScore: overallScore,
      grade: grade,
    );
  }

  /// Gera insights contextuais usando EnhancedInsightsGenerator
  List<FinancialInsight> _generateContextualInsights({
    required List<FinancialGoal> goals,
    required List<Expense> expenses,
    required List<ExpenseCategory> categories,
    required List<PeriodData> periodDataList,
  }) {
    // Usar EnhancedInsightsGenerator para gerar insights baseados em metas
    final smartInsights = _insightsGenerator.generateSmartInsights(
      goals: goals,
      expenses: expenses,
      categories: categories,
    );

    // Adicionar insights específicos de comparação multi-período
    final comparisonInsights = _generateComparisonSpecificInsights(
      periodDataList,
      categories,
    );

    // Combinar e ordenar por prioridade
    final allInsights = [...smartInsights, ...comparisonInsights];
    allInsights.sort((a, b) => _getPriorityWeight(b.priority).compareTo(_getPriorityWeight(a.priority)));

    return allInsights.take(10).toList();
  }

  /// Gera insights específicos de comparação multi-período
  List<FinancialInsight> _generateComparisonSpecificInsights(
    List<PeriodData> periods,
    List<ExpenseCategory> categories,
  ) {
    final insights = <FinancialInsight>[];
    final now = DateTime.now();

    if (periods.length < 2) return insights;

    // Insight: Categoria que sempre excede
    final categoryExceedCount = <String, int>{};
    for (final period in periods) {
      for (final entry in period.categoryDetails.entries) {
        if (entry.value.isExceeded == true) {
          categoryExceedCount[entry.key] = (categoryExceedCount[entry.key] ?? 0) + 1;
        }
      }
    }

    for (final entry in categoryExceedCount.entries) {
      if (entry.value >= (periods.length * 0.5).ceil()) {
        final category = _findCategoryById(entry.key, categories);
        final categoryName = category?.name ?? _getCategoryNameFromId(entry.key);
        insights.add(FinancialInsight(
          id: 'pattern_exceed_${entry.key}_${now.millisecondsSinceEpoch}',
          title: '📊 Padrão Identificado: $categoryName',
          description: 'Esta categoria excedeu o orçamento em ${entry.value} dos últimos ${periods.length} meses. Considere ajustar a meta ou reduzir gastos.',
          type: FinancialInsightType.spendingPattern,
          priority: FinancialInsightPriority.high,
          data: {
            'categoryId': entry.key,
            'categoryName': categoryName,
            'exceedCount': entry.value,
            'totalPeriods': periods.length,
            'route': AppRoutes.financialGoals,
          },
          actionSuggestions: [
            'Revisar e ajustar a meta desta categoria',
            'Analisar os gastos detalhados',
            'Considerar alternativas mais econômicas',
          ],
          createdAt: now,
          isRead: false,
        ));
      }
    }

    // Insight: Tendência de melhoria contínua
    if (periods.length >= 3) {
      bool isImproving = true;
      for (int i = 1; i < periods.length; i++) {
        if (periods[i].totalSpent >= periods[i - 1].totalSpent) {
          isImproving = false;
          break;
        }
      }

      if (isImproving) {
        final reduction = periods.first.totalSpent - periods.last.totalSpent;
        insights.add(FinancialInsight(
          id: 'trend_improving_${now.millisecondsSinceEpoch}',
          title: '🎉 Excelente Progresso!',
          description: 'Você reduziu seus gastos consistentemente nos últimos ${periods.length} meses, economizando R\$ ${reduction.toStringAsFixed(2)} no total!',
          type: FinancialInsightType.positiveProgress,
          priority: FinancialInsightPriority.medium,
          data: {
            'reductionAmount': reduction,
            'periodsCount': periods.length,
          },
          actionSuggestions: [
            'Continue assim!',
            'Considere investir a economia',
            'Defina uma nova meta de economia',
          ],
          createdAt: now,
          isRead: false,
        ));
      }
    }

    // Insight: Variação muito alta
    if (periods.length >= 3) {
      final values = periods.map((p) => p.totalSpent).toList();
      final avg = values.fold(0.0, (s, v) => s + v) / values.length;
      final variance = values.fold(0.0, (s, v) {
        final diff = v - avg;
        return s + (diff * diff);
      }) / values.length;
      final stdDev = _sqrt(variance);
      final cv = avg > 0 ? (stdDev / avg) : 0.0;

      if (cv > 0.3) {
        insights.add(FinancialInsight(
          id: 'trend_volatile_${now.millisecondsSinceEpoch}',
          title: '📈 Gastos Variáveis',
          description: 'Seus gastos variam muito entre os meses (${(cv * 100).toStringAsFixed(0)}% de variação). Tente manter um padrão mais consistente.',
          type: FinancialInsightType.spendingPattern,
          priority: FinancialInsightPriority.medium,
          data: {
            'coefficientOfVariation': cv,
            'average': avg,
          },
          actionSuggestions: [
            'Crie um orçamento fixo mensal',
            'Planeje gastos variáveis antecipadamente',
            'Use a média como referência: R\$ ${avg.toStringAsFixed(2)}',
          ],
          createdAt: now,
          isRead: false,
        ));
      }
    }

    return insights;
  }

  /// Calcula impacto na gamificação
  GamificationImpact _calculateGamificationImpact({
    required EnhancedScore enhancedScore,
    required ComparisonPeriodType periodType,
    required BudgetComparisonData? budgetComparison,
  }) {
    int pointsEarned = 0;
    final badgesUnlocked = <String>[];
    final badgesProgress = <String>[];
    final badgeProgressData = <String, double>{};

    // Pontos baseados no score
    if (enhancedScore.overallScore >= 90) {
      pointsEarned += 100;
    } else if (enhancedScore.overallScore >= 80) {
      pointsEarned += 75;
    } else if (enhancedScore.overallScore >= 70) {
      pointsEarned += 50;
    } else if (enhancedScore.overallScore >= 60) {
      pointsEarned += 25;
    } else {
      pointsEarned += 10;
    }

    // Pontos extras por período mais longo
    if (periodType == ComparisonPeriodType.sixMonths) {
      pointsEarned += 25;
    } else if (periodType == ComparisonPeriodType.twelveMonths) {
      pointsEarned += 50;
    }

    // Badges baseados em performance
    if (budgetComparison != null) {
      // Badge "Orçamento Master" - 100% aderência por 3+ meses
      if (budgetComparison.budgetAdherence <= 100) {
        badgeProgressData['budget_master'] = 0.33; // 1 de 3 meses
        badgesProgress.add('budget_master');
      }

      // Badge "Meta Cumprida" - todas as metas no caminho certo
      if (budgetComparison.goalsExceeded == 0 && budgetComparison.goalsCount > 0) {
        badgesUnlocked.add('all_goals_met');
        pointsEarned += 50;
      }
    }

    // Badge baseado na nota
    if (enhancedScore.grade == 'A+' || enhancedScore.grade == 'A') {
      badgesUnlocked.add('financial_excellence');
      pointsEarned += 30;
    }

    // Determinar próximo badge
    String? nextBadgeId;
    double? nextBadgeProgress;
    if (badgesProgress.isNotEmpty) {
      nextBadgeId = badgesProgress.first;
      nextBadgeProgress = badgeProgressData[nextBadgeId];
    }

    return GamificationImpact(
      pointsEarned: pointsEarned,
      badgesUnlocked: badgesUnlocked,
      badgesProgress: badgesProgress,
      badgeProgressData: badgeProgressData,
      nextBadgeId: nextBadgeId,
      nextBadgeProgress: nextBadgeProgress,
    );
  }

  /// Gera insights base (compatibilidade)
  ComparisonInsights _generateBaseInsights(
    List<PeriodData> periods,
    ComparisonPeriodType periodType,
  ) {
    if (periods.isEmpty) {
      return ComparisonInsights(
        summary: 'Sem dados suficientes para análise',
        highlights: [],
        recommendations: [],
        score: const ComparisonScore(
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
          description: 'Seus gastos têm aumentado significativamente. Considere revisar seu orçamento.',
          type: RecommendationType.trendWarning,
          priority: RecommendationPriority.high,
          actionText: 'Revisar Orçamento',
          actionData: {'route': AppRoutes.financialGoals},
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
        actionData: {
          'categoryId': topEntry.key,
          'route': AppRoutes.financialGoals,
        },
      ));
    }

    // Calcula score
    final score = _calculateBaseScore(periods);

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

  /// Peso de prioridade para ordenação
  int _getPriorityWeight(FinancialInsightPriority priority) {
    switch (priority) {
      case FinancialInsightPriority.urgent:
        return 4;
      case FinancialInsightPriority.high:
        return 3;
      case FinancialInsightPriority.medium:
        return 2;
      case FinancialInsightPriority.low:
        return 1;
    }
  }
  
  /// Busca categoria por ID com fallback para IDs sem sufixo do usuário
  ExpenseCategory? _findCategoryById(String categoryId, List<ExpenseCategory> categories) {
    if (categoryId.isEmpty || categories.isEmpty) return null;
    
    // 1. Tentar match exato
    final exactMatch = categories.firstWhereOrNull((cat) => cat.id == categoryId);
    if (exactMatch != null) return exactMatch;
    
    // 2. Tentar match onde o ID da categoria começa com o categoryId buscado
    final startsWithMatch = categories.firstWhereOrNull(
      (cat) => cat.id.startsWith('${categoryId}_')
    );
    if (startsWithMatch != null) return startsWithMatch;
    
    // 3. Tentar match onde o categoryId começa com o ID base da categoria
    final reverseMatch = categories.firstWhereOrNull(
      (cat) => categoryId.startsWith('${cat.id}_')
    );
    if (reverseMatch != null) return reverseMatch;
    
    // 4. Extrair ID base e tentar match
    final baseId = _extractBaseCategoryId(categoryId);
    if (baseId != categoryId) {
      return categories.firstWhereOrNull(
        (cat) => cat.id == baseId || 
                 cat.id.startsWith('${baseId}_') ||
                 _extractBaseCategoryId(cat.id) == baseId
      );
    }
    
    return null;
  }
  
  /// Extrai o ID base de uma categoria removendo o sufixo do usuário
  String _extractBaseCategoryId(String categoryId) {
    final defaultIds = [
      'alimentacao', 'transporte', 'saude', 'contas', 'lazer',
      'casa', 'educacao', 'roupas', 'tecnologia', 'pets', 'outros', 'investimentos'
    ];
    
    for (final baseId in defaultIds) {
      if (categoryId == baseId || categoryId.startsWith('${baseId}_')) {
        return baseId;
      }
    }
    return categoryId;
  }
  
  /// Obtém o nome da categoria a partir do ID base
  String _getCategoryNameFromId(String categoryId) {
    final baseId = _extractBaseCategoryId(categoryId);
    
    final categoryNames = {
      'alimentacao': 'Alimentação',
      'transporte': 'Transporte',
      'saude': 'Saúde',
      'contas': 'Contas',
      'lazer': 'Lazer',
      'casa': 'Casa',
      'educacao': 'Educação',
      'roupas': 'Roupas e Beleza',
      'tecnologia': 'Tecnologia',
      'pets': 'Pets',
      'outros': 'Outros',
      'investimentos': 'Investimentos',
    };
    
    return categoryNames[baseId] ?? 'Categoria';
  }
}

