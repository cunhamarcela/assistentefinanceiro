import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/ads_service.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../data/repositories/expense_hybrid_repository.dart';
import '../../domain/usecases/add_expense_usecase.dart';
import '../../domain/usecases/add_expense_with_goals_usecase.dart';
import '../../domain/usecases/update_expense_usecase.dart';
import '../../domain/usecases/delete_expense_usecase.dart';
import '../../domain/usecases/get_expense_by_id_usecase.dart';
import '../../domain/usecases/get_expenses_usecase.dart';
import '../../domain/usecases/categorize_expense_usecase.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/logging_service.dart';

class ExpenseController extends GetxController {
  final AddExpenseUseCase addExpenseUseCase;
  final AddExpenseWithGoalsUseCase addExpenseWithGoalsUseCase;
  final UpdateExpenseUseCase updateExpenseUseCase;
  final DeleteExpenseUseCase deleteExpenseUseCase;
  final GetExpenseByIdUseCase getExpenseByIdUseCase;
  final GetExpensesUseCase getExpensesUseCase;
  final CategorizeExpenseUseCase categorizeExpenseUseCase;

  ExpenseController({
    required this.addExpenseUseCase,
    required this.addExpenseWithGoalsUseCase,
    required this.updateExpenseUseCase,
    required this.deleteExpenseUseCase,
    required this.getExpenseByIdUseCase,
    required this.getExpensesUseCase,
    required this.categorizeExpenseUseCase,
  });

  // Estados observáveis
  final RxList<Expense> expenses = <Expense>[].obs;
  final RxList<ExpenseCategory> categories = <ExpenseCategory>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isAddingExpense = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<ExpenseStats?> stats = Rx<ExpenseStats?>(null);

  // Filtros
  final RxString selectedCategoryFilter = ''.obs;
  final RxString searchQuery = ''.obs;
  final Rx<DateTime?> startDateFilter = Rx<DateTime?>(null);
  final Rx<DateTime?> endDateFilter = Rx<DateTime?>(null);
  final RxString selectedPeriodFilter = 'all'.obs; // today, week, month, all
  final Rx<dynamic> selectedPaymentTypeFilter = Rx<dynamic>(null); // PaymentType ou 'installments'
  
  // Lista filtrada de despesas
  final RxList<Expense> _allExpenses = <Expense>[].obs; // Mantém todas as despesas

  @override
  void onInit() {
    super.onInit();
    AppLogger.info(FeatureTag.expenses, '💰 ExpenseController inicializando');
    loadInitialData();
  }

  /// Carrega dados iniciais
  Future<void> loadInitialData() async {
    final opId = AppLogger.startOp(FeatureTag.expenses, 'load_initial_data');
    
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      AppLogger.state(FeatureTag.expenses, 'loading_initial_data');
      
      await Future.wait([
        loadExpenses(),
        loadCategories(),
        loadStats(),
      ]);
      
      AppLogger.completeOp(opId, message: 'Dados iniciais carregados', data: {
        'expenses_count': expenses.length,
        'categories_count': categories.length,
        'has_stats': stats.value != null,
      });
      
    } catch (e) {
      errorMessage.value = 'Erro ao carregar dados: $e';
      AppLogger.failOp(opId, 'Erro ao carregar dados iniciais', exception: e);
      
      Get.snackbar(
        'Erro',
        'Erro ao carregar dados: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorError,
        colorText: AppColors.colorTextOnDark,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Carrega todas as despesas
  Future<void> loadExpenses() async {
    final opId = AppLogger.startOp(FeatureTag.expenses, 'load_expenses');
    
    try {
      AppLogger.debug(FeatureTag.expenses, 'Carregando despesas...');
      
      final result = await getExpensesUseCase.getAllExpenses();
      
      AppLogger.loaded(FeatureTag.expenses, 'despesas', result.length);
      
      _allExpenses.value = result;
      _applyFilters();
      
      AppLogger.completeOp(opId, data: {'count': result.length});
      
      if (result.isNotEmpty) {
        AppLogger.debug(FeatureTag.expenses, 'Primeiras despesas carregadas', data: {
          'first_3': result.take(3).map((e) => {
            'description': e.description,
            'amount': e.amount,
            'date': e.date.toIso8601String(),
          }).toList(),
        });
      }
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao carregar despesas', exception: e);
      throw Exception('Erro ao carregar despesas: $e');
    }
  }

  /// Carrega categorias
  Future<void> loadCategories() async {
    final opId = AppLogger.startOp(FeatureTag.categories, 'load_categories');
    
    try {
      final result = await categorizeExpenseUseCase.getAllCategories();
      categories.value = result;
      
      AppLogger.loaded(FeatureTag.categories, 'categorias', result.length);
      
      // Se não há categorias, algo deu errado - tentar novamente
      if (result.isEmpty) {
        AppLogger.warning(FeatureTag.categories, 'Nenhuma categoria encontrada, forçando recriação');
        
        // Tentar forçar recriação das categorias padrão
        try {
          final repository = Get.find<ExpenseRepository>();
          if (repository is ExpenseHybridRepository) {
            await repository.forceRecreateDefaultCategories();
            AppLogger.info(FeatureTag.categories, 'Categorias padrão recriadas');
          }
        } catch (e) {
          AppLogger.warning(FeatureTag.categories, 'Erro ao forçar recriação', data: {'error': e.toString()});
        }
        
        await Future.delayed(const Duration(milliseconds: 500));
        final retryResult = await categorizeExpenseUseCase.getAllCategories();
        categories.value = retryResult;
        
        AppLogger.info(FeatureTag.categories, 'Categorias após retry', data: {'count': retryResult.length});
      }
      
      AppLogger.completeOp(opId, data: {'count': categories.length});
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao carregar categorias', exception: e);
      throw Exception('Erro ao carregar categorias: $e');
    }
  }

  /// Carrega estatísticas
  Future<void> loadStats() async {
    final opId = AppLogger.startOp(FeatureTag.expenses, 'load_stats');
    
    try {
      final result = await getExpensesUseCase.getExpenseStats();
      stats.value = result;
      
      AppLogger.debug(FeatureTag.expenses, 'Estatísticas carregadas', data: {
        'total_month': result.totalMonth,
        'expense_count': result.expenseCount,
        'average_per_day': result.averagePerDay,
      });
      
      AppLogger.completeOp(opId);
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao carregar estatísticas', exception: e);
      throw Exception('Erro ao carregar estatísticas: $e');
    }
  }

  /// Adiciona nova despesa
  Future<void> addExpense({
    required double amount,
    required String description,
    String? categoryId,
    DateTime? date,
    String? notes,
    PaymentType paymentType = PaymentType.cash,
    String? creditCardId,
    int? installments,
    double? interestRate,
  }) async {
    final opId = AppLogger.startOp(FeatureTag.expenses, 'add_expense', data: {
      'amount': amount,
      'description': description,
      'category': categoryId,
      'payment_type': paymentType.name,
      'installments': installments,
    });
    
    try {
      AppLogger.action('add_expense', feature: FeatureTag.expenses, data: {
        'amount': amount,
        'description': description,
      });
      
      isAddingExpense.value = true;
      errorMessage.value = '';

      // Se é parcelado, criar múltiplas despesas
      if (installments != null && installments > 1) {
        AppLogger.info(FeatureTag.expenses, 'Criando despesa parcelada', data: {
          'installments': installments,
          'total_amount': amount,
        });
        
        await _addInstallmentExpense(
          amount: amount,
          description: description,
          categoryId: categoryId,
          date: date,
          notes: notes,
          creditCardId: creditCardId,
          installments: installments,
          interestRate: interestRate ?? 0,
        );
        
        AppLogger.info(FeatureTag.expenses, '✅ Despesa parcelada criada', data: {
          'installments': installments,
        });
      } else {
        AppLogger.debug(FeatureTag.expenses, 'Chamando use case para adicionar despesa');
        
        await addExpenseWithGoalsUseCase.call(
          amount: amount,
          description: description,
          categoryId: categoryId,
          date: date,
          notes: notes,
          paymentType: paymentType,
          creditCardId: creditCardId,
        );
      }

      // Registra no analytics
      AppLogger.expenseCreated(amount, description, categoryId ?? 'outros', paymentType.name);
      AppLogger.completeOp(opId, message: 'Despesa adicionada com sucesso');

      // Volta para tela anterior IMEDIATAMENTE
      Get.back();

      // Mostra snackbar após voltar
      Get.snackbar(
        'Sucesso',
        installments != null && installments > 1
            ? 'Despesa parcelada em $installments vezes adicionada com sucesso!'
            : 'Despesa adicionada com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorSuccess,
        colorText: AppColors.colorTextOnDark,
        duration: const Duration(seconds: 2),
      );

      // Mostra interstitial após salvar despesa (não bloqueia a UI)
      _showInterstitialAfterAction();

      // Recarrega dados em background (sem bloquear a UI)
      _reloadDataInBackground();
      
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao adicionar despesa', exception: e);
      errorMessage.value = e.toString();
      
      Get.snackbar(
        'Erro',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorError,
        colorText: AppColors.colorTextOnDark,
      );
    } finally {
      isAddingExpense.value = false;
    }
  }

  /// Adiciona uma despesa parcelada (múltiplas parcelas)
  Future<void> _addInstallmentExpense({
    required double amount,
    required String description,
    String? categoryId,
    DateTime? date,
    String? notes,
    String? creditCardId,
    required int installments,
    required double interestRate,
  }) async {
    AppLogger.debug(FeatureTag.expenses, 'Calculando parcelas', data: {
      'total': amount,
      'installments': installments,
      'interest_rate': interestRate,
    });
    
    // Importar o serviço de parcelamento
    final installmentAmount = _calculateInstallmentAmount(
      totalAmount: amount,
      totalInstallments: installments,
      interestRate: interestRate,
    );
    
    AppLogger.logic(FeatureTag.expenses, 'Cálculo de parcela', input: {
      'total': amount,
      'installments': installments,
      'interest': interestRate,
    }, result: installmentAmount);

    // Criar uma despesa para cada parcela
    for (int i = 1; i <= installments; i++) {
      final installmentDate = DateTime(
        (date ?? DateTime.now()).year,
        (date ?? DateTime.now()).month + (i - 1),
        (date ?? DateTime.now()).day,
      );

      AppLogger.debug(FeatureTag.expenses, 'Criando parcela $i/$installments', data: {
        'amount': installmentAmount,
        'date': installmentDate.toIso8601String(),
      });

      await addExpenseWithGoalsUseCase.call(
        amount: installmentAmount,
        description: '$description ($i/$installments)',
        categoryId: categoryId,
        date: installmentDate,
        notes: notes,
        paymentType: PaymentType.credit,
        creditCardId: creditCardId,
      );
    }
    
    AppLogger.info(FeatureTag.expenses, 'Todas as parcelas criadas', data: {
      'total_parcelas': installments,
      'valor_parcela': installmentAmount,
    });
  }

  /// Calcula o valor de cada parcela
  double _calculateInstallmentAmount({
    required double totalAmount,
    required int totalInstallments,
    required double interestRate,
  }) {
    if (totalInstallments <= 1) {
      return totalAmount;
    }

    if (interestRate == 0) {
      return totalAmount / totalInstallments;
    }

    // Com juros
    final i = interestRate / 100;
    final n = totalInstallments.toDouble();
    
    final pow = _pow(1 + i, n);
    final installmentAmount = totalAmount * (i * pow) / (pow - 1);

    return double.parse(installmentAmount.toStringAsFixed(2));
  }

  /// Função auxiliar para calcular potência
  double _pow(double base, double exponent) {
    if (exponent == 0) return 1;
    if (exponent == 1) return base;
    
    double result = 1;
    for (int i = 0; i < exponent.toInt(); i++) {
      result *= base;
    }
    return result;
  }

  /// Mostra interstitial após ação concluída (não bloqueia a UI)
  void _showInterstitialAfterAction() {
    // Executa com pequeno delay para não interferir na navegação
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        if (Get.isRegistered<AdsService>()) {
          final adsService = Get.find<AdsService>();
          final shown = await adsService.showInterstitialIfAvailable();
          
          if (shown) {
            AppLogger.debug(FeatureTag.expenses, 'Interstitial exibido após salvar despesa');
          } else {
            AppLogger.debug(FeatureTag.expenses, 'Interstitial não disponível');
          }
        }
      } catch (e) {
        AppLogger.warning(FeatureTag.expenses, 'Erro ao mostrar interstitial', data: {
          'error': e.toString(),
        });
      }
    });
  }

  /// Recarrega dados em background sem bloquear a UI
  void _reloadDataInBackground() {
    AppLogger.debug(FeatureTag.expenses, 'Iniciando reload em background');
    
    // Executa em background com timeout reduzido para ser mais rápido
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        final startTime = DateTime.now();
        
        await loadExpenses().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            AppLogger.warning(FeatureTag.expenses, 'Timeout ao carregar despesas em background');
          },
        );
        
        final duration = DateTime.now().difference(startTime);
        AppLogger.debug(FeatureTag.expenses, 'Despesas recarregadas em background', data: {
          'duration_ms': duration.inMilliseconds,
        });
      } catch (e) {
        AppLogger.warning(FeatureTag.expenses, 'Erro ao recarregar despesas em background', data: {
          'error': e.toString(),
        });
      }

      // Carregar estatísticas em paralelo (não sequencial)
      Future.delayed(Duration.zero, () async {
        try {
          await loadStats().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              AppLogger.warning(FeatureTag.expenses, 'Timeout ao carregar estatísticas');
            },
          );
        } catch (e) {
          AppLogger.warning(FeatureTag.expenses, 'Erro ao recarregar estatísticas', data: {
            'error': e.toString(),
          });
        }
      });
    });
  }

  /// Analisa texto para extrair despesa
  Future<ExpenseAnalysis> analyzeExpenseText(String text) async {
    AppLogger.debug(FeatureTag.expenses, 'Analisando texto de despesa', data: {'text_length': text.length});
    
    try {
      final result = await categorizeExpenseUseCase.analyzeExpenseText(text);
      AppLogger.debug(FeatureTag.expenses, 'Análise concluída', data: {
        'has_amount': result.amount != null,
        'description': result.description,
        'suggested_category': result.suggestedCategoryId,
        'is_valid': result.isValid,
      });
      return result;
    } catch (e) {
      AppLogger.error(FeatureTag.expenses, 'Erro ao analisar texto', error: e);
      throw Exception('Erro ao analisar texto: $e');
    }
  }

  /// Sugere categoria baseada na descrição
  Future<String> suggestCategory(String description) async {
    AppLogger.debug(FeatureTag.categories, 'Sugerindo categoria', data: {'description': description});
    
    try {
      final result = await categorizeExpenseUseCase.suggestCategory(description);
      AppLogger.debug(FeatureTag.categories, 'Categoria sugerida', data: {'category': result});
      return result;
    } catch (e) {
      AppLogger.warning(FeatureTag.categories, 'Erro ao sugerir categoria, usando padrão', data: {
        'error': e.toString(),
      });
      return 'outros';
    }
  }

  /// Busca despesas por texto
  Future<void> searchExpenses(String query) async {
    AppLogger.action('search_expenses', feature: FeatureTag.expenses, data: {'query': query});
    
    try {
      searchQuery.value = query;
      
      if (query.trim().isEmpty) {
        await loadExpenses();
      } else {
        final result = await getExpensesUseCase.searchExpenses(query);
        expenses.value = result;
        AppLogger.debug(FeatureTag.expenses, 'Busca concluída', data: {
          'query': query,
          'results': result.length,
        });
      }
    } catch (e) {
      AppLogger.error(FeatureTag.expenses, 'Erro na busca', error: e);
      Get.snackbar(
        'Erro',
        'Erro ao buscar despesas: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorError,
        colorText: AppColors.colorTextOnDark,
      );
    }
  }

  /// Filtra despesas por categoria
  Future<void> filterByCategory(String categoryId) async {
    AppLogger.action('filter_by_category', feature: FeatureTag.expenses, data: {'category_id': categoryId});
    
    try {
      selectedCategoryFilter.value = categoryId;
      
      if (categoryId.isEmpty) {
        await loadExpenses();
      } else {
        final result = await getExpensesUseCase.getExpensesByCategory(categoryId);
        expenses.value = result;
        AppLogger.debug(FeatureTag.expenses, 'Filtro por categoria aplicado', data: {
          'category_id': categoryId,
          'results': result.length,
        });
      }
    } catch (e) {
      AppLogger.error(FeatureTag.expenses, 'Erro ao filtrar por categoria', error: e);
      Get.snackbar(
        'Erro',
        'Erro ao filtrar despesas: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorError,
        colorText: AppColors.colorTextOnDark,
      );
    }
  }

  /// Filtra despesas por período
  Future<void> filterByDateRange(DateTime? start, DateTime? end) async {
    AppLogger.action('filter_by_date_range', feature: FeatureTag.expenses, data: {
      'start': start?.toIso8601String(),
      'end': end?.toIso8601String(),
    });
    
    try {
      startDateFilter.value = start;
      endDateFilter.value = end;
      
      if (start == null || end == null) {
        await loadExpenses();
      } else {
        final result = await getExpensesUseCase.getExpensesByDateRange(start, end);
        expenses.value = result;
        AppLogger.debug(FeatureTag.expenses, 'Filtro por data aplicado', data: {
          'results': result.length,
        });
      }
    } catch (e) {
      AppLogger.error(FeatureTag.expenses, 'Erro ao filtrar por data', error: e);
      Get.snackbar(
        'Erro',
        'Erro ao filtrar despesas: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorError,
        colorText: AppColors.colorTextOnDark,
      );
    }
  }

  /// Limpa todos os filtros
  Future<void> clearFilters() async {
    AppLogger.action('clear_filters', feature: FeatureTag.expenses);
    
    selectedCategoryFilter.value = '';
    searchQuery.value = '';
    startDateFilter.value = null;
    endDateFilter.value = null;
    selectedPeriodFilter.value = 'all';
    selectedPaymentTypeFilter.value = null;
    
    await loadExpenses();
    
    AppLogger.debug(FeatureTag.expenses, 'Filtros limpos');
  }

  /// Filtra despesas por período
  void filterByPeriod(String period) {
    AppLogger.action('filter_by_period', feature: FeatureTag.expenses, data: {'period': period});
    selectedPeriodFilter.value = period;
    _applyFilters();
  }

  /// Filtra despesas por tipo de pagamento
  void filterByPaymentType(dynamic type) {
    AppLogger.action('filter_by_payment_type', feature: FeatureTag.expenses, data: {
      'type': type?.toString(),
    });
    selectedPaymentTypeFilter.value = type;
    _applyFilters();
  }

  /// Aplica todos os filtros ativos
  void _applyFilters() {
    var filtered = List<Expense>.from(_allExpenses);
    final activeFilters = <String>[];

    // Filtro por período
    if (selectedPeriodFilter.value != 'all') {
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate;
      
      switch (selectedPeriodFilter.value) {
        case 'today':
          startDate = DateTime(now.year, now.month, now.day);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          filtered = filtered.where((e) => 
            e.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            e.date.isBefore(endDate.add(const Duration(days: 1)))
          ).toList();
          activeFilters.add('period:today');
          break;
        case 'week':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          endDate = startDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
          filtered = filtered.where((e) => 
            e.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            e.date.isBefore(endDate.add(const Duration(days: 1)))
          ).toList();
          activeFilters.add('period:week');
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, 1);
          // Último dia do mês atual
          endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          filtered = filtered.where((e) => 
            e.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            e.date.isBefore(endDate.add(const Duration(days: 1)))
          ).toList();
          activeFilters.add('period:month');
          break;
      }
    }

    // Filtro por tipo de pagamento
    if (selectedPaymentTypeFilter.value != null) {
      if (selectedPaymentTypeFilter.value == 'installments') {
        // Apenas despesas parceladas
        filtered = filtered.where((e) => e.isInstallment).toList();
        activeFilters.add('type:installments');
      } else if (selectedPaymentTypeFilter.value is PaymentType) {
        // Tipo de pagamento específico
        filtered = filtered.where((e) => 
          e.paymentType == selectedPaymentTypeFilter.value
        ).toList();
        activeFilters.add('type:${(selectedPaymentTypeFilter.value as PaymentType).name}');
      }
    }

    // Filtro por categoria (se existir)
    if (selectedCategoryFilter.value.isNotEmpty) {
      filtered = filtered.where((e) => 
        e.categoryId == selectedCategoryFilter.value
      ).toList();
      activeFilters.add('category:${selectedCategoryFilter.value}');
    }

    // Filtro por busca (se existir)
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((e) => 
        e.description.toLowerCase().contains(query) ||
        (e.notes?.toLowerCase().contains(query) ?? false)
      ).toList();
      activeFilters.add('search:${searchQuery.value}');
    }

    // Filtro por data range (se existir)
    if (startDateFilter.value != null && endDateFilter.value != null) {
      filtered = filtered.where((e) =>
        e.date.isAfter(startDateFilter.value!.subtract(const Duration(days: 1))) &&
        e.date.isBefore(endDateFilter.value!.add(const Duration(days: 1)))
      ).toList();
      activeFilters.add('date_range');
    }

    expenses.value = filtered;
    
    AppLogger.debug(FeatureTag.expenses, 'Filtros aplicados', data: {
      'active_filters': activeFilters,
      'original_count': _allExpenses.length,
      'filtered_count': filtered.length,
    });
  }

  /// Carrega despesas do mês atual
  Future<void> loadCurrentMonthExpenses() async {
    AppLogger.debug(FeatureTag.expenses, 'Carregando despesas do mês atual');
    
    try {
      final result = await getExpensesUseCase.getCurrentMonthExpenses();
      expenses.value = result;
      AppLogger.loaded(FeatureTag.expenses, 'despesas do mês', result.length);
    } catch (e) {
      AppLogger.error(FeatureTag.expenses, 'Erro ao carregar despesas do mês', error: e);
      Get.snackbar(
        'Erro',
        'Erro ao carregar despesas do mês: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorError,
        colorText: AppColors.colorTextOnDark,
      );
    }
  }

  /// Carrega despesas de hoje
  Future<void> loadTodayExpenses() async {
    AppLogger.debug(FeatureTag.expenses, 'Carregando despesas de hoje');
    
    try {
      final result = await getExpensesUseCase.getTodayExpenses();
      expenses.value = result;
      AppLogger.loaded(FeatureTag.expenses, 'despesas de hoje', result.length);
    } catch (e) {
      AppLogger.error(FeatureTag.expenses, 'Erro ao carregar despesas de hoje', error: e);
      Get.snackbar(
        'Erro',
        'Erro ao carregar despesas de hoje: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorError,
        colorText: AppColors.colorTextOnDark,
      );
    }
  }

  /// Refresh dos dados
  Future<void> refreshData() async {
    AppLogger.action('refresh_data', feature: FeatureTag.expenses);
    await loadInitialData();
  }

  /// Busca categoria por ID
  ExpenseCategory? getCategoryById(String id) {
    try {
      return categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Verifica se há filtros ativos
  bool get hasActiveFilters {
    return selectedCategoryFilter.value.isNotEmpty ||
           searchQuery.value.isNotEmpty ||
           startDateFilter.value != null ||
           endDateFilter.value != null ||
           selectedPeriodFilter.value != 'all' ||
           selectedPaymentTypeFilter.value != null;
  }

  /// Texto do filtro ativo
  String get activeFilterText {
    final filters = <String>[];
    
    // Filtro de período
    if (selectedPeriodFilter.value != 'all') {
      switch (selectedPeriodFilter.value) {
        case 'today':
          filters.add('Período: Hoje');
          break;
        case 'week':
          filters.add('Período: Esta Semana');
          break;
        case 'month':
          filters.add('Período: Este Mês');
          break;
      }
    }
    
    // Filtro de tipo de pagamento
    if (selectedPaymentTypeFilter.value != null) {
      if (selectedPaymentTypeFilter.value == 'installments') {
        filters.add('Tipo: Parceladas');
      } else if (selectedPaymentTypeFilter.value is PaymentType) {
        final type = selectedPaymentTypeFilter.value as PaymentType;
        switch (type) {
          case PaymentType.credit:
            filters.add('Tipo: Crédito');
            break;
          case PaymentType.debit:
            filters.add('Tipo: Débito');
            break;
          case PaymentType.cash:
            filters.add('Tipo: Dinheiro');
            break;
          case PaymentType.pix:
            filters.add('Tipo: PIX');
            break;
          case PaymentType.other:
            filters.add('Tipo: Outro');
            break;
        }
      }
    }
    
    if (selectedCategoryFilter.value.isNotEmpty) {
      final category = getCategoryById(selectedCategoryFilter.value);
      if (category != null) {
        filters.add('Categoria: ${category.name}');
      }
    }
    
    if (searchQuery.value.isNotEmpty) {
      filters.add('Busca: ${searchQuery.value}');
    }
    
    if (startDateFilter.value != null && endDateFilter.value != null) {
      filters.add('Período selecionado');
    }
    
    return filters.join(' • ');
  }

  /// Busca despesa por ID
  Future<Expense?> getExpenseById(String id) async {
    AppLogger.debug(FeatureTag.expenses, 'Buscando despesa por ID', data: {'id': id});
    
    try {
      final result = await getExpenseByIdUseCase.call(id);
      if (result != null) {
        AppLogger.debug(FeatureTag.expenses, 'Despesa encontrada', data: {
          'description': result.description,
          'amount': result.amount,
        });
      } else {
        AppLogger.warning(FeatureTag.expenses, 'Despesa não encontrada', data: {'id': id});
      }
      return result;
    } catch (e) {
      AppLogger.error(FeatureTag.expenses, 'Erro ao buscar despesa', error: e);
      Get.snackbar(
        'Erro',
        'Erro ao buscar despesa: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorError,
        colorText: AppColors.colorTextOnDark,
      );
      return null;
    }
  }

  /// Atualiza despesa existente
  Future<void> updateExpense({
    required String id,
    required double amount,
    required String description,
    required String categoryId,
    required DateTime date,
    String? notes,
  }) async {
    final opId = AppLogger.startOp(FeatureTag.expenses, 'update_expense', data: {
      'id': id,
      'amount': amount,
      'description': description,
    });
    
    try {
      isAddingExpense.value = true;
      errorMessage.value = '';

      await updateExpenseUseCase.call(
        id: id,
        amount: amount,
        description: description,
        categoryId: categoryId,
        date: date,
        notes: notes,
      );

      AppLogger.expenseUpdated(id, amount);
      AppLogger.completeOp(opId, message: 'Despesa atualizada');

      // Recarrega dados
      await Future.wait([
        loadExpenses(),
        loadStats(),
      ]);

      Get.snackbar(
        'Sucesso',
        'Despesa atualizada com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorSuccess,
        colorText: AppColors.colorTextOnDark,
      );

      // Volta para tela anterior
      Get.back();
    } catch (e) {
      errorMessage.value = e.toString();
      AppLogger.failOp(opId, 'Erro ao atualizar despesa', exception: e);
      Get.snackbar(
        'Erro',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorError,
        colorText: AppColors.colorTextOnDark,
      );
    } finally {
      isAddingExpense.value = false;
    }
  }

  /// Deleta despesa
  Future<void> deleteExpense(String id) async {
    final opId = AppLogger.startOp(FeatureTag.expenses, 'delete_expense', data: {'id': id});
    
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await deleteExpenseUseCase.call(id);

      AppLogger.expenseDeleted(id);
      AppLogger.completeOp(opId, message: 'Despesa excluída');

      // Recarrega dados
      await Future.wait([
        loadExpenses(),
        loadStats(),
      ]);

      Get.snackbar(
        'Sucesso',
        'Despesa excluída com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorSuccess,
        colorText: AppColors.colorTextOnDark,
      );
    } catch (e) {
      errorMessage.value = e.toString();
      AppLogger.failOp(opId, 'Erro ao excluir despesa', exception: e);
      Get.snackbar(
        'Erro',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorError,
        colorText: AppColors.colorTextOnDark,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Confirma exclusão de despesa
  Future<void> confirmDeleteExpense(Expense expense) async {
    AppLogger.action('confirm_delete_expense', feature: FeatureTag.expenses, data: {
      'id': expense.id,
      'description': expense.description,
    });
    
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir a despesa "${expense.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.colorError,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (result == true) {
      await deleteExpense(expense.id);
    } else {
      AppLogger.debug(FeatureTag.expenses, 'Exclusão cancelada pelo usuário');
    }
  }
}
