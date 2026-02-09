import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/ads_service.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/financial_profile.dart';
import '../../domain/entities/financial_goal.dart';
import '../../domain/entities/financial_insight.dart';
import '../../domain/usecases/get_expenses_usecase.dart';
import '../../core/expense_filters.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/repositories/financial_goals_repository.dart';
import '../../data/services/financial_profile_service.dart';
import '../../data/services/financial_insights_service.dart';
import '../../data/services/enhanced_insights_generator.dart';
import '../../data/services/quick_analysis_service.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../onboarding/data/services/onboarding_service.dart';
import '../../../onboarding/data/services/ai_insights_service.dart';
import '../../../monetization/domain/entities/usage_limit.dart';
import '../../../monetization/domain/entities/feature_unlock.dart';
import '../../../monetization/data/services/usage_limit_service.dart';
import '../widgets/excess_alert_card.dart';

/// Logger helper para o EnhancedReportsController
void _logController(String message, {String level = 'INFO'}) {
  final prefix = switch (level) {
    'ERROR' => '❌ [ReportsController]',
    'WARNING' => '⚠️ [ReportsController]',
    'SUCCESS' => '✅ [ReportsController]',
    'LOADING' => '⏳ [ReportsController]',
    'DATA' => '📊 [ReportsController]',
    'UI' => '🖥️ [ReportsController]',
    _ => '📋 [ReportsController]',
  };
  debugPrint('$prefix $message');
}

class EnhancedReportsController extends GetxController {
  // Services
  late final GetExpensesUseCase _getExpensesUseCase;
  late final GetCategoriesUseCase _getCategoriesUseCase;
  late final FinancialProfileService _profileService;
  late final FinancialGoalsRepository _goalsRepository;
  late final FinancialInsightsService _insightsService;
  late final EnhancedInsightsGenerator _enhancedInsightsGenerator;
  late final AuthService _authService;
  late final OnboardingService _onboardingService;
  late final AIInsightsService _aiInsightsService;
  late final QuickAnalysisService _quickAnalysisService;
  
  // Monetization services
  UsageLimitService? _usageLimitService;
  AdsService? _adsService;

  // Observable state
  final isLoading = false.obs;
  final isLoadingAnalysis = false.obs;
  final selectedPeriod = 'month'.obs; // month, week, year
  final selectedDate = DateTime.now().obs;
  
  // Monetization state
  final Rx<UsageLimit?> insightsUsageLimit = Rx<UsageLimit?>(null);
  final Rx<FeatureUnlock?> insightsActiveUnlock = Rx<FeatureUnlock?>(null);
  final RxBool isInsightsLimitReached = false.obs;
  final RxBool hasUnlimitedInsights = false.obs;
  final RxBool showInsightsLimitDialog = false.obs;

  // Data
  final expenses = <Expense>[].obs;
  final categories = <ExpenseCategory>[].obs;
  final financialProfile = Rxn<FinancialProfile>();
  final financialGoals = <FinancialGoal>[].obs;
  final insights = <FinancialInsight>[].obs;

  // Quick Analysis Data
  final dominantCategories = <DominantCategoryData>[].obs;
  final exceededCategories = <ExcessCategoryData>[].obs;
  final warningCategories = <ExcessCategoryData>[].obs;
  final aiAnalysisText = ''.obs;
  final aiSuggestions = <String>[].obs;
  final quickAnalysisResult = Rxn<QuickAnalysisResult>();

  // Computed values
  final totalSpent = 0.0.obs;
  final budgetUsed = 0.0.obs;
  final budgetRemaining = 0.0.obs;
  final categorySpending = <String, double>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _logController('════════════════════════════════════════════════════════════════');
    _logController('INICIALIZANDO EnhancedReportsController', level: 'LOADING');
    _logController('════════════════════════════════════════════════════════════════');
    _initializeDependencies();
    loadReportData();
  }

  void _initializeDependencies() {
    _logController('🔧 Inicializando dependências...', level: 'LOADING');
    
    try {
      _getExpensesUseCase = Get.find<GetExpensesUseCase>();
      _logController('   ✓ GetExpensesUseCase', level: 'SUCCESS');
    } catch (e) {
      _logController('   ✗ GetExpensesUseCase: $e', level: 'ERROR');
    }
    
    try {
      _getCategoriesUseCase = Get.find<GetCategoriesUseCase>();
      _logController('   ✓ GetCategoriesUseCase', level: 'SUCCESS');
    } catch (e) {
      _logController('   ✗ GetCategoriesUseCase: $e', level: 'ERROR');
    }
    
    try {
      _profileService = Get.find<FinancialProfileService>();
      _logController('   ✓ FinancialProfileService', level: 'SUCCESS');
    } catch (e) {
      _logController('   ✗ FinancialProfileService: $e', level: 'ERROR');
    }
    
    try {
      _goalsRepository = Get.find<FinancialGoalsRepository>();
      _logController('   ✓ FinancialGoalsRepository', level: 'SUCCESS');
    } catch (e) {
      _logController('   ✗ FinancialGoalsRepository: $e', level: 'ERROR');
    }
    
    try {
      _insightsService = Get.find<FinancialInsightsService>();
      _logController('   ✓ FinancialInsightsService', level: 'SUCCESS');
    } catch (e) {
      _logController('   ✗ FinancialInsightsService: $e', level: 'ERROR');
    }
    
    try {
      _enhancedInsightsGenerator = Get.find<EnhancedInsightsGenerator>();
      _logController('   ✓ EnhancedInsightsGenerator', level: 'SUCCESS');
    } catch (e) {
      _logController('   ✗ EnhancedInsightsGenerator: $e', level: 'ERROR');
    }
    
    try {
      _authService = Get.find<AuthService>();
      _logController('   ✓ AuthService', level: 'SUCCESS');
    } catch (e) {
      _logController('   ✗ AuthService: $e', level: 'ERROR');
    }
    
    try {
      _onboardingService = Get.find<OnboardingService>();
      _logController('   ✓ OnboardingService', level: 'SUCCESS');
    } catch (e) {
      _logController('   ✗ OnboardingService: $e', level: 'ERROR');
    }
    
    try {
      _aiInsightsService = Get.find<AIInsightsService>();
      _logController('   ✓ AIInsightsService', level: 'SUCCESS');
    } catch (e) {
      _logController('   ✗ AIInsightsService: $e', level: 'ERROR');
    }
    
    // Inicializar QuickAnalysisService se não existir
    if (!Get.isRegistered<QuickAnalysisService>()) {
      _logController('   ⚡ Registrando QuickAnalysisService...', level: 'LOADING');
      Get.put(QuickAnalysisService());
    }
    _quickAnalysisService = Get.find<QuickAnalysisService>();
    _logController('   ✓ QuickAnalysisService', level: 'SUCCESS');
    
    // Inicializar serviços de monetização
    _initializeMonetizationServices();
    
    _logController('🔧 Todas as dependências inicializadas!', level: 'SUCCESS');
  }
  
  /// Inicializa serviços de monetização
  void _initializeMonetizationServices() {
    _logController('💰 Inicializando serviços de monetização...', level: 'LOADING');
    
    try {
      if (Get.isRegistered<UsageLimitService>()) {
        _usageLimitService = Get.find<UsageLimitService>();
        _logController('   ✓ UsageLimitService', level: 'SUCCESS');
      }
    } catch (e) {
      _logController('   ✗ UsageLimitService: $e', level: 'WARNING');
    }
    
    try {
      if (Get.isRegistered<AdsService>()) {
        _adsService = Get.find<AdsService>();
        _logController('   ✓ AdsService', level: 'SUCCESS');
      }
    } catch (e) {
      _logController('   ✗ AdsService: $e', level: 'WARNING');
    }
    
    // Carregar estado inicial de uso
    _loadInsightsUsageState();
  }
  
  /// Carrega estado de uso do recurso de Insights IA
  Future<void> _loadInsightsUsageState() async {
    if (_usageLimitService == null) return;
    
    try {
      // Verifica desbloqueio ativo
      final unlock = _usageLimitService!.getActiveUnlock(FeatureType.aiInsights);
      insightsActiveUnlock.value = unlock;
      hasUnlimitedInsights.value = unlock != null && unlock.isActive;
      
      // Obtém limite atual
      final limit = _usageLimitService!.getLimit(FeatureType.aiInsights);
      insightsUsageLimit.value = limit;
      isInsightsLimitReached.value = limit?.isLimitReached ?? false;
      
      _logController('💰 Estado de uso de Insights carregado', level: 'DATA');
      _logController('   - Desbloqueio ativo: ${hasUnlimitedInsights.value}', level: 'DATA');
      _logController('   - Limite atingido: ${isInsightsLimitReached.value}', level: 'DATA');
    } catch (e) {
      _logController('   ✗ Erro ao carregar estado de uso: $e', level: 'WARNING');
    }
  }
  
  /// Verifica se pode gerar insights (baseado no limite)
  Future<bool> canGenerateInsightsWithLimit() async {
    if (_usageLimitService == null) return true;
    
    try {
      final result = await _usageLimitService!.checkUsage(FeatureType.aiInsights);
      
      hasUnlimitedInsights.value = result.hasUnlock;
      insightsActiveUnlock.value = result.activeUnlock;
      isInsightsLimitReached.value = !result.canUse;
      
      if (!result.canUse) {
        _logController('⚠️ Limite de Insights IA atingido', level: 'WARNING');
      }
      
      return result.canUse;
    } catch (e) {
      _logController('❌ Erro ao verificar limite de insights: $e', level: 'ERROR');
      return true; // Em caso de erro, permite para não bloquear
    }
  }
  
  /// Registra uso de geração de insights
  Future<void> _recordInsightsUsage() async {
    if (_usageLimitService == null) return;
    
    try {
      await _usageLimitService!.recordUsage(FeatureType.aiInsights);
      await _loadInsightsUsageState();
      _logController('📊 Uso de Insights IA registrado', level: 'SUCCESS');
    } catch (e) {
      _logController('⚠️ Erro ao registrar uso de insights: $e', level: 'WARNING');
    }
  }
  
  /// Mostra anúncio para desbloquear Insights IA por 24h
  Future<bool> showAdToUnlockInsights() async {
    if (_adsService == null) {
      _logController('⚠️ AdsService não disponível', level: 'WARNING');
      return false;
    }
    
    _logController('🎬 Iniciando desbloqueio de Insights via anúncio...', level: 'LOADING');
    
    final result = await _adsService!.showRewardedAdForFeature(
      featureType: FeatureType.aiInsights,
      durationHours: 24,
    );
    
    if (result.success) {
      await _loadInsightsUsageState();
      
      _logController('🎉 Insights IA desbloqueado por 24h!', level: 'SUCCESS');
      
      Get.snackbar(
        '🎉 Insights Desbloqueados!',
        'Você tem 24 horas de insights ilimitados com IA',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.colorSuccess,
        colorText: AppColors.colorTextOnDark,
        duration: const Duration(seconds: 4),
      );
      
      // Recarrega relatório para gerar novos insights
      await loadReportData();
      
      return true;
    } else {
      _logController('❌ Falha ao desbloquear: ${result.error}', level: 'WARNING');
      
      Get.snackbar(
        'Não foi possível desbloquear',
        result.error ?? 'Tente novamente em alguns segundos',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorWarning,
        colorText: AppColors.colorTextPrimary,
      );
      
      return false;
    }
  }
  
  /// Texto de uso para exibição na UI
  String get insightsUsageDisplayText {
    if (hasUnlimitedInsights.value && insightsActiveUnlock.value != null) {
      return '✨ Ilimitado (${insightsActiveUnlock.value!.timeRemainingFormatted})';
    }
    
    final limit = insightsUsageLimit.value;
    if (limit == null) return '';
    
    return '${limit.remainingToday}/${limit.dailyLimit}';
  }
  
  /// Indica se deve mostrar aviso de limite próximo
  bool get shouldShowInsightsLimitWarning {
    if (hasUnlimitedInsights.value) return false;
    final limit = insightsUsageLimit.value;
    return limit != null && (limit.isLastUse || limit.isNearLimit);
  }
  
  /// Reseta flag do dialog de limite
  void dismissInsightsLimitDialog() {
    showInsightsLimitDialog.value = false;
  }

  Future<void> loadReportData() async {
    _logController('════════════════════════════════════════════════════════════════');
    _logController('CARREGANDO DADOS DO RELATÓRIO', level: 'LOADING');
    _logController('════════════════════════════════════════════════════════════════');
    
    final stopwatch = Stopwatch()..start();
    
    try {
      isLoading.value = true;
      _logController('⏳ isLoading = true', level: 'UI');

      // Carregar dados em paralelo
      _logController('📥 Carregando dados em paralelo...', level: 'LOADING');
      await Future.wait([
        _loadExpenses(),
        _loadCategories(),
        _loadFinancialProfile(),
      ]);
      _logController('📥 Dados básicos carregados em ${stopwatch.elapsedMilliseconds}ms', level: 'SUCCESS');

      // Carregar metas baseadas no perfil
      _logController('📥 Carregando metas financeiras...', level: 'LOADING');
      await _loadFinancialGoals();

      // Gerar insights baseados nos dados reais
      _logController('🧠 Gerando insights...', level: 'LOADING');
      _generateInsights();

      // Calcular estatísticas
      _logController('📊 Calculando estatísticas...', level: 'LOADING');
      _calculateStatistics();
      
      // Gerar análise rápida com IA
      _logController('🤖 Gerando análise rápida com IA...', level: 'LOADING');
      _generateQuickAnalysis();
      
      stopwatch.stop();
      _logController('════════════════════════════════════════════════════════════════');
      _logController('RELATÓRIO CARREGADO EM ${stopwatch.elapsedMilliseconds}ms', level: 'SUCCESS');
      _logController('════════════════════════════════════════════════════════════════');

    } catch (e, stack) {
      _logController('════════════════════════════════════════════════════════════════');
      _logController('ERRO AO CARREGAR RELATÓRIO', level: 'ERROR');
      _logController('Erro: $e', level: 'ERROR');
      _logController('Stack: $stack', level: 'ERROR');
      _logController('════════════════════════════════════════════════════════════════');
      
      Get.snackbar(
        'Erro',
        'Erro ao carregar relatório. Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
      _logController('⏳ isLoading = false', level: 'UI');
    }
  }

  Future<void> _loadExpenses() async {
    _logController('📥 _loadExpenses() iniciando...', level: 'LOADING');
    try {
      final period = _getDateRange();
      _logController('   Período: ${period.start} até ${period.end}', level: 'DATA');
      
      final result = await _getExpensesUseCase.getExpensesByDateRange(
        period.start,
        period.end,
      );
      expenses.value = result;
      
      _logController('   ✓ ${result.length} despesas carregadas', level: 'SUCCESS');
      if (result.isNotEmpty) {
        final total = result.fold(0.0, (sum, e) => sum + e.amount);
        _logController('   Total: R\$ ${total.toStringAsFixed(2)}', level: 'DATA');
      }
    } catch (e, stack) {
      _logController('   ✗ Erro ao carregar despesas: $e', level: 'ERROR');
      _logController('   Stack: $stack', level: 'ERROR');
      expenses.value = [];
    }
  }

  Future<void> _loadCategories() async {
    _logController('📥 _loadCategories() iniciando...', level: 'LOADING');
    try {
      final result = await _getCategoriesUseCase.execute();
      categories.value = result;
      _logController('   ✓ ${result.length} categorias carregadas', level: 'SUCCESS');
    } catch (e, stack) {
      _logController('   ✗ Erro ao carregar categorias: $e', level: 'ERROR');
      _logController('   Stack: $stack', level: 'ERROR');
      categories.value = [];
    }
  }

  Future<void> _loadFinancialProfile() async {
    _logController('📥 _loadFinancialProfile() iniciando...', level: 'LOADING');
    try {
      final profile = await _profileService.getFinancialProfile();
      financialProfile.value = profile;
      
      if (profile != null) {
        _logController('   ✓ Perfil carregado:', level: 'SUCCESS');
        _logController('   - Orçamento total: R\$ ${profile.totalBudget.toStringAsFixed(2)}', level: 'DATA');
        _logController('   - Renda mensal: R\$ ${profile.monthlyIncome.toStringAsFixed(2)}', level: 'DATA');
      } else {
        _logController('   ⚠️ Nenhum perfil financeiro encontrado', level: 'WARNING');
      }
    } catch (e, stack) {
      _logController('   ✗ Erro ao carregar perfil financeiro: $e', level: 'ERROR');
      _logController('   Stack: $stack', level: 'ERROR');
      financialProfile.value = null;
    }
  }

  Future<void> _loadFinancialGoals() async {
    _logController('📥 _loadFinancialGoals() iniciando...', level: 'LOADING');
    try {
      final currentMonth = DateTime(selectedDate.value.year, selectedDate.value.month);
      _logController('   Mês de referência: ${currentMonth.month}/${currentMonth.year}', level: 'DATA');
      
      final goals = await _goalsRepository.getGoalsByMonth(currentMonth);
      _logController('   ${goals.length} metas encontradas no repositório', level: 'DATA');
      
      // Atualizar valores gastos nas metas baseado nas despesas reais
      final updatedGoals = <FinancialGoal>[];
      _logController('   Atualizando gastos reais para cada meta...', level: 'LOADING');
      
      for (final goal in goals) {
        final categoryExpenses = expenses.where((e) => e.categoryId == goal.categoryId);
        final totalSpent = categoryExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
        
        // Atualizar meta com valor real gasto
        final updatedGoal = goal.copyWith(
          currentSpent: totalSpent,
          updatedAt: DateTime.now(),
        );
        
        updatedGoals.add(updatedGoal);
        
        final percentage = goal.monthlyLimit > 0 ? (totalSpent / goal.monthlyLimit * 100) : 0.0;
        final status = percentage > 100 ? '🔴' : (percentage > 80 ? '🟡' : '🟢');
        _logController('   $status ${goal.categoryName}: R\$ ${totalSpent.toStringAsFixed(2)}/${goal.monthlyLimit.toStringAsFixed(2)} (${percentage.toStringAsFixed(0)}%)', level: 'DATA');
        
        // Atualizar no repositório se o valor mudou
        if (totalSpent != goal.currentSpent) {
          await _goalsRepository.updateGoalSpentAmount(
            goal.categoryId, 
            currentMonth, 
            totalSpent
          );
        }
      }
      
      financialGoals.value = updatedGoals;
      _logController('   ✓ ${updatedGoals.length} metas carregadas e atualizadas', level: 'SUCCESS');
    } catch (e) {
      print('❌ Erro ao carregar metas financeiras: $e');
      financialGoals.value = [];
    }
  }

  Future<void> _generateInsights() async {
    _logController('────────────────────────────────────────────────────────────────');
    _logController('GERANDO INSIGHTS FINANCEIROS', level: 'LOADING');
    _logController('────────────────────────────────────────────────────────────────');
    
    try {
      // Verificar limite de uso antes de gerar insights com IA
      final canGenerate = await canGenerateInsightsWithLimit();
      
      if (!canGenerate) {
        _logController('⚠️ Limite de Insights atingido - usando sistema local', level: 'WARNING');
        showInsightsLimitDialog.value = true;
        
        // Usa sistema local (sem API de IA) quando limite atingido
        await _generateLocalInsights();
        return;
      }
      
      // Primeiro, tenta obter o perfil do onboarding
      _logController('🔍 Verificando perfil de onboarding...', level: 'LOADING');
      final onboardingProfile = await _onboardingService.getOnboardingProfile();
      
      if (onboardingProfile != null) {
        // Se tem perfil do onboarding, usa o sistema de IA híbrido
        _logController('📋 Perfil de onboarding encontrado!', level: 'SUCCESS');
        _logController('🤖 Usando sistema de IA HÍBRIDO (onboarding + despesas)', level: 'LOADING');
        
        final aiInsights = await _aiInsightsService.generateHybridInsights(
          onboardingProfile,
          expenses,
          categories,
        );
        insights.value = aiInsights;
        
        // Registrar uso de insights IA (apenas se usou API)
        await _recordInsightsUsage();
        
        _logController('✓ ${aiInsights.length} insights híbridos gerados', level: 'SUCCESS');
        for (var i = 0; i < aiInsights.take(3).length; i++) {
          _logController('   ${i + 1}. ${aiInsights[i].title}', level: 'DATA');
        }
        return;
      }
      
      _logController('📋 Perfil de onboarding não encontrado', level: 'WARNING');
      
      // Sistema aprimorado baseado em metas financeiras (local, não conta no limite)
      await _generateLocalInsights();
      
      _logController('────────────────────────────────────────────────────────────────');
    } catch (e, stack) {
      _logController('────────────────────────────────────────────────────────────────');
      _logController('ERRO AO GERAR INSIGHTS', level: 'ERROR');
      _logController('Erro: $e', level: 'ERROR');
      _logController('Stack: $stack', level: 'ERROR');
      _logController('────────────────────────────────────────────────────────────────');
      insights.value = [];
    }
  }
  
  /// Gera insights usando sistema local (sem API de IA)
  Future<void> _generateLocalInsights() async {
    // Sistema aprimorado baseado em metas financeiras
    if (financialGoals.isNotEmpty) {
      _logController('🎯 Usando sistema APRIMORADO baseado em ${financialGoals.length} metas financeiras', level: 'LOADING');
      
      final enhancedInsights = _enhancedInsightsGenerator.generateSmartInsights(
        goals: financialGoals,
        expenses: expenses,
        categories: categories,
        referenceDate: selectedDate.value,
      );
      
      insights.value = enhancedInsights;
      _logController('✓ ${enhancedInsights.length} insights inteligentes gerados', level: 'SUCCESS');
      for (var i = 0; i < enhancedInsights.take(3).length; i++) {
        _logController('   ${i + 1}. ${enhancedInsights[i].title}', level: 'DATA');
      }
      return;
    }
    
    // Fallback para o sistema antigo se não tem metas
    _logController('⚠️ Nenhuma meta financeira encontrada', level: 'WARNING');
    
    if (financialProfile.value == null) {
      insights.value = [];
      _logController('⚠️ Nenhum perfil financeiro ou metas encontradas - sem insights', level: 'WARNING');
      return;
    }

    // Sistema antigo como último recurso
    _logController('📦 Usando sistema LEGADO de insights (baseado em perfil)', level: 'LOADING');
    
    final previousMonth = DateTime(selectedDate.value.year, selectedDate.value.month - 1);
    final previousPeriodStart = DateTime(previousMonth.year, previousMonth.month, 1);
    final previousPeriodEnd = DateTime(previousMonth.year, previousMonth.month + 1, 0);
    _logController('   Carregando despesas do mês anterior: ${previousMonth.month}/${previousMonth.year}', level: 'DATA');

    final previousExpenses = await _getExpensesUseCase.getExpensesByDateRange(
      previousPeriodStart,
      previousPeriodEnd,
    );
    _logController('   ${previousExpenses.length} despesas do mês anterior', level: 'DATA');

    final generatedInsights = _insightsService.generateInsights(
      profile: financialProfile.value!,
      goals: financialGoals,
      currentMonthExpenses: expenses,
      previousMonthExpenses: previousExpenses,
      categories: categories,
    );

    insights.value = generatedInsights;
    _logController('✓ ${generatedInsights.length} insights gerados pelo sistema legado', level: 'SUCCESS');
    for (var i = 0; i < generatedInsights.take(3).length; i++) {
      _logController('   ${i + 1}. ${generatedInsights[i].title}', level: 'DATA');
    }
  }

  void _calculateStatistics() {
    _logController('────────────────────────────────────────────────────────────────');
    _logController('CALCULANDO ESTATÍSTICAS', level: 'LOADING');
    _logController('────────────────────────────────────────────────────────────────');
    
    // Filtrar investimentos das despesas (investimentos não são despesas)
    final expensesWithoutInvestments = ExpenseFilters.excludeInvestments(expenses);
    if (expenses.length != expensesWithoutInvestments.length) {
      final investmentCount = expenses.length - expensesWithoutInvestments.length;
      _logController('⚠️ $investmentCount investimento(s) excluído(s) dos cálculos de despesas', level: 'WARNING');
    }
    
    // Calcular total gasto (sem investimentos)
    totalSpent.value = expensesWithoutInvestments.fold(0.0, (sum, expense) => sum + expense.amount);
    _logController('💰 Total gasto: R\$ ${totalSpent.value.toStringAsFixed(2)}', level: 'DATA');

    // Calcular gastos por categoria (sem investimentos)
    final categoryMap = <String, double>{};
    for (final expense in expensesWithoutInvestments) {
      categoryMap[expense.categoryId] = (categoryMap[expense.categoryId] ?? 0) + expense.amount;
    }
    categorySpending.value = categoryMap;
    _logController('📊 Gastos distribuídos em ${categoryMap.length} categorias', level: 'DATA');

    // Calcular orçamento usado e restante
    if (financialProfile.value != null) {
      final profile = financialProfile.value!;
      budgetUsed.value = totalSpent.value;
      budgetRemaining.value = profile.totalBudget - totalSpent.value;
      
      final percentUsed = profile.totalBudget > 0 
          ? (totalSpent.value / profile.totalBudget * 100) 
          : 0.0;
      
      _logController('📈 Orçamento:', level: 'DATA');
      _logController('   - Total: R\$ ${profile.totalBudget.toStringAsFixed(2)}', level: 'DATA');
      _logController('   - Usado: R\$ ${budgetUsed.value.toStringAsFixed(2)} (${percentUsed.toStringAsFixed(1)}%)', level: 'DATA');
      _logController('   - Restante: R\$ ${budgetRemaining.value.toStringAsFixed(2)}', level: 'DATA');
    } else {
      _logController('⚠️ Sem perfil financeiro - estatísticas de orçamento não calculadas', level: 'WARNING');
    }
    
    _logController('────────────────────────────────────────────────────────────────');
  }

  DateTimeRange _getDateRange() {
    final date = selectedDate.value;
    
    switch (selectedPeriod.value) {
      case 'week':
        final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
        return DateTimeRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          end: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + 7),
        );
      
      case 'year':
        return DateTimeRange(
          start: DateTime(date.year, 1, 1),
          end: DateTime(date.year + 1, 1, 1),
        );
      
      case 'month':
      default:
        return DateTimeRange(
          start: DateTime(date.year, date.month, 1),
          end: DateTime(date.year, date.month + 1, 1),
        );
    }
  }

  // Métodos para interação com a UI
  void changePeriod(String period) {
    selectedPeriod.value = period;
    loadReportData();
  }

  void changeDate(DateTime date) {
    selectedDate.value = date;
    loadReportData();
  }

  void previousPeriod() {
    switch (selectedPeriod.value) {
      case 'week':
        selectedDate.value = selectedDate.value.subtract(const Duration(days: 7));
        break;
      case 'year':
        selectedDate.value = DateTime(selectedDate.value.year - 1, selectedDate.value.month);
        break;
      case 'month':
      default:
        selectedDate.value = DateTime(selectedDate.value.year, selectedDate.value.month - 1);
        break;
    }
    loadReportData();
  }

  void nextPeriod() {
    switch (selectedPeriod.value) {
      case 'week':
        selectedDate.value = selectedDate.value.add(const Duration(days: 7));
        break;
      case 'year':
        selectedDate.value = DateTime(selectedDate.value.year + 1, selectedDate.value.month);
        break;
      case 'month':
      default:
        selectedDate.value = DateTime(selectedDate.value.year, selectedDate.value.month + 1);
        break;
    }
    loadReportData();
  }

  Future<void> refreshReports() async {
    await loadReportData();
  }

  // Getters para a UI
  String get periodTitle {
    final date = selectedDate.value;
    switch (selectedPeriod.value) {
      case 'week':
        return 'Semana de ${date.day}/${date.month}/${date.year}';
      case 'year':
        return 'Ano ${date.year}';
      case 'month':
      default:
        return '${_getMonthName(date.month)} ${date.year}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return months[month - 1];
  }

  double getBudgetProgress() {
    if (financialProfile.value == null || financialProfile.value!.totalBudget <= 0) {
      return 0.0;
    }
    return (totalSpent.value / financialProfile.value!.totalBudget).clamp(0.0, 1.0);
  }

  Color getBudgetProgressColor() {
    final progress = getBudgetProgress();
    if (progress >= 1.0) return AppColors.error;
    if (progress >= 0.8) return AppColors.warning;
    if (progress >= 0.5) return AppColors.accent;
    return AppColors.success;
  }

  List<FinancialGoal> getGoalsByStatus(FinancialGoalStatus status) {
    return financialGoals.where((goal) => goal.status == status).toList();
  }

  /// Busca categoria por ID com fallback para IDs sem sufixo do usuário
  /// 
  /// Devido ao formato de ID das categorias (ex: 'alimentacao_userId123'),
  /// esta função tenta múltiplas estratégias de matching:
  /// 1. Match exato por ID
  /// 2. Match onde o ID da categoria começa com o categoryId buscado
  /// 3. Match onde o categoryId começa com o ID base da categoria
  ExpenseCategory? getCategoryById(String categoryId) {
    if (categoryId.isEmpty) return null;
    
    // 1. Tentar match exato
    final exactMatch = categories.firstWhereOrNull((cat) => cat.id == categoryId);
    if (exactMatch != null) return exactMatch;
    
    // 2. Tentar match onde o ID da categoria começa com o categoryId buscado
    // Ex: categoryId = 'alimentacao', categoria.id = 'alimentacao_user123'
    final startsWithMatch = categories.firstWhereOrNull(
      (cat) => cat.id.startsWith('${categoryId}_') || cat.id == categoryId
    );
    if (startsWithMatch != null) return startsWithMatch;
    
    // 3. Tentar match onde o categoryId começa com o ID base da categoria
    // Ex: categoryId = 'alimentacao_user123', categoria.id = 'alimentacao'
    final reverseMatch = categories.firstWhereOrNull(
      (cat) => categoryId.startsWith('${cat.id}_')
    );
    if (reverseMatch != null) return reverseMatch;
    
    // 4. Como último recurso, tentar extrair o ID base e fazer match
    // Ex: categoryId = 'alimentacao_user123' -> base = 'alimentacao'
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
  /// Ex: 'alimentacao_user123' -> 'alimentacao'
  String _extractBaseCategoryId(String categoryId) {
    // Os IDs de categorias padrão são: alimentacao, transporte, saude, contas, lazer, 
    // casa, educacao, roupas, tecnologia, pets, outros, investimentos
    final defaultIds = [
      'alimentacao', 'transporte', 'saude', 'contas', 'lazer',
      'casa', 'educacao', 'roupas', 'tecnologia', 'pets', 'outros', 'investimentos'
    ];
    
    for (final baseId in defaultIds) {
      if (categoryId == baseId || categoryId.startsWith('${baseId}_')) {
        return baseId;
      }
    }
    
    // Se não é uma categoria padrão, retorna o próprio ID
    return categoryId;
  }

  bool get hasFinancialProfile => financialProfile.value != null;
  
  bool get hasGoals => financialGoals.isNotEmpty;
  
  bool get hasInsights => insights.isNotEmpty;

  String get noDataMessage {
    if (expenses.isEmpty) {
      return 'Adicione alguns gastos para começar a receber insights personalizados baseados no seu perfil!';
    }
    if (!hasFinancialProfile) {
      return 'Configure seu perfil financeiro para ver insights mais detalhados';
    }
    if (!hasGoals) {
      return 'Defina suas metas financeiras para acompanhar seu progresso';
    }
    return 'Dados carregados com sucesso';
  }

  // ============================================================================
  // QUICK ANALYSIS - Novos métodos para análise rápida
  // ============================================================================

  /// Gerar análise rápida com texto em linguagem natural
  void _generateQuickAnalysis() {
    _logController('────────────────────────────────────────────────────────────────');
    _logController('GERANDO ANÁLISE RÁPIDA COM IA', level: 'LOADING');
    _logController('────────────────────────────────────────────────────────────────');
    
    try {
      isLoadingAnalysis.value = true;
      _logController('⏳ isLoadingAnalysis = true', level: 'UI');
      
      _logController('📤 Enviando dados para QuickAnalysisService:', level: 'DATA');
      _logController('   - Expenses: ${expenses.length}', level: 'DATA');
      _logController('   - Categories: ${categories.length}', level: 'DATA');
      _logController('   - Goals: ${financialGoals.length}', level: 'DATA');
      _logController('   - Profile: ${financialProfile.value != null}', level: 'DATA');
      _logController('   - Date: ${selectedDate.value}', level: 'DATA');
      
      // Gerar resultado da análise
      final result = _quickAnalysisService.generateMonthAnalysis(
        expenses: expenses,
        categories: categories,
        goals: financialGoals,
        profile: financialProfile.value,
        referenceDate: selectedDate.value,
      );
      
      _logController('📥 Resultado recebido do QuickAnalysisService:', level: 'DATA');
      _logController('   - Total gasto: R\$ ${result.totalSpent.toStringAsFixed(2)}', level: 'DATA');
      _logController('   - Orçamento: R\$ ${result.budget.toStringAsFixed(2)}', level: 'DATA');
      _logController('   - Percentual usado: ${result.percentageUsed.toStringAsFixed(1)}%', level: 'DATA');
      _logController('   - Categorias dominantes: ${result.dominantCategories.length}', level: 'DATA');
      _logController('   - Metas excedidas: ${result.exceededGoals.length}', level: 'DATA');
      _logController('   - Metas em alerta: ${result.warningGoals.length}', level: 'DATA');
      _logController('   - Texto IA: ${result.aiSummaryText.length} chars', level: 'DATA');
      _logController('   - Sugestões: ${result.suggestions.length}', level: 'DATA');
      
      quickAnalysisResult.value = result;
      dominantCategories.value = result.dominantCategories;
      aiAnalysisText.value = result.aiSummaryText;
      aiSuggestions.value = result.suggestions;
      
      _logController('🔄 Atualizando estados observáveis...', level: 'UI');
      
      // Converter metas excedidas para ExcessCategoryData
      _updateExceededCategories();
      
      _logController('────────────────────────────────────────────────────────────────');
      _logController('ANÁLISE RÁPIDA CONCLUÍDA', level: 'SUCCESS');
      _logController('────────────────────────────────────────────────────────────────');
    } catch (e, stack) {
      _logController('────────────────────────────────────────────────────────────────');
      _logController('ERRO NA ANÁLISE RÁPIDA', level: 'ERROR');
      _logController('Erro: $e', level: 'ERROR');
      _logController('Stack: $stack', level: 'ERROR');
      _logController('────────────────────────────────────────────────────────────────');
      aiAnalysisText.value = 'Não foi possível gerar a análise. Tente novamente.';
    } finally {
      isLoadingAnalysis.value = false;
      _logController('⏳ isLoadingAnalysis = false', level: 'UI');
    }
  }

  /// Atualizar lista de categorias com excesso
  void _updateExceededCategories() {
    _logController('🔄 Atualizando categorias com excesso...', level: 'DATA');
    
    final exceeded = <ExcessCategoryData>[];
    final warning = <ExcessCategoryData>[];
    
    _logController('   Processando ${financialGoals.length} metas...', level: 'DATA');
    
    for (final goal in financialGoals) {
      if (!goal.isActive) {
        _logController('   ⏭️ ${goal.categoryName}: inativa, pulando', level: 'DATA');
        continue;
      }
      
      final category = getCategoryById(goal.categoryId);
      if (category == null) {
        _logController('   ⚠️ ${goal.categoryName}: categoria não encontrada', level: 'WARNING');
        continue;
      }
      
      final percentage = goal.progressPercentage * 100;
      
      if (goal.isExceeded) {
        _logController('   🔴 ${goal.categoryName}: EXCEDIDA (${percentage.toStringAsFixed(0)}%)', level: 'WARNING');
        exceeded.add(ExcessCategoryData(
          categoryId: goal.categoryId,
          categoryName: goal.categoryName,
          categoryIcon: category.iconData,
          categoryColor: category.color,
          budgetLimit: goal.monthlyLimit,
          currentSpent: goal.currentSpent,
          percentageUsed: percentage,
        ));
      } else if (goal.status == FinancialGoalStatus.warning) {
        _logController('   🟡 ${goal.categoryName}: ALERTA (${percentage.toStringAsFixed(0)}%)', level: 'WARNING');
        warning.add(ExcessCategoryData(
          categoryId: goal.categoryId,
          categoryName: goal.categoryName,
          categoryIcon: category.iconData,
          categoryColor: category.color,
          budgetLimit: goal.monthlyLimit,
          currentSpent: goal.currentSpent,
          percentageUsed: percentage,
        ));
      } else {
        _logController('   🟢 ${goal.categoryName}: OK (${percentage.toStringAsFixed(0)}%)', level: 'DATA');
      }
    }
    
    exceededCategories.value = exceeded;
    warningCategories.value = warning;
    
    _logController('📊 Resultado: ${exceeded.length} excedidas, ${warning.length} em alerta', level: 'SUCCESS');
  }

  /// Obter todas as categorias com alertas (excedidas + warning)
  List<ExcessCategoryData> get allAlertCategories {
    return [...exceededCategories, ...warningCategories];
  }

  /// Verificar se há alertas de excesso
  bool get hasExcessAlerts => exceededCategories.isNotEmpty || warningCategories.isNotEmpty;

  /// Obter texto de análise de excesso
  String getExcessAnalysisText() {
    return _quickAnalysisService.generateExcessAnalysisText(
      exceededGoals: financialGoals.where((g) => g.isExceeded && g.isActive).toList(),
      warningGoals: financialGoals.where((g) => 
        g.status == FinancialGoalStatus.warning && g.isActive && !g.isExceeded
      ).toList(),
      expenses: expenses,
      categories: categories,
    );
  }

  /// Obter texto de resumo rápido
  String getQuickSummaryText() {
    return _quickAnalysisService.generateQuickSummaryText(
      totalSpent: totalSpent.value,
      budget: financialProfile.value?.totalBudget ?? 
          financialGoals.fold(0.0, (sum, g) => sum + g.monthlyLimit),
      totalTransactions: expenses.length,
      referenceDate: selectedDate.value,
    );
  }

  /// Atualizar análise da IA
  Future<void> refreshAIAnalysis() async {
    isLoadingAnalysis.value = true;
    await Future.delayed(const Duration(milliseconds: 500));
    _generateQuickAnalysis();
  }

  /// Obter orçamento total (do perfil ou soma das metas)
  double get totalBudget {
    if (financialProfile.value != null && financialProfile.value!.totalBudget > 0) {
      return financialProfile.value!.totalBudget;
    }
    return financialGoals.fold(0.0, (sum, g) => sum + g.monthlyLimit);
  }

  /// Verificar se tem orçamento configurado
  bool get hasBudget => totalBudget > 0;

  /// Obter percentual do orçamento usado
  double get budgetPercentageUsed {
    if (totalBudget <= 0) return 0.0;
    return (totalSpent.value / totalBudget * 100);
  }
}
