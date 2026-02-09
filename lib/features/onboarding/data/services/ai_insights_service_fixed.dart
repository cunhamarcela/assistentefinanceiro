import 'package:get/get.dart';
import '../../../../core/services/openai_service.dart';
import '../../../expenses/domain/entities/financial_insight.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/entities/category.dart';
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
    
    // Se não tem dados suficientes, usa insights do onboarding
    if (expenses.isEmpty || expenses.length < 5) {
      return await generateOnboardingInsights(profile);
    }
    
    // Combina dados reais com perfil do onboarding
    insights.addAll(_generateSpendingPatternInsights(profile, expenses, categories));
    insights.addAll(_generateBudgetComparisonInsights(profile, expenses));
    insights.addAll(_generateGoalProgressInsights(profile, expenses));
    
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
    // Implementação simplificada para evitar erros
    return [];
  }

  /// Insights de comparação com orçamento
  List<FinancialInsight> _generateBudgetComparisonInsights(
    OnboardingProfileModel profile,
    List<Expense> expenses,
  ) {
    // Implementação simplificada para evitar erros
    return [];
  }

  /// Insights de progresso de metas
  List<FinancialInsight> _generateGoalProgressInsights(
    OnboardingProfileModel profile,
    List<Expense> expenses,
  ) {
    // Implementação simplificada para evitar erros
    return [];
  }
}
