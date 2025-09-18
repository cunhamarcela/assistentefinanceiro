import 'package:get/get.dart';
import '../../domain/entities/financial_insight.dart';
import '../../domain/entities/financial_goal.dart';
import '../../domain/entities/financial_profile.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart';
import '../../../auth/data/services/auth_service.dart';

/// Serviço para gerar insights financeiros personalizados
class FinancialInsightsService extends GetxService {
  static FinancialInsightsService get instance => Get.find<FinancialInsightsService>();

  late final AuthService _authService;

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
  }

  /// Gerar insights baseados no perfil financeiro e gastos reais
  List<FinancialInsight> generateInsights({
    required FinancialProfile profile,
    required List<FinancialGoal> goals,
    required List<Expense> currentMonthExpenses,
    required List<Expense> previousMonthExpenses,
    required List<ExpenseCategory> categories,
  }) {
    final insights = <FinancialInsight>[];
    final now = DateTime.now();

    // 1. Análise de orçamento excedido
    insights.addAll(_generateBudgetExceededInsights(goals, now));

    // 2. Alertas de orçamento próximo do limite
    insights.addAll(_generateBudgetWarningInsights(goals, now));

    // 3. Oportunidades de economia
    insights.addAll(_generateSavingsOpportunityInsights(
      profile, currentMonthExpenses, categories, now,
    ));

    // 4. Progresso de metas
    insights.addAll(_generateGoalProgressInsights(goals, now));

    // 5. Análise de padrões de gastos
    insights.addAll(_generateSpendingPatternInsights(
      currentMonthExpenses, previousMonthExpenses, categories, now,
    ));

    // 6. Comparação mensal
    insights.addAll(_generateMonthlyComparisonInsights(
      currentMonthExpenses, previousMonthExpenses, now,
    ));

    // Ordenar por prioridade e data
    insights.sort((a, b) {
      final priorityComparison = _getPriorityOrder(b.priority).compareTo(_getPriorityOrder(a.priority));
      if (priorityComparison != 0) return priorityComparison;
      return b.createdAt.compareTo(a.createdAt);
    });

    return insights.take(10).toList(); // Limitar a 10 insights
  }

  /// Gerar insights de orçamento excedido
  List<FinancialInsight> _generateBudgetExceededInsights(
    List<FinancialGoal> goals,
    DateTime now,
  ) {
    final insights = <FinancialInsight>[];

    for (final goal in goals.where((g) => g.isExceeded && g.isActive)) {
      final exceededAmount = goal.currentSpent - goal.monthlyLimit;
      final exceededPercentage = ((goal.currentSpent / goal.monthlyLimit - 1) * 100).round();

      insights.add(FinancialInsight(
        id: 'budget_exceeded_${goal.id}',
        title: 'Orçamento Excedido: ${goal.categoryName}',
        description: 'Você gastou R\$ ${exceededAmount.toStringAsFixed(2)} a mais que o planejado em ${goal.categoryName} ($exceededPercentage% acima do limite).',
        type: FinancialInsightType.budgetExceeded,
        priority: FinancialInsightPriority.high,
        data: {
          'categoryId': goal.categoryId,
          'categoryName': goal.categoryName,
          'budgetLimit': goal.monthlyLimit,
          'currentSpent': goal.currentSpent,
          'exceededAmount': exceededAmount,
          'exceededPercentage': exceededPercentage,
        },
        actionSuggestions: [
          'Revise seus gastos em ${goal.categoryName}',
          'Considere aumentar o orçamento desta categoria',
          'Procure alternativas mais econômicas',
          'Estabeleça um limite diário para esta categoria',
        ],
        createdAt: now,
        isRead: false,
      ));
    }

    return insights;
  }

  /// Gerar insights de alerta de orçamento
  List<FinancialInsight> _generateBudgetWarningInsights(
    List<FinancialGoal> goals,
    DateTime now,
  ) {
    final insights = <FinancialInsight>[];

    for (final goal in goals.where((g) => g.status == FinancialGoalStatus.warning && g.isActive)) {
      final remainingAmount = goal.remainingAmount;
      final usedPercentage = (goal.progressPercentage * 100).round();
      final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day;

      insights.add(FinancialInsight(
        id: 'budget_warning_${goal.id}',
        title: 'Atenção: ${goal.categoryName}',
        description: 'Você já gastou $usedPercentage% do orçamento de ${goal.categoryName}. Restam R\$ ${remainingAmount.toStringAsFixed(2)} para os próximos $daysLeft dias.',
        type: FinancialInsightType.budgetWarning,
        priority: FinancialInsightPriority.medium,
        data: {
          'categoryId': goal.categoryId,
          'categoryName': goal.categoryName,
          'budgetLimit': goal.monthlyLimit,
          'currentSpent': goal.currentSpent,
          'remainingAmount': remainingAmount,
          'usedPercentage': usedPercentage,
          'daysLeft': daysLeft,
        },
        actionSuggestions: [
          'Monitore seus gastos em ${goal.categoryName}',
          'Considere reduzir gastos nesta categoria',
          'Planeje os gastos restantes do mês',
        ],
        createdAt: now,
        isRead: false,
      ));
    }

    return insights;
  }

  /// Gerar insights de oportunidades de economia
  List<FinancialInsight> _generateSavingsOpportunityInsights(
    FinancialProfile profile,
    List<Expense> expenses,
    List<ExpenseCategory> categories,
    DateTime now,
  ) {
    final insights = <FinancialInsight>[];

    // Agrupar gastos por categoria
    final categorySpending = <String, double>{};
    for (final expense in expenses) {
      categorySpending[expense.categoryId] = 
          (categorySpending[expense.categoryId] ?? 0) + expense.amount;
    }

    // Encontrar categorias com gastos muito abaixo do orçamento
    for (final entry in profile.categoryBudgets.entries) {
      final categoryId = entry.key;
      final budgetAmount = entry.value;
      final spentAmount = categorySpending[categoryId] ?? 0;
      
      if (budgetAmount > 0 && spentAmount < budgetAmount * 0.5) {
        final savingsAmount = budgetAmount - spentAmount;
        final category = categories.firstWhereOrNull((c) => c.id == categoryId);
        final categoryName = category?.name ?? 'Categoria';

        insights.add(FinancialInsight(
          id: 'savings_opportunity_${categoryId}',
          title: 'Oportunidade de Economia: $categoryName',
          description: 'Você pode economizar até R\$ ${savingsAmount.toStringAsFixed(2)} em $categoryName. Considere realocar este valor para outras metas.',
          type: FinancialInsightType.savingsOpportunity,
          priority: FinancialInsightPriority.low,
          data: {
            'categoryId': categoryId,
            'categoryName': categoryName,
            'budgetAmount': budgetAmount,
            'spentAmount': spentAmount,
            'savingsAmount': savingsAmount,
          },
          actionSuggestions: [
            'Realoque parte do orçamento para outras categorias',
            'Use a economia para criar uma reserva de emergência',
            'Invista o valor economizado',
          ],
          createdAt: now,
          isRead: false,
        ));
      }
    }

    return insights;
  }

  /// Gerar insights de progresso de metas
  List<FinancialInsight> _generateGoalProgressInsights(
    List<FinancialGoal> goals,
    DateTime now,
  ) {
    final insights = <FinancialInsight>[];

    for (final goal in goals.where((g) => g.status == FinancialGoalStatus.good && g.isActive)) {
      final usedPercentage = (goal.progressPercentage * 100).round();
      final remainingAmount = goal.remainingAmount;

      insights.add(FinancialInsight(
        id: 'goal_progress_${goal.id}',
        title: 'Meta no Caminho Certo: ${goal.categoryName}',
        description: 'Parabéns! Você está gastando apenas $usedPercentage% do orçamento de ${goal.categoryName}. Ainda restam R\$ ${remainingAmount.toStringAsFixed(2)}.',
        type: FinancialInsightType.goalProgress,
        priority: FinancialInsightPriority.low,
        data: {
          'categoryId': goal.categoryId,
          'categoryName': goal.categoryName,
          'budgetLimit': goal.monthlyLimit,
          'currentSpent': goal.currentSpent,
          'remainingAmount': remainingAmount,
          'usedPercentage': usedPercentage,
        },
        actionSuggestions: [
          'Continue mantendo o controle dos gastos',
          'Use a economia para outras prioridades',
          'Considere aumentar investimentos',
        ],
        createdAt: now,
        isRead: false,
      ));
    }

    return insights;
  }

  /// Gerar insights de padrões de gastos
  List<FinancialInsight> _generateSpendingPatternInsights(
    List<Expense> currentExpenses,
    List<Expense> previousExpenses,
    List<ExpenseCategory> categories,
    DateTime now,
  ) {
    final insights = <FinancialInsight>[];

    // Comparar gastos por categoria entre meses
    final currentCategorySpending = _groupExpensesByCategory(currentExpenses);
    final previousCategorySpending = _groupExpensesByCategory(previousExpenses);

    for (final entry in currentCategorySpending.entries) {
      final categoryId = entry.key;
      final currentAmount = entry.value;
      final previousAmount = previousCategorySpending[categoryId] ?? 0;

      if (previousAmount > 0) {
        final changePercentage = ((currentAmount - previousAmount) / previousAmount * 100).round();
        
        if (changePercentage.abs() >= 30) { // Mudança significativa
          final category = categories.firstWhereOrNull((c) => c.id == categoryId);
          final categoryName = category?.name ?? 'Categoria';
          final isIncrease = changePercentage > 0;

          insights.add(FinancialInsight(
            id: 'spending_pattern_${categoryId}',
            title: '${isIncrease ? 'Aumento' : 'Redução'} em $categoryName',
            description: 'Seus gastos em $categoryName ${isIncrease ? 'aumentaram' : 'diminuíram'} ${changePercentage.abs()}% comparado ao mês anterior (R\$ ${currentAmount.toStringAsFixed(2)} vs R\$ ${previousAmount.toStringAsFixed(2)}).',
            type: FinancialInsightType.spendingPattern,
            priority: isIncrease ? FinancialInsightPriority.medium : FinancialInsightPriority.low,
            data: {
              'categoryId': categoryId,
              'categoryName': categoryName,
              'currentAmount': currentAmount,
              'previousAmount': previousAmount,
              'changePercentage': changePercentage,
              'isIncrease': isIncrease,
            },
            actionSuggestions: isIncrease ? [
              'Analise o que causou o aumento nos gastos',
              'Considere estabelecer um limite mais rígido',
              'Procure alternativas mais econômicas',
            ] : [
              'Parabéns pela redução nos gastos!',
              'Continue mantendo este padrão',
              'Use a economia para outras prioridades',
            ],
            createdAt: now,
            isRead: false,
          ));
        }
      }
    }

    return insights;
  }

  /// Gerar insights de comparação mensal
  List<FinancialInsight> _generateMonthlyComparisonInsights(
    List<Expense> currentExpenses,
    List<Expense> previousExpenses,
    DateTime now,
  ) {
    final insights = <FinancialInsight>[];

    final currentTotal = currentExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
    final previousTotal = previousExpenses.fold(0.0, (sum, expense) => sum + expense.amount);

    if (previousTotal > 0) {
      final changePercentage = ((currentTotal - previousTotal) / previousTotal * 100).round();
      final changeAmount = currentTotal - previousTotal;
      final isIncrease = changePercentage > 0;

      if (changePercentage.abs() >= 10) { // Mudança significativa
        insights.add(FinancialInsight(
          id: 'monthly_comparison_${now.month}_${now.year}',
          title: '${isIncrease ? 'Aumento' : 'Redução'} nos Gastos Mensais',
          description: 'Seus gastos totais ${isIncrease ? 'aumentaram' : 'diminuíram'} ${changePercentage.abs()}% este mês (R\$ ${changeAmount.abs().toStringAsFixed(2)} ${isIncrease ? 'a mais' : 'a menos'}).',
          type: FinancialInsightType.monthlyComparison,
          priority: isIncrease ? FinancialInsightPriority.medium : FinancialInsightPriority.low,
          data: {
            'currentTotal': currentTotal,
            'previousTotal': previousTotal,
            'changeAmount': changeAmount,
            'changePercentage': changePercentage,
            'isIncrease': isIncrease,
          },
          actionSuggestions: isIncrease ? [
            'Revise seus gastos do mês',
            'Identifique as categorias que mais aumentaram',
            'Ajuste seu orçamento se necessário',
          ] : [
            'Excelente controle financeiro!',
            'Continue com este padrão de gastos',
            'Considere investir a economia',
          ],
          createdAt: now,
          isRead: false,
        ));
      }
    }

    return insights;
  }

  /// Agrupar despesas por categoria
  Map<String, double> _groupExpensesByCategory(List<Expense> expenses) {
    final categorySpending = <String, double>{};
    for (final expense in expenses) {
      categorySpending[expense.categoryId] = 
          (categorySpending[expense.categoryId] ?? 0) + expense.amount;
    }
    return categorySpending;
  }

  /// Obter ordem de prioridade para ordenação
  int _getPriorityOrder(FinancialInsightPriority priority) {
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
}
