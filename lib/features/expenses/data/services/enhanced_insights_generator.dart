import 'package:get/get.dart';
import '../../domain/entities/financial_insight.dart';
import '../../domain/entities/financial_goal.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart';

/// Gerador avançado de insights baseado em metas financeiras
class EnhancedInsightsGenerator extends GetxService {
  
  /// Gerar insights inteligentes baseados nas metas e gastos reais
  List<FinancialInsight> generateSmartInsights({
    required List<FinancialGoal> goals,
    required List<Expense> expenses,
    required List<ExpenseCategory> categories,
    DateTime? referenceDate,
  }) {
    final insights = <FinancialInsight>[];
    final now = referenceDate ?? DateTime.now();
    
    // 1. Insights de metas excedidas (prioridade alta)
    insights.addAll(_generateExceededGoalsInsights(goals, now));
    
    // 2. Insights de metas em risco (prioridade média-alta)
    insights.addAll(_generateRiskGoalsInsights(goals, now));
    
    // 3. Insights de performance positiva (prioridade baixa-média)
    insights.addAll(_generatePositivePerformanceInsights(goals, now));
    
    // 4. Insights de otimização de orçamento (prioridade média)
    insights.addAll(_generateBudgetOptimizationInsights(goals, expenses, categories, now));
    
    // 5. Insights de padrões de gastos (prioridade baixa)
    insights.addAll(_generateSpendingPatternInsights(expenses, goals, categories, now));
    
    // 6. Insights preditivos (prioridade média)
    insights.addAll(_generatePredictiveInsights(goals, expenses, now));
    
    // Ordenar por prioridade e relevância
    insights.sort((a, b) {
      final priorityComparison = _getPriorityWeight(b.priority).compareTo(_getPriorityWeight(a.priority));
      if (priorityComparison != 0) return priorityComparison;
      return b.createdAt.compareTo(a.createdAt);
    });
    
    return insights.take(8).toList(); // Limitar a 8 insights mais relevantes
  }
  
  /// Insights para metas excedidas
  List<FinancialInsight> _generateExceededGoalsInsights(List<FinancialGoal> goals, DateTime now) {
    final insights = <FinancialInsight>[];
    
    final exceededGoals = goals.where((g) => g.isExceeded && g.isActive).toList();
    
    for (final goal in exceededGoals) {
      final exceededAmount = goal.currentSpent - goal.monthlyLimit;
      final exceededPercentage = ((goal.currentSpent / goal.monthlyLimit - 1) * 100).round();
      
      insights.add(FinancialInsight(
        id: 'exceeded_${goal.id}_${now.millisecondsSinceEpoch}',
        title: '🚨 Meta Excedida: ${goal.categoryName}',
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
          'Revise seus gastos em ${goal.categoryName} nos próximos dias',
          'Considere aumentar o orçamento desta categoria para o próximo mês',
          'Procure alternativas mais econômicas',
          'Estabeleça um limite diário de R\$ ${(goal.monthlyLimit / 30).toStringAsFixed(2)}',
        ],
        createdAt: now,
        isRead: false,
      ));
    }
    
    return insights;
  }
  
  /// Insights para metas em risco (80-100% do orçamento)
  List<FinancialInsight> _generateRiskGoalsInsights(List<FinancialGoal> goals, DateTime now) {
    final insights = <FinancialInsight>[];
    
    final riskGoals = goals.where((g) => 
      g.status == FinancialGoalStatus.warning && 
      g.isActive && 
      !g.isExceeded
    ).toList();
    
    for (final goal in riskGoals) {
      final remainingAmount = goal.remainingAmount;
      final usedPercentage = (goal.progressPercentage * 100).round();
      final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day;
      final dailyBudgetLeft = remainingAmount / daysLeft;
      
      String riskLevel = usedPercentage >= 90 ? 'CRÍTICO' : 'ALTO';
      String emoji = usedPercentage >= 90 ? '🔴' : '🟡';
      
      insights.add(FinancialInsight(
        id: 'risk_${goal.id}_${now.millisecondsSinceEpoch}',
        title: '$emoji Risco $riskLevel: ${goal.categoryName}',
        description: 'Você já gastou $usedPercentage% do orçamento de ${goal.categoryName}. Restam R\$ ${remainingAmount.toStringAsFixed(2)} para os próximos $daysLeft dias (R\$ ${dailyBudgetLeft.toStringAsFixed(2)}/dia).',
        type: FinancialInsightType.budgetWarning,
        priority: usedPercentage >= 90 ? FinancialInsightPriority.high : FinancialInsightPriority.medium,
        data: {
          'categoryId': goal.categoryId,
          'categoryName': goal.categoryName,
          'budgetLimit': goal.monthlyLimit,
          'currentSpent': goal.currentSpent,
          'remainingAmount': remainingAmount,
          'usedPercentage': usedPercentage,
          'daysLeft': daysLeft,
          'dailyBudgetLeft': dailyBudgetLeft,
          'riskLevel': riskLevel,
        },
        actionSuggestions: [
          'Limite seus gastos em ${goal.categoryName} a R\$ ${dailyBudgetLeft.toStringAsFixed(2)} por dia',
          'Monitore cada gasto nesta categoria',
          'Considere adiar compras não essenciais',
          if (usedPercentage >= 90) 'Evite gastos desnecessários nesta categoria',
        ],
        createdAt: now,
        isRead: false,
      ));
    }
    
    return insights;
  }
  
  /// Insights de performance positiva
  List<FinancialInsight> _generatePositivePerformanceInsights(List<FinancialGoal> goals, DateTime now) {
    final insights = <FinancialInsight>[];
    
    final goodGoals = goals.where((g) => 
      g.status == FinancialGoalStatus.good && 
      g.isActive &&
      g.currentSpent > 0 // Tem algum gasto
    ).toList();
    
    if (goodGoals.isNotEmpty) {
      final bestGoal = goodGoals.reduce((a, b) => 
        a.progressPercentage < b.progressPercentage ? a : b
      );
      
      final savedAmount = bestGoal.remainingAmount;
      final usedPercentage = (bestGoal.progressPercentage * 100).round();
      
      insights.add(FinancialInsight(
        id: 'positive_${bestGoal.id}_${now.millisecondsSinceEpoch}',
        title: '🎉 Parabéns! Economia em ${bestGoal.categoryName}',
        description: 'Você está indo muito bem! Gastou apenas $usedPercentage% do orçamento de ${bestGoal.categoryName}, economizando R\$ ${savedAmount.toStringAsFixed(2)}.',
        type: FinancialInsightType.goalProgress,
        priority: FinancialInsightPriority.low,
        data: {
          'categoryId': bestGoal.categoryId,
          'categoryName': bestGoal.categoryName,
          'budgetLimit': bestGoal.monthlyLimit,
          'currentSpent': bestGoal.currentSpent,
          'savedAmount': savedAmount,
          'usedPercentage': usedPercentage,
        },
        actionSuggestions: [
          'Continue assim! Você está no caminho certo',
          'Considere realocar parte desta economia para outras categorias',
          'Use essa economia para criar uma reserva de emergência',
        ],
        createdAt: now,
        isRead: false,
      ));
    }
    
    return insights;
  }
  
  /// Insights de otimização de orçamento
  List<FinancialInsight> _generateBudgetOptimizationInsights(
    List<FinancialGoal> goals,
    List<Expense> expenses,
    List<ExpenseCategory> categories,
    DateTime now,
  ) {
    final insights = <FinancialInsight>[];
    
    // Encontrar categorias com orçamento muito alto comparado ao gasto
    final underutilizedGoals = goals.where((g) => 
      g.isActive && 
      g.progressPercentage < 0.3 && // Menos de 30% usado
      g.currentSpent > 0 // Tem algum gasto
    ).toList();
    
    if (underutilizedGoals.isNotEmpty) {
      final goal = underutilizedGoals.first;
      final unusedAmount = goal.remainingAmount;
      final usedPercentage = (goal.progressPercentage * 100).round();
      
      insights.add(FinancialInsight(
        id: 'optimization_${goal.id}_${now.millisecondsSinceEpoch}',
        title: '💡 Oportunidade de Otimização: ${goal.categoryName}',
        description: 'Você usou apenas $usedPercentage% do orçamento de ${goal.categoryName}. Considere realocar R\$ ${(unusedAmount * 0.5).toStringAsFixed(2)} para outras categorias.',
        type: FinancialInsightType.savingsOpportunity,
        priority: FinancialInsightPriority.medium,
        data: {
          'categoryId': goal.categoryId,
          'categoryName': goal.categoryName,
          'budgetLimit': goal.monthlyLimit,
          'currentSpent': goal.currentSpent,
          'unusedAmount': unusedAmount,
          'usedPercentage': usedPercentage,
          'suggestedReallocation': unusedAmount * 0.5,
        },
        actionSuggestions: [
          'Reduza o orçamento de ${goal.categoryName} em 20-30%',
          'Realoque parte deste orçamento para categorias que precisam',
          'Use essa economia para aumentar sua reserva de emergência',
        ],
        createdAt: now,
        isRead: false,
      ));
    }
    
    return insights;
  }
  
  /// Insights de padrões de gastos
  List<FinancialInsight> _generateSpendingPatternInsights(
    List<Expense> expenses,
    List<FinancialGoal> goals,
    List<ExpenseCategory> categories,
    DateTime now,
  ) {
    final insights = <FinancialInsight>[];
    
    // Analisar gastos por dia da semana
    final weekdaySpending = <int, double>{};
    for (final expense in expenses) {
      final weekday = expense.date.weekday;
      weekdaySpending[weekday] = (weekdaySpending[weekday] ?? 0) + expense.amount;
    }
    
    if (weekdaySpending.isNotEmpty) {
      final maxWeekday = weekdaySpending.entries.reduce((a, b) => 
        a.value > b.value ? a : b
      );
      
      final weekdayNames = ['', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
      final dayName = weekdayNames[maxWeekday.key];
      final totalSpent = weekdaySpending.values.reduce((a, b) => a + b);
      final percentage = ((maxWeekday.value / totalSpent) * 100).round();
      
      if (percentage > 30) { // Mais de 30% dos gastos em um dia
        insights.add(FinancialInsight(
          id: 'pattern_weekday_${now.millisecondsSinceEpoch}',
          title: '📊 Padrão Identificado: Gastos em $dayName',
          description: 'Você gasta mais em $dayName ($percentage% do total). Considere planejar melhor os gastos deste dia.',
          type: FinancialInsightType.spendingPattern,
          priority: FinancialInsightPriority.low,
          data: {
            'weekday': maxWeekday.key,
            'weekdayName': dayName,
            'amount': maxWeekday.value,
            'percentage': percentage,
            'totalSpent': totalSpent,
          },
          actionSuggestions: [
            'Planeje seus gastos de $dayName com antecedência',
            'Defina um limite específico para gastos em $dayName',
            'Evite compras por impulso neste dia',
          ],
          createdAt: now,
          isRead: false,
        ));
      }
    }
    
    return insights;
  }
  
  /// Insights preditivos baseados no ritmo atual de gastos
  List<FinancialInsight> _generatePredictiveInsights(
    List<FinancialGoal> goals,
    List<Expense> expenses,
    DateTime now,
  ) {
    final insights = <FinancialInsight>[];
    
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;
    final daysRemaining = daysInMonth - daysPassed;
    
    if (daysRemaining > 0 && daysPassed > 5) { // Só após 5 dias do mês
      for (final goal in goals.where((g) => g.isActive && g.currentSpent > 0)) {
        final dailyAverage = goal.currentSpent / daysPassed;
        final projectedSpending = dailyAverage * daysInMonth;
        
        if (projectedSpending > goal.monthlyLimit * 1.1) { // Projeção 10% acima do limite
          final projectedExcess = projectedSpending - goal.monthlyLimit;
          
          insights.add(FinancialInsight(
            id: 'prediction_${goal.id}_${now.millisecondsSinceEpoch}',
            title: '🔮 Projeção: Risco em ${goal.categoryName}',
            description: 'No ritmo atual (R\$ ${dailyAverage.toStringAsFixed(2)}/dia), você pode exceder o orçamento de ${goal.categoryName} em R\$ ${projectedExcess.toStringAsFixed(2)} até o fim do mês.',
            type: FinancialInsightType.budgetWarning,
            priority: FinancialInsightPriority.medium,
            data: {
              'categoryId': goal.categoryId,
              'categoryName': goal.categoryName,
              'dailyAverage': dailyAverage,
              'projectedSpending': projectedSpending,
              'projectedExcess': projectedExcess,
              'daysRemaining': daysRemaining,
              'recommendedDailyLimit': goal.remainingAmount / daysRemaining,
            },
            actionSuggestions: [
              'Reduza seus gastos diários em ${goal.categoryName} para R\$ ${(goal.remainingAmount / daysRemaining).toStringAsFixed(2)}',
              'Monitore mais de perto os gastos desta categoria',
              'Considere adiar compras não essenciais',
            ],
            createdAt: now,
            isRead: false,
          ));
        }
      }
    }
    
    return insights;
  }
  
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
}
