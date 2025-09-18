import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/financial_profile.dart';
import '../../domain/entities/financial_goal.dart';
import '../../domain/entities/financial_insight.dart';
import '../../domain/usecases/get_expenses_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../data/services/financial_profile_service.dart';
import '../../data/services/financial_insights_service.dart';
import '../../../auth/data/services/auth_service.dart';

class EnhancedReportsController extends GetxController {
  // Services
  late final GetExpensesUseCase _getExpensesUseCase;
  late final GetCategoriesUseCase _getCategoriesUseCase;
  late final FinancialProfileService _profileService;
  late final FinancialInsightsService _insightsService;
  late final AuthService _authService;

  // Observable state
  final isLoading = false.obs;
  final selectedPeriod = 'month'.obs; // month, week, year
  final selectedDate = DateTime.now().obs;

  // Data
  final expenses = <Expense>[].obs;
  final categories = <ExpenseCategory>[].obs;
  final financialProfile = Rxn<FinancialProfile>();
  final financialGoals = <FinancialGoal>[].obs;
  final insights = <FinancialInsight>[].obs;

  // Computed values
  final totalSpent = 0.0.obs;
  final budgetUsed = 0.0.obs;
  final budgetRemaining = 0.0.obs;
  final categorySpending = <String, double>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeDependencies();
    loadReportData();
  }

  void _initializeDependencies() {
    _getExpensesUseCase = Get.find<GetExpensesUseCase>();
    _getCategoriesUseCase = Get.find<GetCategoriesUseCase>();
    _profileService = Get.find<FinancialProfileService>();
    _insightsService = Get.find<FinancialInsightsService>();
    _authService = Get.find<AuthService>();
  }

  Future<void> loadReportData() async {
    try {
      isLoading.value = true;

      // Carregar dados em paralelo
      await Future.wait([
        _loadExpenses(),
        _loadCategories(),
        _loadFinancialProfile(),
      ]);

      // Carregar metas baseadas no perfil
      await _loadFinancialGoals();

      // Gerar insights baseados nos dados reais
      _generateInsights();

      // Calcular estatísticas
      _calculateStatistics();

    } catch (e) {
      print('❌ Erro ao carregar dados do relatório: $e');
      Get.snackbar(
        'Erro',
        'Erro ao carregar relatório. Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadExpenses() async {
    try {
      final period = _getDateRange();
      final result = await _getExpensesUseCase.getExpensesByDateRange(
        period.start,
        period.end,
      );
      expenses.value = result;
    } catch (e) {
      print('❌ Erro ao carregar despesas: $e');
      expenses.value = [];
    }
  }

  Future<void> _loadCategories() async {
    try {
      final result = await _getCategoriesUseCase.execute();
      categories.value = result;
    } catch (e) {
      print('❌ Erro ao carregar categorias: $e');
      categories.value = [];
    }
  }

  Future<void> _loadFinancialProfile() async {
    try {
      final profile = await _profileService.getFinancialProfile();
      financialProfile.value = profile;
    } catch (e) {
      print('❌ Erro ao carregar perfil financeiro: $e');
      financialProfile.value = null;
    }
  }

  Future<void> _loadFinancialGoals() async {
    try {
      final currentMonth = DateTime(selectedDate.value.year, selectedDate.value.month);
      final goals = await _profileService.getFinancialGoals(currentMonth);
      
      // Atualizar valores gastos nas metas
      final updatedGoals = <FinancialGoal>[];
      for (final goal in goals) {
        final categoryExpenses = expenses.where((e) => e.categoryId == goal.categoryId);
        final totalSpent = categoryExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
        
        updatedGoals.add(goal.copyWith(currentSpent: totalSpent));
      }
      
      financialGoals.value = updatedGoals;
    } catch (e) {
      print('❌ Erro ao carregar metas financeiras: $e');
      financialGoals.value = [];
    }
  }

  void _generateInsights() {
    try {
      if (financialProfile.value == null) {
        insights.value = [];
        return;
      }

      // Obter despesas do mês anterior para comparação
      final previousMonth = DateTime(selectedDate.value.year, selectedDate.value.month - 1);
      final previousPeriod = DateTimeRange(
        start: DateTime(previousMonth.year, previousMonth.month),
        end: DateTime(previousMonth.year, previousMonth.month + 1),
      );

      // Simular carregamento de despesas do mês anterior (seria uma chamada real)
      final previousExpenses = <Expense>[]; // TODO: Implementar busca real

      final generatedInsights = _insightsService.generateInsights(
        profile: financialProfile.value!,
        goals: financialGoals,
        currentMonthExpenses: expenses,
        previousMonthExpenses: previousExpenses,
        categories: categories,
      );

      insights.value = generatedInsights;
    } catch (e) {
      print('❌ Erro ao gerar insights: $e');
      insights.value = [];
    }
  }

  void _calculateStatistics() {
    // Calcular total gasto
    totalSpent.value = expenses.fold(0.0, (sum, expense) => sum + expense.amount);

    // Calcular gastos por categoria
    final categoryMap = <String, double>{};
    for (final expense in expenses) {
      categoryMap[expense.categoryId] = (categoryMap[expense.categoryId] ?? 0) + expense.amount;
    }
    categorySpending.value = categoryMap;

    // Calcular orçamento usado e restante
    if (financialProfile.value != null) {
      final profile = financialProfile.value!;
      budgetUsed.value = totalSpent.value;
      budgetRemaining.value = profile.totalBudget - totalSpent.value;
    }
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

  ExpenseCategory? getCategoryById(String categoryId) {
    return categories.firstWhereOrNull((cat) => cat.id == categoryId);
  }

  bool get hasFinancialProfile => financialProfile.value != null;
  
  bool get hasGoals => financialGoals.isNotEmpty;
  
  bool get hasInsights => insights.isNotEmpty;

  String get noDataMessage {
    if (!hasFinancialProfile) {
      return 'Configure seu perfil financeiro para ver insights personalizados';
    }
    if (!hasGoals) {
      return 'Defina suas metas financeiras para acompanhar seu progresso';
    }
    if (expenses.isEmpty) {
      return 'Adicione algumas despesas para gerar relatórios';
    }
    return 'Dados carregados com sucesso';
  }
}
