import 'package:get/get.dart';
import 'dart:io';
import 'dart:convert';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/financial_context_service.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/logging_service.dart';
import '../../domain/entities/multi_period_comparison.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/financial_insight.dart';
import '../../domain/entities/budget_comparison_data.dart';
import '../../domain/entities/enhanced_score.dart';
import '../../domain/entities/gamification_impact.dart';
import '../../domain/usecases/generate_multi_period_comparison_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../data/services/comparison_share_service.dart';
import '../../data/services/smart_comparison_service.dart';
import '../../../auth/data/services/auth_service.dart';

/// Controller para gerenciar comparações multi-período
/// 
/// Agora integra com todos os sistemas do app:
/// - Metas financeiras e orçamentos
/// - Insights contextuais do EnhancedInsightsGenerator
/// - Sistema de gamificação
/// - Navegação acionável para outras telas
class MultiPeriodComparisonController extends GetxController {
  final GenerateMultiPeriodComparisonUseCase _generateComparisonUseCase;
  final GetCategoriesUseCase _getCategoriesUseCase;
  late final AuthService _authService;
  SmartComparisonService? _smartComparisonService;
  FinancialContextService? _financialContextService;

  MultiPeriodComparisonController({
    required GenerateMultiPeriodComparisonUseCase generateComparisonUseCase,
    required GetCategoriesUseCase getCategoriesUseCase,
  })  : _generateComparisonUseCase = generateComparisonUseCase,
        _getCategoriesUseCase = getCategoriesUseCase;

  @override
  void onInit() {
    super.onInit();
    _initializeDependencies();
    _loadCategories();
    loadComparison(ComparisonPeriodType.threeMonths);
  }

  void _initializeDependencies() {
    // #region agent log
    _debugLog('H3', 'multi_period_comparison_controller.dart:46', 'Starting _initializeDependencies');
    // #endregion
    try {
      _authService = Get.find<AuthService>();
      // #region agent log
      _debugLog('H3', 'multi_period_comparison_controller.dart:51', 'Found AuthService');
      // #endregion
    } catch (e) {
      // #region agent log
      _debugLog('H3', 'multi_period_comparison_controller.dart:54', 'FAILED AuthService', {'error': e.toString()});
      // #endregion
      rethrow;
    }
    
    // Dependências opcionais (integração inteligente)
    if (Get.isRegistered<SmartComparisonService>()) {
      _smartComparisonService = Get.find<SmartComparisonService>();
      // #region agent log
      _debugLog('H3', 'multi_period_comparison_controller.dart:62', 'Found SmartComparisonService');
      // #endregion
    } else {
      // #region agent log
      _debugLog('H3', 'multi_period_comparison_controller.dart:65', 'SmartComparisonService NOT registered (optional)');
      // #endregion
    }
    if (Get.isRegistered<FinancialContextService>()) {
      _financialContextService = Get.find<FinancialContextService>();
      // #region agent log
      _debugLog('H3', 'multi_period_comparison_controller.dart:70', 'Found FinancialContextService');
      // #endregion
    } else {
      // #region agent log
      _debugLog('H3', 'multi_period_comparison_controller.dart:73', 'FinancialContextService NOT registered (optional)');
      // #endregion
    }
  }

  // Estados observáveis
  final Rx<MultiPeriodComparison?> currentComparison = Rx<MultiPeriodComparison?>(null);
  final RxList<ExpenseCategory> categories = <ExpenseCategory>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<ComparisonPeriodType> selectedPeriodType = ComparisonPeriodType.threeMonths.obs;
  
  // Estados para animações
  final RxBool showChart = false.obs;
  final RxBool showInsights = false.obs;
  final RxBool showRecommendations = false.obs;
  final RxBool showBudgetComparison = false.obs;
  final RxBool showGamification = false.obs;
  
  // Estados para filtro de categoria
  final RxBool showCategoryFilter = false.obs;
  final RxnString selectedCategoryId = RxnString(null);

  /// Carrega categorias
  Future<void> _loadCategories() async {
    try {
      final result = await _getCategoriesUseCase.execute();
      categories.value = result;
    } catch (e) {
      AppLogger.warning(FeatureTag.expenses, 'Erro ao carregar categorias', data: {'error': e.toString()});
    }
  }

  /// Carrega comparação para um período
  Future<void> loadComparison(ComparisonPeriodType periodType, {bool forceRefresh = false}) async {
    // #region agent log
    _debugLog('H3', 'multi_period_comparison_controller.dart:117', 'loadComparison() STARTED', {'periodType': periodType.toString()});
    // #endregion
    final userId = _authService.currentUser?.id;
    if (userId == null) {
      // #region agent log
      _debugLog('H3', 'multi_period_comparison_controller.dart:122', 'User not authenticated - aborting');
      // #endregion
      errorMessage.value = 'Usuário não autenticado';
      return;
    }

    try {
      isLoading.value = true;
      // #region agent log
      _debugLog('H3', 'multi_period_comparison_controller.dart:130', 'isLoading set to true');
      // #endregion
      errorMessage.value = '';
      selectedPeriodType.value = periodType;

      // Reseta animações
      _resetAnimations();

      // #region agent log
      _debugLog('H3', 'multi_period_comparison_controller.dart:138', 'Before _generateComparisonUseCase.execute()');
      // #endregion
      final comparison = await _generateComparisonUseCase.execute(
        userId: userId,
        periodType: periodType,
        forceRefresh: forceRefresh,
      );
      // #region agent log
      _debugLog('H3', 'multi_period_comparison_controller.dart:146', 'After _generateComparisonUseCase.execute()', {'periods': comparison.periods.length});
      // #endregion

      currentComparison.value = comparison;

      // Ativa animações sequencialmente
      // #region agent log
      _debugLog('H3', 'multi_period_comparison_controller.dart:152', 'Before _startAnimationSequence()');
      // #endregion
      await _startAnimationSequence();
      // #region agent log
      _debugLog('H3', 'multi_period_comparison_controller.dart:156', 'After _startAnimationSequence()');
      // #endregion
      
      AppLogger.info(FeatureTag.expenses, 'Comparação carregada', data: {
        'periodType': periodType.displayName,
        'periods': comparison.periods.length,
        'hasEnhancedScore': comparison.enhancedScore != null,
        'hasBudgetComparison': comparison.budgetComparison != null,
      });
      // #region agent log
      _debugLog('H3', 'multi_period_comparison_controller.dart:166', 'loadComparison() completed successfully');
      // #endregion
      
    } catch (e) {
      // #region agent log
      _debugLog('H3', 'multi_period_comparison_controller.dart:170', 'loadComparison() EXCEPTION', {'error': e.toString()});
      // #endregion
      errorMessage.value = 'Erro ao carregar comparação: $e';
      AppLogger.error(FeatureTag.expenses, 'Erro ao carregar comparação', data: {'error': e.toString()});
    } finally {
      // #region agent log
      _debugLog('H3', 'multi_period_comparison_controller.dart:176', 'Setting isLoading to false');
      // #endregion
      isLoading.value = false;
    }
  }

  void _resetAnimations() {
    showChart.value = false;
    showInsights.value = false;
    showRecommendations.value = false;
    showBudgetComparison.value = false;
    showGamification.value = false;
  }

  Future<void> _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    showChart.value = true;
    
    await Future.delayed(const Duration(milliseconds: 400));
    showBudgetComparison.value = true;
    
    await Future.delayed(const Duration(milliseconds: 400));
    showInsights.value = true;
    
    await Future.delayed(const Duration(milliseconds: 400));
    showRecommendations.value = true;
    
    await Future.delayed(const Duration(milliseconds: 300));
    showGamification.value = true;
  }

  /// Atualiza a comparação (forçando refresh)
  Future<void> refreshComparison() async {
    isRefreshing.value = true;
    
    // Invalida cache se o serviço estiver disponível
    _smartComparisonService?.invalidateCache();
    _financialContextService?.invalidateCache();
    
    await loadComparison(selectedPeriodType.value, forceRefresh: true);
    isRefreshing.value = false;
  }

  /// Muda o tipo de período
  Future<void> changePeriodType(ComparisonPeriodType type) async {
    if (type != selectedPeriodType.value) {
      await loadComparison(type);
    }
  }

  /// Retorna categoria por ID
  ExpenseCategory? getCategoryById(String id) {
    try {
      return categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // DADOS PARA GRÁFICOS E UI
  // ============================================

  /// Retorna dados formatados para gráfico de linha
  List<Map<String, dynamic>> get lineChartData {
    if (currentComparison.value == null) return [];
    
    return currentComparison.value!.periods.map((period) {
      return {
        'period': period.shortPeriodName,
        'amount': period.totalSpent,
        'budgetLimit': period.budgetLimit,
        'budgetAdherence': period.budgetAdherence,
        'color': _getTrendColor(period),
      };
    }).toList();
  }

  /// Retorna dados para gráfico de comparação com orçamento
  List<Map<String, dynamic>> get budgetComparisonChartData {
    if (currentComparison.value == null) return [];
    
    return currentComparison.value!.periods.map((period) {
      return {
        'period': period.shortPeriodName,
        'spent': period.totalSpent,
        'budget': period.budgetLimit ?? 0.0,
        'adherence': period.budgetAdherence ?? 0.0,
        'isExceeded': (period.budgetAdherence ?? 0) > 100,
      };
    }).toList();
  }

  /// Retorna dados formatados para gráfico de barras
  List<Map<String, dynamic>> get barChartData {
    if (currentComparison.value == null) return [];
    
    return currentComparison.value!.periods.map((period) {
      return {
        'period': period.shortPeriodName,
        'amount': period.totalSpent,
        'average': currentComparison.value!.averageSpending,
      };
    }).toList();
  }

  /// Retorna cor baseada na tendência (usando tokens do Design System)
  String _getTrendColor(PeriodData period) {
    final comparison = currentComparison.value!;
    final avg = comparison.averageSpending;
    
    if (period.totalSpent > avg * 1.1) return '#E76F51'; // colorError
    if (period.totalSpent < avg * 0.9) return '#3CB371'; // colorSuccess
    return '#1A3D63'; // colorBrandPrimary
  }

  /// Retorna top 5 categorias do período mais recente
  List<Map<String, dynamic>> get topCategories {
    if (currentComparison.value == null || 
        currentComparison.value!.periods.isEmpty) {
      return [];
    }

    final lastPeriod = currentComparison.value!.periods.last;
    final sortedCategories = lastPeriod.categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.take(5).map((entry) {
      final category = getCategoryById(entry.key);
      final categoryDetails = lastPeriod.categoryDetails[entry.key];
      
      // Converte Color para string hexadecimal
      String colorHex = '#4A7FA7';
      if (category?.color != null) {
        colorHex = '#${category!.color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
      }
      
      return {
        'id': entry.key,
        'name': category?.name ?? 'Desconhecida',
        'amount': entry.value,
        'color': colorHex,
        'icon': category?.icon ?? 'category',
        'limit': categoryDetails?.limit,
        'adherence': categoryDetails?.adherence,
        'isExceeded': categoryDetails?.isExceeded ?? false,
      };
    }).toList();
  }

  /// Retorna estatísticas gerais
  Map<String, dynamic> get statistics {
    if (currentComparison.value == null) {
      return {
        'average': 0.0,
        'highest': 0.0,
        'lowest': 0.0,
        'total': 0.0,
        'change': 0.0,
      };
    }

    final comp = currentComparison.value!;
    final total = comp.periods.fold(0.0, (sum, period) => sum + period.totalSpent);

    return {
      'average': comp.averageSpending,
      'highest': comp.highestSpendingPeriod?.totalSpent ?? 0.0,
      'lowest': comp.lowestSpendingPeriod?.totalSpent ?? 0.0,
      'total': total,
      'change': comp.overallChangePercentage,
    };
  }

  // ============================================
  // SCORE E GAMIFICAÇÃO
  // ============================================

  /// Retorna o score expandido (se disponível)
  EnhancedScore? get enhancedScore => currentComparison.value?.enhancedScore;

  /// Retorna o score base
  ComparisonScore? get baseScore => currentComparison.value?.insights.score;

  /// Retorna dados de comparação com orçamento
  BudgetComparisonData? get budgetComparison => currentComparison.value?.budgetComparison;

  /// Retorna impacto na gamificação
  GamificationImpact? get gamificationImpact => currentComparison.value?.gamificationImpact;

  /// Verifica se há dados de orçamento
  bool get hasBudgetData => budgetComparison != null && budgetComparison!.totalBudget > 0;

  /// Verifica se há dados de gamificação
  bool get hasGamificationData => gamificationImpact != null && gamificationImpact!.pointsEarned > 0;

  // ============================================
  // INSIGHTS CONTEXTUAIS
  // ============================================

  /// Retorna insights contextuais
  List<FinancialInsight> get contextualInsights => 
      currentComparison.value?.contextualInsights ?? [];

  /// Retorna insights de alta prioridade
  List<FinancialInsight> get highPriorityInsights => 
      contextualInsights.where((i) => 
        i.priority == FinancialInsightPriority.high ||
        i.priority == FinancialInsightPriority.urgent
      ).toList();

  /// Retorna insights positivos
  List<FinancialInsight> get positiveInsights =>
      contextualInsights.where((i) => 
        i.type == FinancialInsightType.positiveProgress
      ).toList();

  // ============================================
  // NAVEGAÇÃO ACIONÁVEL
  // ============================================

  /// Navega para a tela de metas com contexto de categoria
  void navigateToGoals({String? categoryId, double? suggestedLimit}) {
    final arguments = <String, dynamic>{};
    if (categoryId != null) arguments['categoryId'] = categoryId;
    if (suggestedLimit != null) arguments['suggestedLimit'] = suggestedLimit;
    
    Get.toNamed(AppRoutes.financialGoals, arguments: arguments);
  }

  /// Navega para detalhes de uma categoria
  void navigateToCategoryDetails(String categoryId) {
    final category = getCategoryById(categoryId);
    if (category == null) {
      Get.snackbar(
        'Categoria não encontrada',
        'Não foi possível encontrar detalhes desta categoria',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    Get.toNamed(AppRoutes.categoryReport, arguments: {
      'categoryId': categoryId,
      'categoryName': category.name,
    });
  }

  /// Executa ação de uma recomendação
  void executeRecommendationAction(ComparisonRecommendation recommendation) {
    final actionData = recommendation.actionData;
    
    if (actionData == null) {
      Get.snackbar(
        'Ação não disponível',
        'Esta recomendação não possui uma ação específica',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Navega para a rota especificada nos dados da ação
    final route = actionData['route'] as String?;
    if (route != null) {
      // Remove a rota do actionData para evitar duplicação
      final arguments = Map<String, dynamic>.from(actionData)..remove('route');
      Get.toNamed(route, arguments: arguments.isNotEmpty ? arguments : null);
    } else if (actionData['categoryId'] != null) {
      // Fallback: navega para metas se houver categoryId
      navigateToGoals(
        categoryId: actionData['categoryId'] as String,
        suggestedLimit: actionData['suggestedLimit'] as double?,
      );
    }
  }

  /// Executa ação de um insight contextual
  void executeInsightAction(FinancialInsight insight) {
    final data = insight.data;
    
    // Verifica se há rota nos dados
    if (data.containsKey('route')) {
      final route = data['route'] as String;
      final arguments = Map<String, dynamic>.from(data)..remove('route');
      Get.toNamed(route, arguments: arguments.isNotEmpty ? arguments : null);
      return;
    }
    
    // Verifica se há categoryId para navegar para metas
    if (data.containsKey('categoryId')) {
      navigateToGoals(
        categoryId: data['categoryId'] as String,
        suggestedLimit: data['suggestedLimit'] as double?,
      );
      return;
    }
    
    // Fallback: mostrar detalhes do insight
    Get.snackbar(
      insight.title,
      insight.description,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  /// Cria meta a partir de uma recomendação
  void createGoalFromRecommendation(ComparisonRecommendation recommendation) {
    final categoryId = recommendation.actionData?['categoryId'] as String?;
    final suggestedLimit = recommendation.actionData?['suggestedLimit'] as double?;
    
    if (categoryId == null) {
      Get.snackbar(
        'Erro',
        'Não foi possível identificar a categoria para criar a meta',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    navigateToGoals(
      categoryId: categoryId,
      suggestedLimit: suggestedLimit,
    );
  }

  // ============================================
  // COMPARTILHAMENTO
  // ============================================

  /// Compartilha o relatório de comparação
  void shareComparison() {
    if (currentComparison.value == null) {
      Get.snackbar(
        'Erro',
        'Não há dados para compartilhar',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    final shareService = ComparisonShareService();
    shareService.showShareOptions(currentComparison.value!);
  }

  // ============================================
  // ESTADO E HELPERS
  // ============================================

  /// Verifica se há dados
  bool get hasData => currentComparison.value != null && 
      currentComparison.value!.periods.isNotEmpty;

  /// Retorna mensagem de estado vazio
  String get emptyStateMessage {
    switch (selectedPeriodType.value) {
      case ComparisonPeriodType.threeMonths:
        return 'Registre seus gastos para ver uma comparação dos últimos 3 meses';
      case ComparisonPeriodType.sixMonths:
        return 'Registre seus gastos para ver uma comparação dos últimos 6 meses';
      case ComparisonPeriodType.twelveMonths:
        return 'Registre seus gastos para ver uma comparação dos últimos 12 meses';
      default:
        return 'Registre seus gastos para ver comparações detalhadas';
    }
  }

  /// Verifica se o sistema integrado está disponível
  bool get hasEnhancedFeatures => 
      currentComparison.value?.enhancedScore != null ||
      currentComparison.value?.budgetComparison != null ||
      (currentComparison.value?.contextualInsights.isNotEmpty ?? false);

  // ============================================
  // FILTRO DE CATEGORIA
  // ============================================

  /// Categorias disponíveis para filtro
  List<ExpenseCategory> get filterableCategories => categories.toList();

  /// Verifica se há filtro de categoria ativo
  bool get hasCategoryFilter => selectedCategoryId.value != null;

  /// Categoria selecionada
  ExpenseCategory? get selectedCategory {
    if (selectedCategoryId.value == null) return null;
    return getCategoryById(selectedCategoryId.value!);
  }

  /// Alterna visibilidade do filtro de categorias
  void toggleCategoryFilter() {
    showCategoryFilter.value = !showCategoryFilter.value;
  }

  /// Seleciona uma categoria para filtrar
  void selectCategory(String categoryId) {
    selectedCategoryId.value = categoryId;
    showCategoryFilter.value = false;
  }

  /// Limpa o filtro de categoria
  void clearCategoryFilter() {
    selectedCategoryId.value = null;
  }

  /// Dados do gráfico filtrados por categoria
  List<Map<String, dynamic>> get filteredLineChartData {
    if (!hasCategoryFilter || currentComparison.value == null) {
      return lineChartData;
    }

    final categoryId = selectedCategoryId.value!;
    return currentComparison.value!.periods.map((period) {
      final categoryAmount = period.categoryBreakdown[categoryId] ?? 0.0;
      return {
        'period': period.shortPeriodName,
        'amount': categoryAmount,
        'budgetLimit': period.categoryDetails[categoryId]?.limit,
        'budgetAdherence': period.categoryDetails[categoryId]?.adherence,
        'color': _getFilteredTrendColor(categoryAmount, categoryId),
      };
    }).toList();
  }

  String _getFilteredTrendColor(double amount, String categoryId) {
    // Calcula média da categoria
    final categoryAmounts = currentComparison.value!.periods
        .map((p) => p.categoryBreakdown[categoryId] ?? 0.0)
        .toList();
    final avg = categoryAmounts.isEmpty 
        ? 0.0 
        : categoryAmounts.fold(0.0, (s, v) => s + v) / categoryAmounts.length;
    
    if (amount > avg * 1.1) return '#E76F51'; // colorError
    if (amount < avg * 0.9) return '#3CB371'; // colorSuccess
    return '#1A3D63'; // colorBrandPrimary
  }

  /// Estatísticas filtradas por categoria
  Map<String, dynamic> get filteredStatistics {
    if (!hasCategoryFilter || currentComparison.value == null) {
      return statistics;
    }

    final categoryId = selectedCategoryId.value!;
    final periods = currentComparison.value!.periods;
    
    final categoryAmounts = periods
        .map((p) => p.categoryBreakdown[categoryId] ?? 0.0)
        .toList();
    
    if (categoryAmounts.isEmpty) {
      return {
        'average': 0.0,
        'highest': 0.0,
        'lowest': 0.0,
        'total': 0.0,
        'change': 0.0,
      };
    }

    final total = categoryAmounts.fold(0.0, (s, v) => s + v);
    final avg = total / categoryAmounts.length;
    final highest = categoryAmounts.reduce((a, b) => a > b ? a : b);
    final lowest = categoryAmounts.reduce((a, b) => a < b ? a : b);
    
    // Variação entre primeiro e último período
    final first = categoryAmounts.first;
    final last = categoryAmounts.last;
    final change = first > 0 ? ((last - first) / first) * 100 : 0.0;

    return {
      'average': avg,
      'highest': highest,
      'lowest': lowest,
      'total': total,
      'change': change,
    };
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
}
