import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/financial_profile.dart';
import '../../domain/entities/category.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../data/services/financial_profile_service.dart';
import '../../../auth/data/services/auth_service.dart';

class FinancialGoalsController extends GetxController {
  // Services
  late final GetCategoriesUseCase _getCategoriesUseCase;
  late final FinancialProfileService _profileService;
  late final AuthService _authService;

  // Controllers
  final incomeController = TextEditingController();
  final totalBudgetController = TextEditingController();
  final Map<String, TextEditingController> _categoryControllers = {};

  // Observable state
  final isLoading = false.obs;
  final isSaving = false.obs;
  final hasUnsavedChanges = false.obs;
  
  final monthlyIncome = 0.0.obs;
  final totalBudget = 0.0.obs;
  final categoryBudgets = <String, double>{}.obs;
  final categories = <ExpenseCategory>[].obs;

  FinancialProfile? _originalProfile;

  @override
  void onInit() {
    super.onInit();
    _initializeDependencies();
    _loadData();
  }

  @override
  void onClose() {
    incomeController.dispose();
    totalBudgetController.dispose();
    for (final controller in _categoryControllers.values) {
      controller.dispose();
    }
    super.onClose();
  }

  void _initializeDependencies() {
    _getCategoriesUseCase = Get.find<GetCategoriesUseCase>();
    _profileService = Get.find<FinancialProfileService>();
    _authService = Get.find<AuthService>();
  }

  Future<void> _loadData() async {
    try {
      isLoading.value = true;

      // Carregar categorias
      await _loadCategories();

      // Carregar perfil financeiro existente
      await _loadFinancialProfile();

    } catch (e) {
      print('❌ Erro ao carregar dados: $e');
      Get.snackbar(
        'Erro',
        'Erro ao carregar dados. Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final result = await _getCategoriesUseCase.execute();
      categories.value = result;

      // Criar controllers para cada categoria
      for (final category in result) {
        _categoryControllers[category.id] = TextEditingController();
      }
    } catch (e) {
      print('❌ Erro ao carregar categorias: $e');
      throw Exception('Erro ao carregar categorias');
    }
  }

  Future<void> _loadFinancialProfile() async {
    try {
      final profile = await _profileService.getFinancialProfile();
      
      if (profile != null) {
        _originalProfile = profile;
        
        // Atualizar campos
        monthlyIncome.value = profile.monthlyIncome;
        totalBudget.value = profile.totalBudget;
        categoryBudgets.value = Map.from(profile.categoryBudgets);

        // Atualizar controllers
        incomeController.text = profile.monthlyIncome > 0 
            ? profile.monthlyIncome.toStringAsFixed(2) 
            : '';
        totalBudgetController.text = profile.totalBudget > 0 
            ? profile.totalBudget.toStringAsFixed(2) 
            : '';

        // Atualizar controllers das categorias
        for (final entry in profile.categoryBudgets.entries) {
          final controller = _categoryControllers[entry.key];
          if (controller != null) {
            controller.text = entry.value > 0 ? entry.value.toStringAsFixed(2) : '';
          }
        }
      }
    } catch (e) {
      print('❌ Erro ao carregar perfil financeiro: $e');
      // Não lançar erro aqui, pois pode ser o primeiro acesso
    }
  }

  void updateIncome(String value) {
    final income = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    monthlyIncome.value = income;
    _checkForChanges();
  }

  void updateTotalBudget(String value) {
    final budget = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    totalBudget.value = budget;
    _checkForChanges();
  }

  void updateCategoryBudget(String categoryId, String value) {
    final budget = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    
    if (budget > 0) {
      categoryBudgets[categoryId] = budget;
    } else {
      categoryBudgets.remove(categoryId);
    }
    
    categoryBudgets.refresh();
    _checkForChanges();
  }

  TextEditingController getCategoryController(String categoryId) {
    return _categoryControllers[categoryId] ?? TextEditingController();
  }

  void _checkForChanges() {
    if (_originalProfile == null) {
      // Novo perfil - tem mudanças se algum campo foi preenchido
      hasUnsavedChanges.value = monthlyIncome.value > 0 || 
                               totalBudget.value > 0 || 
                               categoryBudgets.isNotEmpty;
    } else {
      // Perfil existente - verificar se houve mudanças
      hasUnsavedChanges.value = 
          monthlyIncome.value != _originalProfile!.monthlyIncome ||
          totalBudget.value != _originalProfile!.totalBudget ||
          !_mapsEqual(categoryBudgets, _originalProfile!.categoryBudgets);
    }
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
      Get.snackbar(
        'Dados Incompletos',
        'Preencha pelo menos a renda mensal e o orçamento total.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

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
        categoryBudgets: Map.from(categoryBudgets),
        createdAt: _originalProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _profileService.saveFinancialProfile(profile);

      _originalProfile = profile;
      hasUnsavedChanges.value = false;

      Get.snackbar(
        'Sucesso',
        'Configurações salvas com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Voltar para a tela anterior após salvar
      Get.back();

    } catch (e) {
      print('❌ Erro ao salvar perfil: $e');
      Get.snackbar(
        'Erro',
        'Erro ao salvar configurações. Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }

  // Método para resetar o formulário
  void resetForm() {
    incomeController.clear();
    totalBudgetController.clear();
    
    for (final controller in _categoryControllers.values) {
      controller.clear();
    }

    monthlyIncome.value = 0.0;
    totalBudget.value = 0.0;
    categoryBudgets.clear();
    hasUnsavedChanges.value = false;
  }

  // Método para aplicar um template de orçamento
  void applyBudgetTemplate(String templateName) {
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
  }

  void _apply503020Rule() {
    if (monthlyIncome.value <= 0) return;

    final income = monthlyIncome.value;
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
  }

  void _applyConservativeTemplate() {
    if (monthlyIncome.value <= 0) return;

    final income = monthlyIncome.value;
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
  }
}
