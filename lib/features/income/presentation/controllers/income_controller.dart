import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'dart:convert';
import '../../domain/entities/income.dart';
import '../../domain/repositories/income_repository.dart';
import '../../data/models/income_model.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/logging_service.dart';

/// Controller para gerenciamento de receitas
class IncomeController extends GetxController {
  final IncomeRepository _repository;
  final AnalyticsService? _analyticsService;

  IncomeController({
    required IncomeRepository repository,
    AnalyticsService? analyticsService,
  })  : _repository = repository,
        _analyticsService = analyticsService;

  // Estados observáveis
  final RxList<Income> incomes = <Income>[].obs;
  final RxList<Income> currentMonthIncomes = <Income>[].obs;
  final RxList<Income> recurringIncomes = <Income>[].obs;
  
  // Totais
  final RxDouble totalIncome = 0.0.obs;
  final RxDouble currentMonthTotal = 0.0.obs;
  
  // Agrupamentos
  final RxMap<IncomeType, double> incomesByType = <IncomeType, double>{}.obs;
  
  // Estados de UI
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Filtros
  final Rx<DateTime?> startDateFilter = Rx<DateTime?>(null);
  final Rx<DateTime?> endDateFilter = Rx<DateTime?>(null);
  final Rx<IncomeType?> typeFilter = Rx<IncomeType?>(null);

  @override
  void onInit() {
    super.onInit();
    AppLogger.info(FeatureTag.income, '💵 IncomeController inicializando');
    loadIncomes();
    _setupListeners();
  }

  /// Configura listeners para atualizações em tempo real
  void _setupListeners() {
    AppLogger.debug(FeatureTag.income, 'Configurando listeners de receitas');
    
    // Listener para receitas do mês atual
    _repository.watchCurrentMonthIncomes().listen((data) {
      currentMonthIncomes.value = data;
      _calculateCurrentMonthTotal();
      AppLogger.debug(FeatureTag.income, 'Receitas do mês atualizadas', data: {'count': data.length});
    });

    // Listener para todas as receitas
    _repository.watchAllIncomes().listen((data) {
      incomes.value = data;
      _calculateTotals();
      _groupByType();
      AppLogger.debug(FeatureTag.income, 'Todas receitas atualizadas', data: {'count': data.length});
    });
  }

  /// Carrega todas as receitas
  Future<void> loadIncomes() async {
    final opId = AppLogger.startOp(FeatureTag.income, 'load_incomes');
    
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final allIncomes = await _repository.getAllIncomes();
      incomes.value = allIncomes;
      AppLogger.loaded(FeatureTag.income, 'receitas', allIncomes.length);

      final monthIncomes = await _repository.getCurrentMonthIncomes();
      currentMonthIncomes.value = monthIncomes;
      AppLogger.debug(FeatureTag.income, 'Receitas do mês carregadas', data: {'count': monthIncomes.length});

      final recurring = await _repository.getRecurringIncomes();
      recurringIncomes.value = recurring;
      AppLogger.debug(FeatureTag.income, 'Receitas recorrentes carregadas', data: {'count': recurring.length});

      _calculateTotals();
      _groupByType();
      
      AppLogger.completeOp(opId, message: 'Receitas carregadas', data: {
        'total': allIncomes.length,
        'month': monthIncomes.length,
        'recurring': recurring.length,
        'total_amount': totalIncome.value,
      });

    } catch (e) {
      errorMessage.value = 'Erro ao carregar receitas: $e';
      AppLogger.failOp(opId, 'Erro ao carregar receitas', exception: e);
      _showError('Erro ao carregar receitas', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Adiciona uma nova receita
  Future<bool> addIncome(Income income) async {
    // #region agent log
    _debugLog('H4', 'income_controller.dart:110', 'addIncome() STARTED', {'amount': income.amount});
    // #endregion
    final opId = AppLogger.startOp(FeatureTag.income, 'add_income', data: {
      'amount': income.amount,
      'type': income.type.name,
      'is_recurring': income.isRecurring,
    });
    
    try {
      isLoading.value = true;
      // #region agent log
      _debugLog('H4', 'income_controller.dart:120', 'isLoading set to true');
      // #endregion
      
      // #region agent log
      _debugLog('H4', 'income_controller.dart:124', 'Before _repository.addIncome()');
      // #endregion
      await _repository.addIncome(income);
      // #region agent log
      _debugLog('H4', 'income_controller.dart:128', 'After _repository.addIncome()');
      // #endregion
      
      // NÃO atualiza lista local manualmente - os listeners já fazem isso automaticamente
      // Isso evita duplicação quando o Firestore notifica a mudança

      // Analytics
      _analyticsService?.trackCustomEvent(
        name: 'income_added',
        properties: {
          'type': income.type.name,
          'amount': income.amount,
          'is_recurring': income.isRecurring,
        },
      );
      
      AppLogger.incomeCreated(income.amount, income.type.name);
      AppLogger.completeOp(opId, message: 'Receita adicionada', data: {
        'id': income.id,
        'amount': income.amount,
      });

      _showSuccess('Receita adicionada com sucesso!');
      // #region agent log
      _debugLog('H4', 'income_controller.dart:160', 'addIncome() returning TRUE');
      // #endregion
      return true;
    } catch (e) {
      // #region agent log
      _debugLog('H4', 'income_controller.dart:164', 'addIncome() EXCEPTION', {'error': e.toString()});
      // #endregion
      errorMessage.value = 'Erro ao adicionar receita: $e';
      AppLogger.failOp(opId, 'Erro ao adicionar receita', exception: e);
      _showError('Erro ao adicionar receita', e.toString());
      return false;
    } finally {
      // #region agent log
      _debugLog('H4', 'income_controller.dart:172', 'Setting isLoading to false (finally block)');
      // #endregion
      isLoading.value = false;
    }
  }

  /// Atualiza uma receita existente
  Future<bool> updateIncome(Income income) async {
    final opId = AppLogger.startOp(FeatureTag.income, 'update_income', data: {
      'id': income.id,
      'amount': income.amount,
    });
    
    try {
      isLoading.value = true;
      
      await _repository.updateIncome(income);
      
      // Atualiza lista local
      final index = incomes.indexWhere((i) => i.id == income.id);
      if (index != -1) {
        incomes[index] = income;
      }
      
      _updateMonthAndRecurringLists();
      _calculateTotals();
      _groupByType();

      AppLogger.saved(FeatureTag.income, 'receita', id: income.id, data: {'action': 'update'});
      AppLogger.completeOp(opId, message: 'Receita atualizada');

      _showSuccess('Receita atualizada com sucesso!');
      return true;
    } catch (e) {
      errorMessage.value = 'Erro ao atualizar receita: $e';
      AppLogger.failOp(opId, 'Erro ao atualizar receita', exception: e);
      _showError('Erro ao atualizar receita', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Remove uma receita
  Future<bool> deleteIncome(String id) async {
    final opId = AppLogger.startOp(FeatureTag.income, 'delete_income', data: {'id': id});
    
    try {
      isLoading.value = true;
      
      await _repository.deleteIncome(id);
      
      // Remove da lista local
      incomes.removeWhere((i) => i.id == id);
      currentMonthIncomes.removeWhere((i) => i.id == id);
      recurringIncomes.removeWhere((i) => i.id == id);
      
      _calculateTotals();
      _groupByType();

      AppLogger.deleted(FeatureTag.income, 'receita', id);
      AppLogger.completeOp(opId, message: 'Receita removida');

      _showSuccess('Receita removida com sucesso!');
      return true;
    } catch (e) {
      errorMessage.value = 'Erro ao remover receita: $e';
      AppLogger.failOp(opId, 'Erro ao remover receita', exception: e);
      _showError('Erro ao remover receita', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Cria uma nova receita usando factory
  Future<bool> createIncome({
    required double amount,
    required String description,
    required IncomeType type,
    DateTime? date,
    String? notes,
    bool isRecurring = false,
    RecurrenceInfo? recurrenceInfo,
  }) async {
    AppLogger.action('create_income', feature: FeatureTag.income, data: {
      'amount': amount,
      'type': type.name,
      'is_recurring': isRecurring,
    });
    
    final income = IncomeModel.create(
      amount: amount,
      description: description,
      type: type,
      date: date,
      notes: notes,
      isRecurring: isRecurring,
      recurrenceInfo: recurrenceInfo,
    );

    return addIncome(income.toEntity());
  }

  /// Filtra receitas por período
  Future<List<Income>> filterByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    AppLogger.action('filter_income_by_date', feature: FeatureTag.income, data: {
      'start': startDate.toIso8601String(),
      'end': endDate.toIso8601String(),
    });
    
    startDateFilter.value = startDate;
    endDateFilter.value = endDate;
    
    final result = await _repository.getIncomesByDateRange(
      startDate: startDate,
      endDate: endDate,
    );
    
    AppLogger.debug(FeatureTag.income, 'Receitas filtradas por período', data: {
      'results': result.length,
    });
    
    return result;
  }

  /// Filtra receitas por tipo
  List<Income> filterByType(IncomeType type) {
    AppLogger.action('filter_income_by_type', feature: FeatureTag.income, data: {
      'type': type.name,
    });
    
    typeFilter.value = type;
    final result = incomes.where((i) => i.type == type).toList();
    
    AppLogger.debug(FeatureTag.income, 'Receitas filtradas por tipo', data: {
      'type': type.name,
      'results': result.length,
    });
    
    return result;
  }

  /// Limpa filtros
  void clearFilters() {
    AppLogger.action('clear_income_filters', feature: FeatureTag.income);
    startDateFilter.value = null;
    endDateFilter.value = null;
    typeFilter.value = null;
  }

  /// Calcula totais
  void _calculateTotals() {
    totalIncome.value = incomes.fold(0.0, (sum, income) => sum + income.amount);
    _calculateCurrentMonthTotal();
    
    AppLogger.debug(FeatureTag.income, 'Totais calculados', data: {
      'total': totalIncome.value,
      'month': currentMonthTotal.value,
    });
  }

  void _calculateCurrentMonthTotal() {
    currentMonthTotal.value = currentMonthIncomes.fold(
      0.0, 
      (sum, income) => sum + income.amount,
    );
  }

  /// Agrupa receitas por tipo
  void _groupByType() {
    final grouped = <IncomeType, double>{};
    
    for (final income in incomes) {
      grouped[income.type] = (grouped[income.type] ?? 0) + income.amount;
    }
    
    incomesByType.value = grouped;
    
    AppLogger.debug(FeatureTag.income, 'Receitas agrupadas por tipo', data: {
      'types_count': grouped.length,
    });
  }

  /// Atualiza listas de mês atual e recorrentes
  void _updateMonthAndRecurringLists() {
    currentMonthIncomes.value = incomes.where((i) => i.isThisMonth).toList();
    recurringIncomes.value = incomes.where((i) => i.isRecurring).toList();
  }

  /// Obtém receitas de hoje
  List<Income> get todayIncomes => incomes.where((i) => i.isToday).toList();

  /// Obtém receitas desta semana
  List<Income> get thisWeekIncomes => incomes.where((i) => i.isThisWeek).toList();

  /// Obtém total de receitas de hoje
  double get todayTotal => todayIncomes.fold(0.0, (sum, i) => sum + i.amount);

  /// Obtém total de receitas desta semana
  double get thisWeekTotal => thisWeekIncomes.fold(0.0, (sum, i) => sum + i.amount);

  /// Mostra mensagem de sucesso
  void _showSuccess(String message) {
    Get.snackbar(
      'Sucesso',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// Mostra mensagem de erro
  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
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
