import 'package:get/get.dart';
import '../../features/expenses/domain/entities/expense.dart';
import '../../features/expenses/domain/entities/financial_goal.dart';
import '../../features/expenses/domain/entities/financial_profile.dart';
import '../../features/expenses/domain/entities/category.dart';
import '../../features/expenses/core/expense_filters.dart';
import '../../features/expenses/presentation/controllers/expense_controller.dart';
import '../../features/expenses/presentation/controllers/financial_goals_controller.dart';
import '../../features/expenses/data/services/financial_profile_service.dart';
import '../../features/onboarding/data/services/onboarding_service.dart';
import '../../features/onboarding/data/models/onboarding_question_model.dart';
import '../../features/investments/domain/entities/investment.dart';
import '../../features/investments/presentation/controllers/investment_controller.dart';
import 'app_logger.dart';
import 'logging_service.dart';

/// Modelo de dados agregados do contexto financeiro do usuário
class FinancialContext {
  final OnboardingProfileModel? userProfile;
  final FinancialProfile? financialProfile;
  final List<FinancialGoal> goals;
  final List<Expense> currentMonthExpenses;
  final double totalSpentThisMonth;
  final double budgetRemaining;
  final List<GoalAlert> alerts;
  final Map<String, double> categorySpending;
  final int daysRemainingInMonth;
  final double dailyBudgetAvailable;
  
  // Investimentos
  final List<Investment> currentMonthInvestments;
  final double totalInvestedThisMonth;
  final double totalInvestedAllTime;
  final Map<InvestmentType, double> investmentsByType;

  FinancialContext({
    this.userProfile,
    this.financialProfile,
    this.goals = const [],
    this.currentMonthExpenses = const [],
    this.totalSpentThisMonth = 0,
    this.budgetRemaining = 0,
    this.alerts = const [],
    this.categorySpending = const {},
    this.daysRemainingInMonth = 0,
    this.dailyBudgetAvailable = 0,
    this.currentMonthInvestments = const [],
    this.totalInvestedThisMonth = 0,
    this.totalInvestedAllTime = 0,
    this.investmentsByType = const {},
  });

  /// Verifica se há metas configuradas
  bool get hasGoals => goals.isNotEmpty;

  /// Verifica se há alertas ativos
  bool get hasAlerts => alerts.isNotEmpty;

  /// Retorna metas excedidas
  List<FinancialGoal> get exceededGoals =>
      goals.where((g) => g.isExceeded && g.isActive).toList();

  /// Retorna metas em alerta (80-100%)
  List<FinancialGoal> get warningGoals => goals
      .where((g) => g.status == FinancialGoalStatus.warning && g.isActive)
      .toList();

  /// Retorna metas saudáveis
  List<FinancialGoal> get healthyGoals => goals
      .where((g) =>
          (g.status == FinancialGoalStatus.good ||
              g.status == FinancialGoalStatus.onTrack) &&
          g.isActive)
      .toList();

  /// Formata contexto para uso em prompts de IA
  String toPromptContext() {
    final buffer = StringBuffer();

    // Perfil básico
    if (userProfile != null) {
      final goal = userProfile!.getGoal();
      final income = userProfile!.getIncome();
      final challenge = userProfile!.getBiggestChallenge();

      buffer.writeln('**PERFIL DO USUÁRIO:**');
      if (goal != null) buffer.writeln('- Objetivo: $goal');
      if (income != null) buffer.writeln('- Faixa de renda: $income');
      if (challenge != null) buffer.writeln('- Maior desafio: $challenge');
      buffer.writeln();
    }

    // Situação financeira atual
    buffer.writeln('**SITUAÇÃO FINANCEIRA ATUAL (${_getMonthName(DateTime.now().month)}):**');

    if (financialProfile != null) {
      buffer.writeln('- Orçamento total: R\$ ${financialProfile!.totalBudget.toStringAsFixed(2)}');
      buffer.writeln('- Total gasto: R\$ ${totalSpentThisMonth.toStringAsFixed(2)}');
      buffer.writeln('- Saldo restante: R\$ ${budgetRemaining.toStringAsFixed(2)}');
      buffer.writeln('- Dias restantes: $daysRemainingInMonth');
      if (dailyBudgetAvailable > 0) {
        buffer.writeln('- Orçamento diário disponível: R\$ ${dailyBudgetAvailable.toStringAsFixed(2)}/dia');
      }
    }
    buffer.writeln();

    // Alertas de metas
    if (alerts.isNotEmpty) {
      buffer.writeln('**⚠️ ALERTAS IMPORTANTES:**');
      for (final alert in alerts.take(3)) {
        buffer.writeln('- ${alert.emoji} ${alert.message}');
      }
      buffer.writeln();
    }

    // Status das metas por categoria
    if (goals.isNotEmpty) {
      buffer.writeln('**STATUS DAS METAS POR CATEGORIA:**');

      // Metas excedidas primeiro
      for (final goal in exceededGoals) {
        final excess = goal.currentSpent - goal.monthlyLimit;
        buffer.writeln('- 🚨 ${goal.categoryName}: EXCEDIDO (+R\$ ${excess.toStringAsFixed(2)})');
      }

      // Metas em alerta
      for (final goal in warningGoals) {
        final usedPercent = (goal.progressPercentage * 100).round();
        buffer.writeln('- ⚠️ ${goal.categoryName}: $usedPercent% usado (R\$ ${goal.remainingAmount.toStringAsFixed(2)} restante)');
      }

      // Metas saudáveis (resumido)
      if (healthyGoals.isNotEmpty) {
        final healthyNames = healthyGoals.map((g) => g.categoryName).join(', ');
        buffer.writeln('- ✅ No caminho certo: $healthyNames');
      }
      buffer.writeln();
    }

    // Gastos por categoria (top 3)
    if (categorySpending.isNotEmpty) {
      final sortedCategories = categorySpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      buffer.writeln('**TOP GASTOS DO MÊS:**');
      for (final entry in sortedCategories.take(3)) {
        buffer.writeln('- ${entry.key}: R\$ ${entry.value.toStringAsFixed(2)}');
      }
      buffer.writeln();
    }

    // Investimentos e Meta de Investimento
    final investmentGoal = financialProfile?.monthlyInvestmentGoal ?? 0;
    
    buffer.writeln('**💰 INVESTIMENTOS:**');
    
    // Meta de investimento
    if (investmentGoal > 0) {
      final investmentProgress = totalInvestedThisMonth / investmentGoal;
      final remainingToInvest = investmentGoal - totalInvestedThisMonth;
      final progressPercent = (investmentProgress * 100).clamp(0, 999).toStringAsFixed(1);
      
      buffer.writeln('- Meta mensal: R\$ ${investmentGoal.toStringAsFixed(2)}');
      buffer.writeln('- Investido este mês: R\$ ${totalInvestedThisMonth.toStringAsFixed(2)} ($progressPercent%)');
      
      if (remainingToInvest > 0) {
        buffer.writeln('- Falta investir: R\$ ${remainingToInvest.toStringAsFixed(2)}');
      } else {
        buffer.writeln('- ✅ Meta de investimento atingida!');
      }
    } else if (totalInvestedThisMonth > 0) {
      buffer.writeln('- Investido este mês: R\$ ${totalInvestedThisMonth.toStringAsFixed(2)}');
      buffer.writeln('- ⚠️ Nenhuma meta de investimento definida');
    }
    
    // Total histórico
    if (totalInvestedAllTime > 0) {
      buffer.writeln('- Total investido (histórico): R\$ ${totalInvestedAllTime.toStringAsFixed(2)}');
      
      if (investmentsByType.isNotEmpty) {
        buffer.writeln('- Distribuição:');
        for (final entry in investmentsByType.entries) {
          final percentage = totalInvestedAllTime > 0 
              ? (entry.value / totalInvestedAllTime * 100).toStringAsFixed(1)
              : '0';
          buffer.writeln('  • ${entry.key.displayName}: R\$ ${entry.value.toStringAsFixed(2)} ($percentage%)');
        }
      }
    }
    buffer.writeln();

    return buffer.toString();
  }

  String _getMonthName(int month) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return months[month - 1];
  }
}

/// Alerta relacionado a uma meta financeira
class GoalAlert {
  final String categoryId;
  final String categoryName;
  final GoalAlertType type;
  final String message;
  final double value;
  final String emoji;

  GoalAlert({
    required this.categoryId,
    required this.categoryName,
    required this.type,
    required this.message,
    required this.value,
    required this.emoji,
  });
}

enum GoalAlertType {
  exceeded,             // Meta de despesa excedida
  warning,              // 80-100% do limite de despesa
  nearLimit,            // 60-80% do limite de despesa
  noGoal,               // Categoria sem meta definida
  investmentBelowGoal,  // Investimento abaixo da meta
  investmentOnTrack,    // Investimento no caminho certo
}

/// Serviço central para agregar contexto financeiro do usuário
/// Usado para fornecer dados contextualizados para IA e relatórios
class FinancialContextService extends GetxService {
  static FinancialContextService get instance =>
      Get.find<FinancialContextService>();

  // Cache do contexto
  FinancialContext? _cachedContext;
  DateTime? _lastUpdate;
  static const Duration _cacheExpiration = Duration(minutes: 5);

  /// Obtém o contexto financeiro completo do usuário
  Future<FinancialContext> getContext({bool forceRefresh = false}) async {
    final opId = AppLogger.startOp(FeatureTag.goals, 'get_financial_context');

    try {
      // Verificar cache
      if (!forceRefresh && _cachedContext != null && _lastUpdate != null) {
        final elapsed = DateTime.now().difference(_lastUpdate!);
        if (elapsed < _cacheExpiration) {
          AppLogger.debug(FeatureTag.goals, 'Usando contexto em cache');
          return _cachedContext!;
        }
      }

      AppLogger.debug(FeatureTag.goals, 'Construindo novo contexto financeiro');

      // Coletar dados de diferentes fontes
      final userProfile = await _getUserProfile();
      final financialProfile = await _getFinancialProfile();
      final goals = await _getGoals();
      final allExpenses = _getCurrentMonthExpenses();
      
      // Filtrar investimentos das despesas
      final expenses = ExpenseFilters.excludeInvestments(allExpenses);

      // Calcular métricas
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final daysRemaining = daysInMonth - now.day;

      final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
      final totalBudget = financialProfile?.totalBudget ?? 0;
      final budgetRemaining = totalBudget - totalSpent;
      final dailyBudget = daysRemaining > 0 ? budgetRemaining / daysRemaining : 0.0;

      // Agrupar gastos por categoria
      final categorySpending = <String, double>{};
      for (final expense in expenses) {
        final categoryName = _getCategoryName(expense.categoryId);
        categorySpending[categoryName] =
            (categorySpending[categoryName] ?? 0) + expense.amount;
      }

      // Gerar alertas de metas de despesas
      final alerts = _generateAlerts(goals, categorySpending);
      
      // Adicionar alertas de investimento (serão preenchidos depois de calcular investimentos)

      // Obter investimentos
      final investmentData = _getInvestmentData();
      final currentMonthInvestments = investmentData['currentMonth'] as List<Investment>;
      final allInvestments = investmentData['all'] as List<Investment>;
      final totalInvestedThisMonth = currentMonthInvestments.fold(0.0, (sum, inv) => sum + inv.amount);
      final totalInvestedAllTime = allInvestments.fold(0.0, (sum, inv) => sum + inv.amount);
      
      // Agrupar investimentos por tipo
      final investmentsByType = <InvestmentType, double>{};
      for (final investment in allInvestments) {
        investmentsByType[investment.type] = 
            (investmentsByType[investment.type] ?? 0) + investment.amount;
      }
      
      // Adicionar alertas de investimento
      final investmentGoal = financialProfile?.monthlyInvestmentGoal ?? 0;
      _addInvestmentAlerts(alerts, investmentGoal, totalInvestedThisMonth, daysRemaining);

      // Construir contexto
      _cachedContext = FinancialContext(
        userProfile: userProfile,
        financialProfile: financialProfile,
        goals: goals,
        currentMonthExpenses: expenses,
        totalSpentThisMonth: totalSpent,
        budgetRemaining: budgetRemaining,
        alerts: alerts,
        categorySpending: categorySpending,
        daysRemainingInMonth: daysRemaining,
        dailyBudgetAvailable: dailyBudget,
        currentMonthInvestments: currentMonthInvestments,
        totalInvestedThisMonth: totalInvestedThisMonth,
        totalInvestedAllTime: totalInvestedAllTime,
        investmentsByType: investmentsByType,
      );

      _lastUpdate = DateTime.now();

      AppLogger.completeOp(opId, message: 'Contexto financeiro construído', data: {
        'has_profile': userProfile != null,
        'goals_count': goals.length,
        'expenses_count': expenses.length,
        'alerts_count': alerts.length,
        'total_spent': totalSpent,
      });

      return _cachedContext!;
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao construir contexto', exception: e);

      // Retorna contexto vazio em caso de erro
      return FinancialContext();
    }
  }

  /// Obtém sugestões de orçamento baseadas no histórico de gastos
  Future<Map<String, double>> getSuggestedBudgets() async {
    final opId = AppLogger.startOp(FeatureTag.goals, 'get_suggested_budgets');

    try {
      // Obter histórico dos últimos 3 meses
      final expenses = _getAllExpenses();
      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);

      final recentExpenses = expenses.where((e) => e.date.isAfter(threeMonthsAgo)).toList();

      if (recentExpenses.isEmpty) {
        AppLogger.debug(FeatureTag.goals, 'Sem histórico suficiente para sugestões');
        return {};
      }

      // Agrupar por categoria e calcular média mensal
      final categoryTotals = <String, List<double>>{};

      for (final expense in recentExpenses) {
        final monthKey = '${expense.date.year}-${expense.date.month}';
        final categoryId = expense.categoryId;

        categoryTotals.putIfAbsent(categoryId, () => []);

        // Agregar por mês
        // (simplificado - soma todas do período e divide por 3)
      }

      // Calcular médias por categoria
      final suggestions = <String, double>{};
      final categoryGroups = <String, double>{};

      for (final expense in recentExpenses) {
        categoryGroups[expense.categoryId] =
            (categoryGroups[expense.categoryId] ?? 0) + expense.amount;
      }

      // Calcular meses no período
      final monthsInPeriod = _monthsBetween(threeMonthsAgo, now);

      for (final entry in categoryGroups.entries) {
        // Média mensal + 10% de margem
        final monthlyAverage = entry.value / monthsInPeriod;
        suggestions[entry.key] = (monthlyAverage * 1.1).roundToDouble();
      }

      AppLogger.completeOp(opId, data: {
        'categories_count': suggestions.length,
        'months_analyzed': monthsInPeriod,
      });

      return suggestions;
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao calcular sugestões', exception: e);
      return {};
    }
  }

  /// Verifica se deve mostrar alerta proativo na home
  Future<List<GoalAlert>> getProactiveAlerts() async {
    final context = await getContext();
    return context.alerts.where((a) =>
        a.type == GoalAlertType.exceeded ||
        a.type == GoalAlertType.warning).toList();
  }

  /// Invalida o cache forçando refresh na próxima chamada
  void invalidateCache() {
    _cachedContext = null;
    _lastUpdate = null;
    AppLogger.debug(FeatureTag.goals, 'Cache de contexto invalidado');
  }

  // ============================================
  // MÉTODOS PRIVADOS - BUSCA DE DADOS
  // ============================================

  Future<OnboardingProfileModel?> _getUserProfile() async {
    try {
      if (Get.isRegistered<OnboardingService>()) {
        final service = Get.find<OnboardingService>();
        return await service.getOnboardingProfile();
      }
    } catch (e) {
      AppLogger.warning(FeatureTag.goals, 'Erro ao obter perfil de onboarding', data: {'error': e.toString()});
    }
    return null;
  }

  Future<FinancialProfile?> _getFinancialProfile() async {
    try {
      if (Get.isRegistered<FinancialProfileService>()) {
        final service = Get.find<FinancialProfileService>();
        return await service.getFinancialProfile();
      }
    } catch (e) {
      AppLogger.warning(FeatureTag.goals, 'Erro ao obter perfil financeiro', data: {'error': e.toString()});
    }
    return null;
  }

  Future<List<FinancialGoal>> _getGoals() async {
    try {
      if (Get.isRegistered<FinancialGoalsController>()) {
        final controller = Get.find<FinancialGoalsController>();
        return await controller.loadCurrentMonthGoals();
      }
    } catch (e) {
      AppLogger.warning(FeatureTag.goals, 'Erro ao obter metas', data: {'error': e.toString()});
    }
    return [];
  }

  List<Expense> _getCurrentMonthExpenses() {
    try {
      if (Get.isRegistered<ExpenseController>()) {
        final controller = Get.find<ExpenseController>();
        final now = DateTime.now();

        return controller.expenses
            .where((e) => e.date.year == now.year && e.date.month == now.month)
            .toList();
      }
    } catch (e) {
      AppLogger.warning(FeatureTag.expenses, 'Erro ao obter despesas do mês', data: {'error': e.toString()});
    }
    return [];
  }

  List<Expense> _getAllExpenses() {
    try {
      if (Get.isRegistered<ExpenseController>()) {
        final controller = Get.find<ExpenseController>();
        return controller.expenses;
      }
    } catch (e) {
      AppLogger.warning(FeatureTag.expenses, 'Erro ao obter todas despesas', data: {'error': e.toString()});
    }
    return [];
  }

  /// Obtém dados de investimentos (mês atual e histórico)
  Map<String, dynamic> _getInvestmentData() {
    try {
      if (Get.isRegistered<InvestmentController>()) {
        final controller = Get.find<InvestmentController>();
        return {
          'currentMonth': controller.currentMonthInvestments.toList(),
          'all': controller.investments.toList(),
        };
      }
    } catch (e) {
      AppLogger.warning(FeatureTag.expenses, 'Erro ao obter investimentos', data: {'error': e.toString()});
    }
    return {
      'currentMonth': <Investment>[],
      'all': <Investment>[],
    };
  }

  String _getCategoryName(String categoryId) {
    try {
      // Buscar nome da categoria
      // Por simplicidade, usar mapeamento básico
      final defaultCategories = ExpenseCategory.defaultCategories;
      final category = defaultCategories.firstWhereOrNull((c) => c.id == categoryId);
      return category?.name ?? 'Outros';
    } catch (e) {
      return 'Outros';
    }
  }

  List<GoalAlert> _generateAlerts(
    List<FinancialGoal> goals,
    Map<String, double> categorySpending,
  ) {
    final alerts = <GoalAlert>[];

    for (final goal in goals.where((g) => g.isActive)) {
      if (goal.isExceeded) {
        final excess = goal.currentSpent - goal.monthlyLimit;
        alerts.add(GoalAlert(
          categoryId: goal.categoryId,
          categoryName: goal.categoryName,
          type: GoalAlertType.exceeded,
          message: '${goal.categoryName} excedeu R\$ ${excess.toStringAsFixed(2)} do limite',
          value: excess,
          emoji: '🚨',
        ));
      } else if (goal.status == FinancialGoalStatus.warning) {
        alerts.add(GoalAlert(
          categoryId: goal.categoryId,
          categoryName: goal.categoryName,
          type: GoalAlertType.warning,
          message: '${goal.categoryName} está em ${(goal.progressPercentage * 100).round()}% do limite',
          value: goal.remainingAmount,
          emoji: '⚠️',
        ));
      }
    }

    // Ordenar por severidade
    alerts.sort((a, b) {
      final typeOrder = {
        GoalAlertType.exceeded: 0,
        GoalAlertType.warning: 1,
        GoalAlertType.nearLimit: 2,
        GoalAlertType.investmentBelowGoal: 3,
        GoalAlertType.noGoal: 4,
        GoalAlertType.investmentOnTrack: 5,
      };
      return typeOrder[a.type]!.compareTo(typeOrder[b.type]!);
    });

    return alerts;
  }

  /// Adiciona alertas relacionados à meta de investimento
  void _addInvestmentAlerts(
    List<GoalAlert> alerts,
    double investmentGoal,
    double totalInvestedThisMonth,
    int daysRemaining,
  ) {
    if (investmentGoal <= 0) return;
    
    final progress = totalInvestedThisMonth / investmentGoal;
    final remaining = investmentGoal - totalInvestedThisMonth;
    
    // Calcular progresso esperado baseado no dia do mês
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;
    final expectedProgress = daysPassed / daysInMonth;
    
    if (progress >= 1.0) {
      // Meta de investimento atingida!
      alerts.add(GoalAlert(
        categoryId: 'investment_goal',
        categoryName: 'Meta de Investimento',
        type: GoalAlertType.investmentOnTrack,
        message: '🎉 Meta de investimento atingida! R\$ ${totalInvestedThisMonth.toStringAsFixed(2)} investidos',
        value: totalInvestedThisMonth,
        emoji: '🎉',
      ));
    } else if (progress < expectedProgress * 0.5 && daysRemaining <= 15) {
      // Progresso muito abaixo do esperado e já passou metade do mês
      alerts.add(GoalAlert(
        categoryId: 'investment_goal',
        categoryName: 'Meta de Investimento',
        type: GoalAlertType.investmentBelowGoal,
        message: 'Investimento abaixo da meta! Faltam R\$ ${remaining.toStringAsFixed(2)}',
        value: remaining,
        emoji: '📉',
      ));
    } else if (progress < expectedProgress && daysRemaining <= 10) {
      // Progresso abaixo do esperado nos últimos 10 dias
      alerts.add(GoalAlert(
        categoryId: 'investment_goal',
        categoryName: 'Meta de Investimento',
        type: GoalAlertType.warning,
        message: 'Ainda faltam R\$ ${remaining.toStringAsFixed(2)} para atingir a meta de investimento',
        value: remaining,
        emoji: '💰',
      ));
    }
  }

  int _monthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + end.month - start.month + 1;
  }
}

