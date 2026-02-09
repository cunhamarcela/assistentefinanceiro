import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'dart:convert';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/services/financial_context_service.dart';
import '../../domain/entities/financial_profile.dart';
import '../../domain/entities/financial_goal.dart';
import '../../domain/entities/category.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/repositories/financial_goals_repository.dart';
import '../../data/services/financial_profile_service.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../data/repositories/expense_hybrid_repository.dart';

class FinancialGoalsController extends GetxController {
  // Services
  late final GetCategoriesUseCase _getCategoriesUseCase;
  late final FinancialProfileService _profileService;
  late final FinancialGoalsRepository _goalsRepository;
  late final AuthService _authService;

  // Controllers
  final incomeController = TextEditingController();
  final totalBudgetController = TextEditingController();
  final investmentGoalController = TextEditingController(); // Nova: meta de investimento
  final Map<String, TextEditingController> _categoryControllers = {};

  // Observable state
  final isLoading = false.obs;
  final isSaving = false.obs;
  final hasUnsavedChanges = false.obs;
  
  final monthlyIncome = 0.0.obs;
  final totalBudget = 0.0.obs;
  final monthlyInvestmentGoal = 0.0.obs; // Nova: meta mensal de investimento
  final categoryBudgets = <String, double>{}.obs;
  final categories = <ExpenseCategory>[].obs;
  final selectedCategories = <String>{}.obs; // IDs das categorias selecionadas

  // Cache das metas carregadas (já com gastos recalculados)
  final currentMonthGoals = <FinancialGoal>[].obs;

  FinancialProfile? _originalProfile;

  @override
  void onInit() {
    super.onInit();
    AppLogger.info(FeatureTag.goals, '🎯 FinancialGoalsController inicializando');
    _initializeDependencies();
    _loadData();
  }

  @override
  void onClose() {
    AppLogger.debug(FeatureTag.goals, 'FinancialGoalsController disposing');
    incomeController.dispose();
    totalBudgetController.dispose();
    investmentGoalController.dispose();
    for (final controller in _categoryControllers.values) {
      controller.dispose();
    }
    super.onClose();
  }

  void _initializeDependencies() {
    AppLogger.debug(FeatureTag.goals, 'Inicializando dependências');
    // #region agent log
    _debugLog('H2', 'financial_goals_controller.dart:68', 'Starting _initializeDependencies');
    // #endregion
    try {
      _getCategoriesUseCase = Get.find<GetCategoriesUseCase>();
      // #region agent log
      _debugLog('H2', 'financial_goals_controller.dart:72', 'Found GetCategoriesUseCase');
      // #endregion
    } catch (e) {
      // #region agent log
      _debugLog('H2', 'financial_goals_controller.dart:75', 'FAILED GetCategoriesUseCase', {'error': e.toString()});
      // #endregion
      rethrow;
    }
    try {
      _profileService = Get.find<FinancialProfileService>();
      // #region agent log
      _debugLog('H2', 'financial_goals_controller.dart:81', 'Found FinancialProfileService');
      // #endregion
    } catch (e) {
      // #region agent log
      _debugLog('H2', 'financial_goals_controller.dart:84', 'FAILED FinancialProfileService', {'error': e.toString()});
      // #endregion
      rethrow;
    }
    try {
      _goalsRepository = Get.find<FinancialGoalsRepository>();
      // #region agent log
      _debugLog('H2', 'financial_goals_controller.dart:90', 'Found FinancialGoalsRepository');
      // #endregion
    } catch (e) {
      // #region agent log
      _debugLog('H2', 'financial_goals_controller.dart:93', 'FAILED FinancialGoalsRepository', {'error': e.toString()});
      // #endregion
      rethrow;
    }
    try {
      _authService = Get.find<AuthService>();
      // #region agent log
      _debugLog('H2', 'financial_goals_controller.dart:99', 'Found AuthService');
      // #endregion
    } catch (e) {
      // #region agent log
      _debugLog('H2', 'financial_goals_controller.dart:102', 'FAILED AuthService', {'error': e.toString()});
      // #endregion
      rethrow;
    }
    // #region agent log
    _debugLog('H2', 'financial_goals_controller.dart:106', 'All dependencies initialized');
    // #endregion
  }

  Future<void> _loadData() async {
    // #region agent log
    _debugLog('H2', 'financial_goals_controller.dart:111', 'Starting _loadData');
    // #endregion
    final opId = AppLogger.startOp(FeatureTag.goals, 'load_goals_data');
    
    try {
      isLoading.value = true;

      // Carregar categorias
      // #region agent log
      _debugLog('H2', 'financial_goals_controller.dart:134', 'Before loadCategories()');
      // #endregion
      await loadCategories();
      // #region agent log
      _debugLog('H2', 'financial_goals_controller.dart:138', 'After loadCategories()', {'count': categories.length});
      // #endregion

      // Carregar perfil financeiro existente
      // #region agent log
      _debugLog('H2', 'financial_goals_controller.dart:142', 'Before _loadFinancialProfile()');
      // #endregion
      await _loadFinancialProfile();
      // #region agent log
      _debugLog('H2', 'financial_goals_controller.dart:146', 'After _loadFinancialProfile()');
      // #endregion

      // Carregar metas do mês atual (já recalcula gastos)
      // #region agent log
      _debugLog('H2', 'financial_goals_controller.dart:150', 'Before _loadAndRecalculateGoals()');
      // #endregion
      await _loadAndRecalculateGoals();
      // #region agent log
      _debugLog('H2', 'financial_goals_controller.dart:154', 'After _loadAndRecalculateGoals()');
      // #endregion
      
      AppLogger.completeOp(opId, message: 'Dados de metas carregados', data: {
        'categories_count': categories.length,
        'has_profile': _originalProfile != null,
        'monthly_income': monthlyIncome.value,
        'total_budget': totalBudget.value,
        'goals_count': currentMonthGoals.length,
      });
      // #region agent log
      _debugLog('H2', 'financial_goals_controller.dart:165', '_loadData completed successfully');
      // #endregion

    } catch (e) {
      // #region agent log
      _debugLog('H2', 'financial_goals_controller.dart:169', '_loadData EXCEPTION', {'error': e.toString()});
      // #endregion
      AppLogger.failOp(opId, 'Erro ao carregar dados de metas', exception: e);
      Get.snackbar(
        'Erro',
        'Erro ao carregar dados. Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorError,
        colorText: AppColors.colorTextOnDark,
      );
    } finally {
      // #region agent log
      _debugLog('H2', 'financial_goals_controller.dart:181', 'Setting isLoading to false');
      // #endregion
      isLoading.value = false;
    }
  }

  /// Carrega e recalcula metas do mês atual
  Future<void> _loadAndRecalculateGoals() async {
    try {
      final goals = await loadCurrentMonthGoals();
      currentMonthGoals.value = goals;
      AppLogger.debug(FeatureTag.goals, 'Metas do mês carregadas no cache', data: {
        'count': goals.length,
        'total_spent': goals.fold(0.0, (sum, g) => sum + g.currentSpent),
      });
    } catch (e) {
      AppLogger.warning(FeatureTag.goals, 'Erro ao carregar metas do mês', data: {'error': e.toString()});
    }
  }

  Future<void> loadCategories() async {
    final opId = AppLogger.startOp(FeatureTag.categories, 'load_categories_for_goals');
    
    try {
      final result = await _getCategoriesUseCase.execute();
      
      // Se há poucas categorias, forçar inicialização das padrões
      if (result.length < 5) {
        AppLogger.warning(FeatureTag.categories, 'Poucas categorias encontradas', data: {
          'count': result.length,
        });
        
        try {
          // Usar o repositório para garantir categorias padrão
          final repository = Get.find<ExpenseRepository>();
          if (repository is ExpenseHybridRepository) {
            await repository.ensureDefaultCategories();
            // Recarregar após inicialização
            final newResult = await _getCategoriesUseCase.execute();
            categories.value = newResult;
            AppLogger.info(FeatureTag.categories, 'Categorias recarregadas após inicialização', data: {
              'count': newResult.length,
            });
          } else {
            categories.value = result;
          }
        } catch (e) {
          AppLogger.error(FeatureTag.categories, 'Erro ao inicializar categorias padrão', error: e);
          categories.value = result;
        }
      } else {
        categories.value = result;
      }

      // Criar controllers para cada categoria
      for (final category in categories.value) {
        _categoryControllers[category.id] = TextEditingController();
      }
      
      AppLogger.completeOp(opId, data: {'count': categories.length});
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao carregar categorias', exception: e);
      throw Exception('Erro ao carregar categorias');
    }
  }

  Future<void> _loadFinancialProfile() async {
    final opId = AppLogger.startOp(FeatureTag.goals, 'load_financial_profile');
    
    try {
      final profile = await _profileService.getFinancialProfile();
      
      if (profile != null) {
        _originalProfile = profile;
        
        // Atualizar campos
        monthlyIncome.value = profile.monthlyIncome;
        totalBudget.value = profile.totalBudget;
        monthlyInvestmentGoal.value = profile.monthlyInvestmentGoal;
        categoryBudgets.value = Map.from(profile.categoryBudgets);

        // Atualizar controllers
        incomeController.text = profile.monthlyIncome > 0 
            ? profile.monthlyIncome.toStringAsFixed(2) 
            : '';
        totalBudgetController.text = profile.totalBudget > 0 
            ? profile.totalBudget.toStringAsFixed(2) 
            : '';
        investmentGoalController.text = profile.monthlyInvestmentGoal > 0 
            ? profile.monthlyInvestmentGoal.toStringAsFixed(2) 
            : '';

        // Atualizar controllers das categorias e seleções
        selectedCategories.clear();
        for (final entry in profile.categoryBudgets.entries) {
          final controller = _categoryControllers[entry.key];
          if (controller != null) {
            controller.text = entry.value > 0 ? entry.value.toStringAsFixed(2) : '';
            selectedCategories.add(entry.key); // Marcar categoria como selecionada
          }
        }
        selectedCategories.refresh();
        
        AppLogger.completeOp(opId, message: 'Perfil financeiro carregado', data: {
          'income': profile.monthlyIncome,
          'budget': profile.totalBudget,
          'investment_goal': profile.monthlyInvestmentGoal,
          'categories_with_budget': profile.categoryBudgets.length,
        });
      } else {
        AppLogger.info(FeatureTag.goals, 'Nenhum perfil financeiro existente');
        AppLogger.completeOp(opId, message: 'Perfil não encontrado (primeiro acesso)');
      }
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao carregar perfil financeiro', exception: e);
      // Não lançar erro aqui, pois pode ser o primeiro acesso
    }
  }

  void updateIncome(String value) {
    final income = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    monthlyIncome.value = income;
    AppLogger.debug(FeatureTag.goals, 'Renda atualizada', data: {'value': income});
    _checkForChanges();
  }

  void updateTotalBudget(String value) {
    final budget = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    totalBudget.value = budget;
    AppLogger.debug(FeatureTag.goals, 'Orçamento total atualizado', data: {'value': budget});
    _checkForChanges();
  }

  /// Atualizar meta mensal de investimento
  void updateInvestmentGoal(String value) {
    final goal = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    monthlyInvestmentGoal.value = goal;
    AppLogger.debug(FeatureTag.goals, 'Meta de investimento atualizada', data: {'value': goal});
    _checkForChanges();
  }

  /// Orçamento máximo disponível para despesas (renda - meta de investimento)
  double get availableBudgetForExpenses {
    return monthlyIncome.value - monthlyInvestmentGoal.value;
  }

  /// Percentual da renda destinado a investimentos
  double get investmentPercentage {
    if (monthlyIncome.value <= 0) return 0.0;
    return (monthlyInvestmentGoal.value / monthlyIncome.value) * 100;
  }

  /// Percentual da renda destinado a despesas
  double get expensesPercentage {
    if (monthlyIncome.value <= 0) return 0.0;
    return 100 - investmentPercentage;
  }

  /// Verifica se o orçamento de despesas está dentro do limite disponível
  bool get isBudgetWithinLimit {
    return totalBudget.value <= availableBudgetForExpenses;
  }

  /// Margem restante após orçamento de despesas
  double get remainingMargin {
    return availableBudgetForExpenses - totalBudget.value;
  }

  /// Verifica se o orçamento ultrapassa o disponível (alerta)
  bool get isBudgetOverLimit {
    return totalBudget.value > availableBudgetForExpenses && availableBudgetForExpenses > 0;
  }

  void updateCategoryBudget(String categoryId, String value) {
    final budget = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    
    if (budget > 0) {
      categoryBudgets[categoryId] = budget;
    } else {
      categoryBudgets.remove(categoryId);
    }
    
    AppLogger.debug(FeatureTag.goals, 'Orçamento de categoria atualizado', data: {
      'category_id': categoryId,
      'value': budget,
    });
    
    categoryBudgets.refresh();
    _checkForChanges();
  }

  void toggleCategorySelection(String categoryId) {
    AppLogger.action('toggle_category_selection', feature: FeatureTag.goals, data: {
      'category_id': categoryId,
      'was_selected': selectedCategories.contains(categoryId),
    });
    
    if (selectedCategories.contains(categoryId)) {
      selectedCategories.remove(categoryId);
      // Remove o orçamento da categoria desmarcada
      categoryBudgets.remove(categoryId);
      _categoryControllers[categoryId]?.clear();
    } else {
      selectedCategories.add(categoryId);
    }
    selectedCategories.refresh();
    categoryBudgets.refresh();
    _checkForChanges();
  }

  bool isCategorySelected(String categoryId) {
    return selectedCategories.contains(categoryId);
  }

  List<ExpenseCategory> get availableCategories {
    return categories.where((cat) => !selectedCategories.contains(cat.id)).toList();
  }

  List<ExpenseCategory> get selectedCategoriesList {
    return categories.where((cat) => selectedCategories.contains(cat.id)).toList();
  }

  /// Forçar inicialização das categorias padrão
  Future<void> forceInitializeDefaultCategories() async {
    final opId = AppLogger.startOp(FeatureTag.categories, 'force_init_default_categories');
    
    try {
      isLoading.value = true;
      AppLogger.info(FeatureTag.categories, 'Forçando inicialização das categorias padrão');
      
      final repository = Get.find<ExpenseRepository>();
      if (repository is ExpenseHybridRepository) {
        await repository.forceRecreateDefaultCategories();
        await loadCategories();
        
        AppLogger.completeOp(opId, message: 'Categorias padrão inicializadas');
        
        Get.snackbar(
          'Sucesso',
          'Categorias padrão inicializadas com sucesso!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao forçar inicialização', exception: e);
      Get.snackbar(
        'Erro',
        'Erro ao inicializar categorias padrão',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorError,
        colorText: AppColors.colorTextOnDark,
      );
    } finally {
      isLoading.value = false;
    }
  }

  TextEditingController getCategoryController(String categoryId) {
    return _categoryControllers[categoryId] ?? TextEditingController();
  }

  void _checkForChanges() {
    if (_originalProfile == null) {
      // Novo perfil - tem mudanças se algum campo foi preenchido
      hasUnsavedChanges.value = monthlyIncome.value > 0 || 
                               totalBudget.value > 0 || 
                               monthlyInvestmentGoal.value > 0 ||
                               categoryBudgets.isNotEmpty;
    } else {
      // Perfil existente - verificar se houve mudanças
      hasUnsavedChanges.value = 
          monthlyIncome.value != _originalProfile!.monthlyIncome ||
          totalBudget.value != _originalProfile!.totalBudget ||
          monthlyInvestmentGoal.value != _originalProfile!.monthlyInvestmentGoal ||
          !_mapsEqual(categoryBudgets, _originalProfile!.categoryBudgets);
    }
    
    AppLogger.state(FeatureTag.goals, 'unsaved_changes', data: {
      'has_changes': hasUnsavedChanges.value,
    });
  }

  bool _mapsEqual(Map<String, double> map1, Map<String, double> map2) {
    if (map1.length != map2.length) return false;
    
    for (final entry in map1.entries) {
      if (!map2.containsKey(entry.key) || map2[entry.key] != entry.value) {
        return false;
      }
    }
    
    return true;
  }

  bool get isProfileValid {
    return monthlyIncome.value > 0 && totalBudget.value > 0;
  }

  Future<void> saveProfile() async {
    if (!isProfileValid) {
      AppLogger.warning(FeatureTag.goals, 'Tentativa de salvar perfil inválido');
      Get.snackbar(
        'Dados Incompletos',
        'Preencha pelo menos a renda mensal e o orçamento total.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorWarning,
        colorText: AppColors.colorTextOnDark,
      );
      return;
    }

    final opId = AppLogger.startOp(FeatureTag.goals, 'save_profile', data: {
      'income': monthlyIncome.value,
      'budget': totalBudget.value,
      'categories_count': categoryBudgets.length,
    });

    try {
      isSaving.value = true;

      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      // Criar ou atualizar perfil
      final profile = FinancialProfile(
        id: _originalProfile?.id ?? 'profile_$userId',
        userId: userId,
        monthlyIncome: monthlyIncome.value,
        totalBudget: totalBudget.value,
        monthlyInvestmentGoal: monthlyInvestmentGoal.value,
        categoryBudgets: Map.from(categoryBudgets),
        createdAt: _originalProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _profileService.saveFinancialProfile(profile);
      AppLogger.saved(FeatureTag.goals, 'perfil_financeiro', id: profile.id);

      // Criar/atualizar metas baseadas no perfil
      await _createGoalsFromProfile(profile);

      _originalProfile = profile;
      hasUnsavedChanges.value = false;

      // Recarregar metas para atualizar o cache (gastos já recalculados pelo repositório)
      await _loadAndRecalculateGoals();

      // Invalidar cache de contexto financeiro
      invalidateContextCache();

      AppLogger.completeOp(opId, message: 'Perfil e metas salvos');
      AppLogger.goalCreated('Perfil Financeiro', totalBudget.value, 'geral');

      // Mostrar feedback de sucesso
      Get.snackbar(
        '✅ Salvo com Sucesso!',
        'Suas metas financeiras foram atualizadas.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorSuccess,
        colorText: AppColors.colorTextOnDark,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      // Aguardar um momento para o usuário ver o feedback antes de voltar
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Voltar para a tela anterior após salvar
      Get.back();

    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao salvar perfil', exception: e);
      Get.snackbar(
        'Erro',
        'Erro ao salvar configurações. Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorError,
        colorText: AppColors.colorTextOnDark,
      );
    } finally {
      isSaving.value = false;
    }
  }

  // Método para resetar o formulário
  void resetForm() {
    AppLogger.action('reset_form', feature: FeatureTag.goals);
    
    incomeController.clear();
    totalBudgetController.clear();
    investmentGoalController.clear();
    
    for (final controller in _categoryControllers.values) {
      controller.clear();
    }

    monthlyIncome.value = 0.0;
    totalBudget.value = 0.0;
    monthlyInvestmentGoal.value = 0.0;
    categoryBudgets.clear();
    hasUnsavedChanges.value = false;
    
    AppLogger.debug(FeatureTag.goals, 'Formulário resetado');
  }

  // Método para aplicar um template de orçamento
  void applyBudgetTemplate(String templateName) {
    AppLogger.action('apply_template', feature: FeatureTag.goals, data: {'template': templateName});
    
    switch (templateName) {
      case '50-30-20':
        _apply503020Rule();
        break;
      case 'conservative':
        _applyConservativeTemplate();
        break;
      case 'aggressive':
        _applyAggressiveTemplate();
        break;
    }
    
    AppLogger.info(FeatureTag.goals, 'Template aplicado', data: {
      'template': templateName,
      'total_budget': totalBudget.value,
    });
  }

  void _apply503020Rule() {
    if (monthlyIncome.value <= 0) return;

    final income = monthlyIncome.value;
    
    // Regra 50-30-20: 50% necessidades, 30% desejos, 20% investimentos/poupança
    monthlyInvestmentGoal.value = income * 0.2; // 20% para investimentos
    investmentGoalController.text = monthlyInvestmentGoal.value.toStringAsFixed(2);
    
    totalBudget.value = income * 0.8; // 80% para gastos (50% necessidades + 30% desejos)
    totalBudgetController.text = totalBudget.value.toStringAsFixed(2);

    // Distribuir entre categorias principais
    final necessities = income * 0.5;
    final wants = income * 0.3;

    // Exemplo de distribuição (pode ser customizado)
    _distributeBudget({
      'alimentacao': necessities * 0.4,
      'transporte': necessities * 0.3,
      'moradia': necessities * 0.3,
      'entretenimento': wants * 0.5,
      'compras': wants * 0.3,
      'outros': wants * 0.2,
    });
    
    AppLogger.logic(FeatureTag.goals, 'Regra 50-30-20 aplicada', input: {
      'income': income,
    }, result: totalBudget.value);
  }

  void _applyConservativeTemplate() {
    if (monthlyIncome.value <= 0) return;

    final income = monthlyIncome.value;
    
    // Template conservador: 30% para investimentos, 70% para gastos
    monthlyInvestmentGoal.value = income * 0.3; // 30% para investimentos
    investmentGoalController.text = monthlyInvestmentGoal.value.toStringAsFixed(2);
    
    totalBudget.value = income * 0.7; // 70% para gastos
    totalBudgetController.text = totalBudget.value.toStringAsFixed(2);

    _distributeBudget({
      'alimentacao': totalBudget.value * 0.35,
      'transporte': totalBudget.value * 0.25,
      'moradia': totalBudget.value * 0.25,
      'entretenimento': totalBudget.value * 0.1,
      'outros': totalBudget.value * 0.05,
    });
  }

  void _applyAggressiveTemplate() {
    if (monthlyIncome.value <= 0) return;

    final income = monthlyIncome.value;
    
    // Template agressivo: 10% para investimentos, 90% para gastos
    monthlyInvestmentGoal.value = income * 0.1; // 10% para investimentos
    investmentGoalController.text = monthlyInvestmentGoal.value.toStringAsFixed(2);
    
    totalBudget.value = income * 0.9; // 90% para gastos
    totalBudgetController.text = totalBudget.value.toStringAsFixed(2);

    _distributeBudget({
      'alimentacao': totalBudget.value * 0.3,
      'transporte': totalBudget.value * 0.2,
      'moradia': totalBudget.value * 0.2,
      'entretenimento': totalBudget.value * 0.15,
      'compras': totalBudget.value * 0.1,
      'outros': totalBudget.value * 0.05,
    });
  }

  void _distributeBudget(Map<String, double> distribution) {
    for (final entry in distribution.entries) {
      final categoryId = entry.key;
      final amount = entry.value;
      
      categoryBudgets[categoryId] = amount;
      
      final controller = _categoryControllers[categoryId];
      if (controller != null) {
        controller.text = amount.toStringAsFixed(2);
      }
    }
    
    categoryBudgets.refresh();
    _checkForChanges();
    
    AppLogger.debug(FeatureTag.goals, 'Orçamento distribuído', data: {
      'categories_count': distribution.length,
    });
  }

  /// Criar metas baseadas no perfil financeiro
  Future<void> _createGoalsFromProfile(FinancialProfile profile) async {
    final opId = AppLogger.startOp(FeatureTag.goals, 'create_goals_from_profile');
    
    try {
      AppLogger.debug(FeatureTag.goals, 'Criando metas baseadas no perfil', data: {
        'categories_with_budget': profile.categoryBudgets.length,
      });
      
      final currentMonth = DateTime.now();
      final targetMonth = DateTime(currentMonth.year, currentMonth.month);
      
      // Criar metas para cada categoria com orçamento definido
      await _goalsRepository.createGoalsFromProfile(profile.categoryBudgets, targetMonth);
      
      AppLogger.completeOp(opId, message: 'Metas criadas do perfil', data: {
        'goals_count': profile.categoryBudgets.length,
      });
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao criar metas do perfil', exception: e);
      // Não lançar erro aqui para não interromper o salvamento do perfil
    }
  }

  /// Carregar metas do mês atual (recalcula gastos automaticamente)
  Future<List<FinancialGoal>> loadCurrentMonthGoals() async {
    AppLogger.debug(FeatureTag.goals, 'Carregando metas do mês atual');
    
    try {
      final currentMonth = DateTime.now();
      final targetMonth = DateTime(currentMonth.year, currentMonth.month);
      
      // Primeiro recalcula os gastos baseado nas despesas existentes
      final recalculatedGoals = await _goalsRepository.recalculateGoalsSpent(targetMonth);
      
      if (recalculatedGoals.isNotEmpty) {
        AppLogger.loaded(FeatureTag.goals, 'metas do mês (recalculadas)', recalculatedGoals.length);
        return recalculatedGoals;
      }
      
      // Fallback: buscar metas sem recalcular
      final goals = await _goalsRepository.getGoalsByMonth(targetMonth);
      AppLogger.loaded(FeatureTag.goals, 'metas do mês', goals.length);
      
      return goals;
    } catch (e) {
      AppLogger.error(FeatureTag.goals, 'Erro ao carregar metas', error: e);
      return [];
    }
  }

  /// Obter resumo das metas
  Map<String, dynamic> getGoalsSummary(List<FinancialGoal> goals) {
    if (goals.isEmpty) {
      return {
        'totalBudget': 0.0,
        'totalSpent': 0.0,
        'totalRemaining': 0.0,
        'progressPercentage': 0.0,
        'goalsCount': 0,
        'exceededGoals': 0,
      };
    }

    final totalBudget = goals.fold<double>(0.0, (sum, goal) => sum + goal.monthlyLimit);
    final totalSpent = goals.fold<double>(0.0, (sum, goal) => sum + goal.currentSpent);
    final totalRemaining = totalBudget - totalSpent;
    final progressPercentage = totalBudget > 0 ? totalSpent / totalBudget : 0.0;
    final exceededGoals = goals.where((goal) => goal.isExceeded).length;

    final summary = {
      'totalBudget': totalBudget,
      'totalSpent': totalSpent,
      'totalRemaining': totalRemaining,
      'progressPercentage': progressPercentage,
      'goalsCount': goals.length,
      'exceededGoals': exceededGoals,
    };
    
    AppLogger.debug(FeatureTag.goals, 'Resumo das metas calculado', data: summary);
    return summary;
  }

  /// Verificar se existem metas para o mês atual
  Future<bool> hasCurrentMonthGoals() async {
    final goals = await loadCurrentMonthGoals();
    final hasGoals = goals.isNotEmpty;
    AppLogger.debug(FeatureTag.goals, 'Verificação de metas do mês', data: {'has_goals': hasGoals});
    return hasGoals;
  }

  // ============================================
  // INTEGRAÇÃO COM IA E RELATÓRIOS
  // ============================================

  /// Obtém sugestões de orçamento baseadas no histórico de gastos
  /// Usa FinancialContextService para análise inteligente
  Future<Map<String, double>> getSuggestedBudgets() async {
    final opId = AppLogger.startOp(FeatureTag.goals, 'get_suggested_budgets');

    try {
      if (!Get.isRegistered<FinancialContextService>()) {
        AppLogger.warning(FeatureTag.goals, 'FinancialContextService não disponível');
        return {};
      }

      final contextService = Get.find<FinancialContextService>();
      final suggestions = await contextService.getSuggestedBudgets();

      AppLogger.completeOp(opId, data: {
        'suggestions_count': suggestions.length,
      });

      return suggestions;
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao obter sugestões', exception: e);
      return {};
    }
  }

  /// Aplica sugestões de orçamento baseadas no histórico
  Future<void> applySuggestedBudgets() async {
    final opId = AppLogger.startOp(FeatureTag.goals, 'apply_suggested_budgets');

    try {
      isLoading.value = true;

      final suggestions = await getSuggestedBudgets();

      if (suggestions.isEmpty) {
        Get.snackbar(
          'Sem Histórico',
          'Registre despesas por pelo menos 1 mês para receber sugestões personalizadas.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.colorWarning,
          colorText: Colors.white,
        );
        AppLogger.completeOp(opId, message: 'Sem sugestões disponíveis');
        return;
      }

      // Aplicar sugestões para categorias correspondentes
      for (final entry in suggestions.entries) {
        final categoryId = entry.key;
        final suggestedAmount = entry.value;

        categoryBudgets[categoryId] = suggestedAmount;

        // Atualizar controller se existir
        final controller = _categoryControllers[categoryId];
        if (controller != null) {
          controller.text = suggestedAmount.toStringAsFixed(2);
        }

        // Marcar categoria como selecionada
        if (!selectedCategories.contains(categoryId)) {
          selectedCategories.add(categoryId);
        }
      }

      categoryBudgets.refresh();
      selectedCategories.refresh();
      _checkForChanges();

      AppLogger.completeOp(opId, message: 'Sugestões aplicadas', data: {
        'categories_count': suggestions.length,
      });

      Get.snackbar(
        'Sugestões Aplicadas',
        'Orçamentos sugeridos baseados no seu histórico de gastos.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorSuccess,
        colorText: Colors.white,
      );
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao aplicar sugestões', exception: e);
      Get.snackbar(
        'Erro',
        'Não foi possível aplicar as sugestões.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorError,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Obtém alertas proativos das metas
  Future<List<GoalAlert>> getProactiveAlerts() async {
    try {
      if (!Get.isRegistered<FinancialContextService>()) {
        return [];
      }

      final contextService = Get.find<FinancialContextService>();
      return await contextService.getProactiveAlerts();
    } catch (e) {
      AppLogger.warning(FeatureTag.goals, 'Erro ao obter alertas', data: {'error': e.toString()});
      return [];
    }
  }

  /// Invalida o cache de contexto (chamar quando metas são alteradas)
  void invalidateContextCache() {
    try {
      if (Get.isRegistered<FinancialContextService>()) {
        Get.find<FinancialContextService>().invalidateCache();
        AppLogger.debug(FeatureTag.goals, 'Cache de contexto invalidado');
      }
    } catch (e) {
      AppLogger.warning(FeatureTag.goals, 'Erro ao invalidar cache', data: {'error': e.toString()});
    }
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
