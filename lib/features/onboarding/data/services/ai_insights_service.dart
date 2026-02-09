import 'package:get/get.dart';
import '../../../../core/services/openai_service.dart';
import '../../../../core/services/financial_context_service.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/logging_service.dart';
import '../../../expenses/domain/entities/financial_insight.dart';
import '../../../expenses/domain/entities/financial_goal.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/entities/category.dart';
import '../../../expenses/core/expense_filters.dart';
import '../../../investments/domain/entities/investment.dart';
import '../models/onboarding_question_model.dart';

class AIInsightsService extends GetxService {
  late final OpenAIService _openAIService;

  @override
  void onInit() {
    super.onInit();
    _openAIService = Get.find<OpenAIService>();
  }

  /// Gera insights baseados apenas no perfil do onboarding
  Future<List<FinancialInsight>> generateOnboardingInsights(OnboardingProfileModel profile) async {
    final insights = <FinancialInsight>[];
    
    // Tentar gerar insight com IA real primeiro
    if (await _openAIService.isConfigured()) {
      try {
        final aiInsight = await _generateAIInsight(profile, {});
        if (aiInsight != null) {
          insights.add(aiInsight);
        }
      } catch (e) {
        print('⚠️ Erro ao gerar insight com IA: $e');
      }
    }
    
    // Adicionar insights baseados no objetivo
    insights.addAll(_generateGoalBasedInsights(profile));
    
    // Adicionar insights baseados na renda
    insights.addAll(_generateIncomeBasedInsights(profile));
    
    // Adicionar insights motivacionais
    insights.addAll(_generateMotivationBasedInsights(profile));
    
    return insights;
  }

  /// Gera insights baseados nos dados reais + perfil do onboarding
  Future<List<FinancialInsight>> generateHybridInsights(
    OnboardingProfileModel profile,
    List<Expense> expenses,
    List<ExpenseCategory> categories,
  ) async {
    final insights = <FinancialInsight>[];
    
    // Filtrar investimentos das despesas
    final expensesWithoutInvestments = ExpenseFilters.excludeInvestments(expenses);
    
    // Se não tem dados suficientes, usa insights do onboarding
    if (expensesWithoutInvestments.isEmpty || expensesWithoutInvestments.length < 5) {
      return await generateOnboardingInsights(profile);
    }
    
    // Combina dados reais com perfil do onboarding
    insights.addAll(_generateSpendingPatternInsights(profile, expensesWithoutInvestments, categories));
    insights.addAll(_generateBudgetComparisonInsights(profile, expensesWithoutInvestments));
    insights.addAll(_generateGoalProgressInsights(profile, expensesWithoutInvestments));
    
    return insights;
  }
  
  /// Gera insights incluindo investimentos no contexto
  Future<List<FinancialInsight>> generateInsightsWithInvestments(
    OnboardingProfileModel profile,
    List<Expense> expenses,
    List<ExpenseCategory> categories,
    List<Investment> investments,
  ) async {
    final insights = <FinancialInsight>[];
    
    // Filtrar investimentos das despesas
    final expensesWithoutInvestments = ExpenseFilters.excludeInvestments(expenses);
    
    // Gerar insights básicos
    insights.addAll(await generateHybridInsights(profile, expensesWithoutInvestments, categories));
    
    // Gerar insights de investimentos
    insights.addAll(_generateInvestmentInsights(profile, investments, expensesWithoutInvestments));
    
    return insights;
  }
  
  /// Gera insights sobre investimentos
  List<FinancialInsight> _generateInvestmentInsights(
    OnboardingProfileModel profile,
    List<Investment> investments,
    List<Expense> expenses,
  ) {
    final insights = <FinancialInsight>[];
    final now = DateTime.now();
    
    // Total investido no mês
    final monthInvestments = investments.where(
      (inv) => inv.date.year == now.year && inv.date.month == now.month
    ).toList();
    final totalInvestedThisMonth = monthInvestments.fold(0.0, (sum, inv) => sum + inv.amount);
    
    // Total gasto no mês (sem investimentos)
    final monthExpenses = expenses.where(
      (exp) => exp.date.year == now.year && exp.date.month == now.month
    ).toList();
    final totalSpentThisMonth = monthExpenses.fold(0.0, (sum, exp) => sum + exp.amount);
    
    // Se não está investindo
    if (monthInvestments.isEmpty && investments.isEmpty) {
      insights.add(FinancialInsight(
        id: 'invest_start_${now.millisecondsSinceEpoch}',
        type: FinancialInsightType.savingsOpportunity,
        priority: FinancialInsightPriority.medium,
        title: 'Comece a Investir 📈',
        description: 'Você ainda não registrou nenhum investimento. '
            'Que tal começar com uma reserva de emergência na poupança ou um CDB?',
        data: {'type': 'investment_start'},
        actionSuggestions: ['Ver Investimentos', 'Criar Meta'],
        createdAt: now,
        isRead: false,
      ));
    }
    
    // Se está investindo menos que 10% da renda (baseado no perfil)
    final incomeRange = profile.getIncome();
    double estimatedIncome = 5000; // valor padrão
    if (incomeRange != null) {
      if (incomeRange.contains('1.000') || incomeRange.contains('2.000')) {
        estimatedIncome = 2000;
      } else if (incomeRange.contains('3.000') || incomeRange.contains('5.000')) {
        estimatedIncome = 4000;
      } else if (incomeRange.contains('5.000') || incomeRange.contains('10.000')) {
        estimatedIncome = 7500;
      } else if (incomeRange.contains('10.000')) {
        estimatedIncome = 15000;
      }
    }
    
    final investmentRatio = totalInvestedThisMonth / estimatedIncome;
    
    if (investments.isNotEmpty && investmentRatio < 0.1) {
      insights.add(FinancialInsight(
        id: 'invest_increase_${now.millisecondsSinceEpoch}',
        type: FinancialInsightType.goalProgress,
        priority: FinancialInsightPriority.medium,
        title: 'Aumente seus Investimentos 📊',
        description: 'Você investiu apenas ${(investmentRatio * 100).toStringAsFixed(1)}% da renda estimada este mês. '
            'O ideal é investir pelo menos 10-20% da renda.',
        data: {
          'invested_ratio': investmentRatio,
          'recommended_ratio': 0.15,
        },
        actionSuggestions: ['Ajustar Meta', 'Ver Dicas'],
        createdAt: now,
        isRead: false,
      ));
    }
    
    // Se está investindo mais do que gastando - parabéns!
    if (totalInvestedThisMonth > 0 && totalInvestedThisMonth >= totalSpentThisMonth * 0.3) {
      insights.add(FinancialInsight(
        id: 'invest_great_${now.millisecondsSinceEpoch}',
        type: FinancialInsightType.positiveProgress,
        priority: FinancialInsightPriority.low,
        title: 'Excelente Equilíbrio! 🎉',
        description: 'Parabéns! Você está investindo R\$ ${totalInvestedThisMonth.toStringAsFixed(2)} este mês, '
            'um ótimo equilíbrio com seus gastos.',
        data: {
          'invested': totalInvestedThisMonth,
          'spent': totalSpentThisMonth,
        },
        actionSuggestions: ['Continuar Assim', 'Ver Evolução'],
        createdAt: now,
        isRead: false,
      ));
    }
    
    // Análise de diversificação
    if (investments.length > 3) {
      final typeCount = <InvestmentType>{};
      for (final inv in investments) {
        typeCount.add(inv.type);
      }
      
      if (typeCount.length < 2) {
        insights.add(FinancialInsight(
          id: 'invest_diversify_${now.millisecondsSinceEpoch}',
          type: FinancialInsightType.spendingPattern,
          priority: FinancialInsightPriority.medium,
          title: 'Diversifique seus Investimentos 🎯',
          description: 'Seus investimentos estão concentrados em apenas ${typeCount.length} tipo(s). '
              'Diversificar pode reduzir riscos e aumentar retornos.',
          data: {'types_count': typeCount.length},
          actionSuggestions: ['Ver Tipos', 'Aprender Mais'],
          createdAt: now,
          isRead: false,
        ));
      }
    }
    
    return insights;
  }

  /// Gera insight usando OpenAI
  Future<FinancialInsight?> _generateAIInsight(
    OnboardingProfileModel profile,
    Map<String, dynamic> expenseData,
  ) async {
    try {
      final aiResponse = await _openAIService.generateFinancialInsight(
        userProfile: profile,
        expenseData: expenseData,
      );

      return FinancialInsight(
        id: 'ai_insight_${DateTime.now().millisecondsSinceEpoch}',
        type: FinancialInsightType.savingsOpportunity,
        priority: FinancialInsightPriority.high,
        title: '🤖 Insight Personalizado com IA',
        description: aiResponse,
        data: {'source': 'openai', 'personalized': true},
        actionSuggestions: ['Ver Mais Dicas', 'Aplicar Sugestão'],
        createdAt: DateTime.now(),
        isRead: false,
      );
    } catch (e) {
      print('❌ Erro ao gerar insight com OpenAI: $e');
      return null;
    }
  }

  /// Gera insights baseados no objetivo escolhido
  List<FinancialInsight> _generateGoalBasedInsights(OnboardingProfileModel profile) {
    final goal = profile.getGoal();
    if (goal == null) return [];

    if (goal.contains('economizar')) {
      return [
        FinancialInsight(
          id: 'goal_save_tip',
          type: FinancialInsightType.savingsOpportunity,
          priority: FinancialInsightPriority.high,
          title: 'Dica para Economizar 💰',
          description: 'Comece aplicando a regra 50-30-20: 50% para gastos essenciais, 30% para desejos e 20% para poupança. Mesmo R\$ 50 por mês já faz diferença!',
          data: {'rule': '50-30-20', 'goal': 'save'},
          actionSuggestions: ['Criar Meta de Economia', 'Calcular Orçamento'],
          createdAt: DateTime.now(),
          isRead: false,
        ),
      ];
    }
    
    if (goal.contains('investir')) {
      return [
        FinancialInsight(
          id: 'goal_invest_tip',
          type: FinancialInsightType.goalProgress,
          priority: FinancialInsightPriority.medium,
          title: 'Primeiros Passos para Investir 📈',
          description: 'Antes de investir, tenha uma reserva de emergência de 6 meses de gastos. Depois, comece com investimentos de baixo risco como Tesouro Direto.',
          data: {'investment_type': 'beginner', 'emergency_months': 6},
          actionSuggestions: ['Calcular Reserva', 'Ver Investimentos'],
          createdAt: DateTime.now(),
          isRead: false,
        ),
      ];
    }
    
    if (goal.contains('organizar')) {
      return [
        FinancialInsight(
          id: 'goal_organize_tip',
          type: FinancialInsightType.spendingPattern,
          priority: FinancialInsightPriority.high,
          title: 'Organizando suas Finanças 📊',
          description: 'Registre TODOS os gastos por 30 dias, mesmo os pequenos. Isso vai te dar uma visão real de onde seu dinheiro está indo.',
          data: {'tracking_period': 30, 'goal': 'organize'},
          actionSuggestions: ['Começar Registro', 'Ver Tutorial'],
          createdAt: DateTime.now(),
          isRead: false,
        ),
      ];
    }
    
    return [];
  }

  /// Gera insights baseados na renda informada
  List<FinancialInsight> _generateIncomeBasedInsights(OnboardingProfileModel profile) {
    final income = profile.getIncome();
    if (income == null) return [];

    String description;
    if (income.contains('até R\$ 2.000')) {
      description = 'Com sua renda, foque primeiro em controlar gastos básicos. Cada R\$ 1 economizado faz diferença! Comece com pequenas metas de R\$ 20-50 por mês.';
    } else if (income.contains('R\$ 2.001 a R\$ 5.000')) {
      description = 'Sua renda permite criar uma reserva de emergência. Tente economizar 10-15% da renda mensal. Isso seria entre R\$ 200-750 por mês.';
    } else if (income.contains('R\$ 5.001 a R\$ 10.000')) {
      description = 'Com essa renda, você pode focar em investimentos. Após ter 6 meses de reserva, considere diversificar entre poupança, CDB e fundos.';
    } else {
      description = 'Sua renda permite estratégias mais avançadas. Considere consultoria financeira e investimentos de longo prazo como ações e fundos imobiliários.';
    }

    return [
      FinancialInsight(
        id: 'income_analysis_tip',
        type: FinancialInsightType.spendingPattern,
        priority: FinancialInsightPriority.medium,
        title: 'Análise da sua Renda 💰',
        description: description,
        data: {'income_range': income, 'analysis_type': 'income'},
        actionSuggestions: ['Ver Dicas de Economia', 'Calcular Orçamento'],
        createdAt: DateTime.now(),
        isRead: false,
      ),
    ];
  }

  /// Gera insights motivacionais baseados no perfil
  List<FinancialInsight> _generateMotivationBasedInsights(OnboardingProfileModel profile) {
    final motivation = profile.getMotivation();
    if (motivation == null) return [];

    String title;
    String description;
    
    if (motivation.contains('casa')) {
      title = 'Sonho da Casa Própria 🏠';
      description = 'Para conquistar a casa própria, organize suas finanças e crie um plano de poupança específico. Considere FGTS, financiamento e entrada.';
    } else if (motivation.contains('viagem')) {
      title = 'Planejando sua Viagem dos Sonhos ✈️';
      description = 'Transforme sua viagem em realidade! Defina o destino, calcule os custos e crie uma meta mensal de economia específica para isso.';
    } else if (motivation.contains('aposentadoria')) {
      title = 'Preparando sua Aposentadoria 🌅';
      description = 'Quanto antes começar, melhor! Considere previdência privada, INSS e investimentos de longo prazo para garantir um futuro tranquilo.';
    } else {
      title = 'Realizando seus Sonhos 🌟';
      description = 'Todo sonho financeiro é possível com planejamento! Defina metas claras, prazos realistas e comece hoje mesmo.';
    }

    return [
      FinancialInsight(
        id: 'motivation_tip',
        type: FinancialInsightType.goalProgress,
        priority: FinancialInsightPriority.medium,
        title: title,
        description: description,
        data: {'motivation': motivation, 'type': 'motivational'},
        actionSuggestions: ['Criar Meta', 'Ver Planos'],
        createdAt: DateTime.now(),
        isRead: false,
      ),
    ];
  }

  /// Insights baseados em padrões de gastos reais
  List<FinancialInsight> _generateSpendingPatternInsights(
    OnboardingProfileModel profile,
    List<Expense> expenses,
    List<ExpenseCategory> categories,
  ) {
    final insights = <FinancialInsight>[];
    final now = DateTime.now();

    if (expenses.isEmpty) return insights;

    // Agrupar gastos por categoria
    final categorySpending = <String, double>{};
    for (final expense in expenses) {
      categorySpending[expense.categoryId] =
          (categorySpending[expense.categoryId] ?? 0) + expense.amount;
    }

    // Encontrar categoria dominante
    if (categorySpending.isNotEmpty) {
      final sortedCategories = categorySpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topCategory = sortedCategories.first;
      final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
      final percentage = (topCategory.value / totalSpent * 100).round();

      if (percentage >= 40) {
        final category = _findCategoryById(topCategory.key, categories);
        final categoryName = category?.name ?? _getCategoryNameFromId(topCategory.key);

        insights.add(FinancialInsight(
          id: 'spending_pattern_dominant',
          type: FinancialInsightType.spendingPattern,
          priority: FinancialInsightPriority.medium,
          title: 'Concentração de Gastos: $categoryName',
          description: '$percentage% dos seus gastos estão em $categoryName (R\$ ${topCategory.value.toStringAsFixed(2)}). Considere diversificar ou estabelecer um limite para esta categoria.',
          data: {
            'categoryId': topCategory.key,
            'categoryName': categoryName,
            'amount': topCategory.value,
            'percentage': percentage,
          },
          actionSuggestions: [
            'Definir meta para $categoryName',
            'Analisar gastos detalhados',
            'Buscar alternativas econômicas',
          ],
          createdAt: now,
          isRead: false,
        ));
      }
    }

    return insights;
  }

  /// Insights de comparação com orçamento usando contexto financeiro real
  List<FinancialInsight> _generateBudgetComparisonInsights(
    OnboardingProfileModel profile,
    List<Expense> expenses,
  ) {
    final insights = <FinancialInsight>[];
    final now = DateTime.now();

    try {
      // Tentar obter contexto financeiro real
      if (Get.isRegistered<FinancialContextService>()) {
        final contextService = Get.find<FinancialContextService>();
        // Usar dados do cache se disponível (síncrono)
        // Para análise assíncrona, use generateHybridInsightsWithContext
      }
    } catch (e) {
      AppLogger.warning(FeatureTag.goals, 'Não foi possível obter contexto para insights');
    }

    // Calcular gasto médio diário
    if (expenses.isNotEmpty) {
      final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final dailyAverage = totalSpent / now.day;
      final projectedMonthly = dailyAverage * daysInMonth;

      // Comparar com renda do perfil
      final incomeStr = profile.getIncome();
      double? estimatedIncome;

      if (incomeStr != null) {
        if (incomeStr.contains('até R\$ 2.000')) {
          estimatedIncome = 2000;
        } else if (incomeStr.contains('R\$ 2.001 a R\$ 5.000')) {
          estimatedIncome = 3500;
        } else if (incomeStr.contains('R\$ 5.001 a R\$ 10.000')) {
          estimatedIncome = 7500;
        } else if (incomeStr.contains('mais de R\$ 10.000')) {
          estimatedIncome = 15000;
        }
      }

      if (estimatedIncome != null) {
        final projectedPercentage = (projectedMonthly / estimatedIncome * 100).round();

        if (projectedPercentage > 100) {
          insights.add(FinancialInsight(
            id: 'budget_projection_exceeded',
            type: FinancialInsightType.budgetExceeded,
            priority: FinancialInsightPriority.high,
            title: '⚠️ Projeção de Gastos Alta',
            description: 'No ritmo atual, você gastará aproximadamente R\$ ${projectedMonthly.toStringAsFixed(2)} este mês ($projectedPercentage% da renda). Considere reduzir gastos.',
            data: {
              'dailyAverage': dailyAverage,
              'projectedMonthly': projectedMonthly,
              'estimatedIncome': estimatedIncome,
              'projectedPercentage': projectedPercentage,
            },
            actionSuggestions: [
              'Revisar gastos não essenciais',
              'Definir limite diário',
              'Pausar compras não urgentes',
            ],
            createdAt: now,
            isRead: false,
          ));
        } else if (projectedPercentage < 70) {
          insights.add(FinancialInsight(
            id: 'budget_projection_good',
            type: FinancialInsightType.savingsOpportunity,
            priority: FinancialInsightPriority.low,
            title: '✅ Ótimo Controle de Gastos',
            description: 'Você está gastando apenas $projectedPercentage% da renda estimada. Continue assim! Considere guardar a diferença.',
            data: {
              'projectedPercentage': projectedPercentage,
              'potentialSavings': estimatedIncome - projectedMonthly,
            },
            actionSuggestions: [
              'Criar reserva de emergência',
              'Investir a economia',
              'Definir meta de poupança',
            ],
            createdAt: now,
            isRead: false,
          ));
        }
      }
    }

    return insights;
  }

  /// Insights de progresso de metas usando dados reais do FinancialContextService
  List<FinancialInsight> _generateGoalProgressInsights(
    OnboardingProfileModel profile,
    List<Expense> expenses,
  ) {
    final insights = <FinancialInsight>[];
    final now = DateTime.now();

    try {
      // Obter alertas proativos do contexto financeiro
      if (Get.isRegistered<FinancialContextService>()) {
        final contextService = Get.find<FinancialContextService>();

        // Buscar alertas de forma síncrona usando cache
        contextService.getProactiveAlerts().then((alerts) {
          for (final alert in alerts) {
            // Os alertas já são processados pelo FinancialContextService
            AppLogger.debug(FeatureTag.goals, 'Alerta proativo: ${alert.message}');
          }
        });
      }
    } catch (e) {
      AppLogger.warning(FeatureTag.goals, 'Erro ao gerar insights de metas', data: {'error': e.toString()});
    }

    // Insight baseado no objetivo do usuário
    final goal = profile.getGoal();
    if (goal != null) {
      if (goal.contains('economizar') || goal.contains('poupar')) {
        final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
        final savingsGoal = profile.getSavingsGoal();

        if (savingsGoal != null && savingsGoal > 0) {
          insights.add(FinancialInsight(
            id: 'goal_savings_progress',
            type: FinancialInsightType.goalProgress,
            priority: FinancialInsightPriority.medium,
            title: '🎯 Progresso da Meta de Economia',
            description: 'Sua meta é economizar R\$ ${savingsGoal.toStringAsFixed(2)} por mês. Continue controlando os gastos para alcançar esse objetivo!',
            data: {
              'savingsGoal': savingsGoal,
              'currentSpent': totalSpent,
            },
            actionSuggestions: [
              'Ver relatório de gastos',
              'Ajustar orçamento',
              'Configurar lembretes',
            ],
            createdAt: now,
            isRead: false,
          ));
        }
      }
    }

    return insights;
  }

  /// Gera insights híbridos usando o contexto financeiro completo
  /// Esta é a forma recomendada para obter insights mais precisos
  Future<List<FinancialInsight>> generateHybridInsightsWithContext(
    OnboardingProfileModel profile,
  ) async {
    final insights = <FinancialInsight>[];
    final now = DateTime.now();

    try {
      // Obter contexto financeiro completo
      if (!Get.isRegistered<FinancialContextService>()) {
        return await generateOnboardingInsights(profile);
      }

      final contextService = Get.find<FinancialContextService>();
      final context = await contextService.getContext();

      // Gerar insights baseados em alertas reais
      for (final alert in context.alerts) {
        if (alert.type == GoalAlertType.exceeded) {
          insights.add(FinancialInsight(
            id: 'goal_exceeded_${alert.categoryId}',
            type: FinancialInsightType.budgetExceeded,
            priority: FinancialInsightPriority.high,
            title: '🚨 Orçamento Excedido: ${alert.categoryName}',
            description: alert.message,
            data: {
              'categoryId': alert.categoryId,
              'categoryName': alert.categoryName,
              'excessAmount': alert.value,
            },
            actionSuggestions: [
              'Revisar gastos em ${alert.categoryName}',
              'Ajustar orçamento',
              'Pausar gastos não essenciais',
            ],
            createdAt: now,
            isRead: false,
          ));
        } else if (alert.type == GoalAlertType.warning) {
          insights.add(FinancialInsight(
            id: 'goal_warning_${alert.categoryId}',
            type: FinancialInsightType.budgetWarning,
            priority: FinancialInsightPriority.medium,
            title: '⚠️ Atenção: ${alert.categoryName}',
            description: alert.message,
            data: {
              'categoryId': alert.categoryId,
              'categoryName': alert.categoryName,
              'remainingAmount': alert.value,
            },
            actionSuggestions: [
              'Monitorar gastos restantes',
              'Ver detalhes da categoria',
            ],
            createdAt: now,
            isRead: false,
          ));
        }
      }

      // Insight de orçamento diário
      if (context.dailyBudgetAvailable > 0) {
        insights.add(FinancialInsight(
          id: 'daily_budget_info',
          type: FinancialInsightType.savingsOpportunity,
          priority: FinancialInsightPriority.low,
          title: '💰 Orçamento Diário Disponível',
          description: 'Você pode gastar até R\$ ${context.dailyBudgetAvailable.toStringAsFixed(2)} por dia pelos próximos ${context.daysRemainingInMonth} dias para ficar dentro do orçamento.',
          data: {
            'dailyBudget': context.dailyBudgetAvailable,
            'daysRemaining': context.daysRemainingInMonth,
            'budgetRemaining': context.budgetRemaining,
          },
          actionSuggestions: [
            'Ver detalhes do orçamento',
            'Planejar gastos da semana',
          ],
          createdAt: now,
          isRead: false,
        ));
      }

      // Se não há alertas e está tudo bem
      if (context.alerts.isEmpty && context.hasGoals) {
        insights.add(FinancialInsight(
          id: 'all_goals_on_track',
          type: FinancialInsightType.goalProgress,
          priority: FinancialInsightPriority.low,
          title: '✅ Suas Metas Estão no Caminho Certo!',
          description: 'Parabéns! Todas as suas ${context.goals.length} metas estão dentro do esperado. Continue assim!',
          data: {
            'goalsCount': context.goals.length,
            'healthyGoalsCount': context.healthyGoals.length,
          },
          actionSuggestions: [
            'Ver progresso detalhado',
            'Definir novas metas',
          ],
          createdAt: now,
          isRead: false,
        ));
      }

    } catch (e) {
      AppLogger.error(FeatureTag.goals, 'Erro ao gerar insights com contexto', error: e);
      // Fallback para insights básicos
      return await generateOnboardingInsights(profile);
    }

    return insights;
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
