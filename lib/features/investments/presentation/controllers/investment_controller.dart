import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'dart:convert';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/logging_service.dart';
import '../../domain/entities/investment.dart';
import '../../domain/entities/investment_goal.dart';
import '../../domain/repositories/investment_repository.dart';
import '../../../auth/data/services/auth_service.dart';

class InvestmentController extends GetxController {
  // Services
  late final InvestmentRepository _investmentRepository;
  late final AuthService _authService;

  // Controllers
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  final notesController = TextEditingController();
  final institutionController = TextEditingController();
  final expectedReturnController = TextEditingController();
  final monthlyTargetController = TextEditingController();

  // Observable state
  final isLoading = false.obs;
  final isSaving = false.obs;
  
  final investments = <Investment>[].obs;
  final currentMonthInvestments = <Investment>[].obs;
  final investmentGoals = <InvestmentGoal>[].obs;
  
  final selectedType = Rx<InvestmentType>(InvestmentType.savings);
  final selectedDate = Rx<DateTime>(DateTime.now());
  final selectedMaturityDate = Rx<DateTime?>(null);

  // Totais
  final totalInvested = 0.0.obs;
  final totalInvestedThisMonth = 0.0.obs;
  final monthlyTarget = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    AppLogger.info(FeatureTag.expenses, '💰 InvestmentController inicializando');
    _initializeDependencies();
    _loadData();
  }

  @override
  void onClose() {
    AppLogger.debug(FeatureTag.expenses, 'InvestmentController disposing');
    amountController.dispose();
    descriptionController.dispose();
    notesController.dispose();
    institutionController.dispose();
    expectedReturnController.dispose();
    monthlyTargetController.dispose();
    super.onClose();
  }

  void _initializeDependencies() {
    AppLogger.debug(FeatureTag.expenses, 'Inicializando dependências de investimentos');
    _investmentRepository = Get.find<InvestmentRepository>();
    _authService = Get.find<AuthService>();
  }

  Future<void> _loadData() async {
    final opId = AppLogger.startOp(FeatureTag.expenses, 'load_investments_data');
    
    try {
      isLoading.value = true;

      // Carregar todos os investimentos
      await loadInvestments();

      // Carregar investimentos do mês atual
      await loadCurrentMonthInvestments();

      // Calcular totais
      _calculateTotals();
      
      AppLogger.completeOp(opId, message: 'Dados de investimentos carregados', data: {
        'investments_count': investments.length,
        'month_investments_count': currentMonthInvestments.length,
        'total_invested': totalInvested.value,
      });

    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao carregar dados de investimentos', exception: e);
      Get.snackbar(
        'Erro',
        'Erro ao carregar investimentos. Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorError,
        colorText: AppColors.colorTextOnDark,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadInvestments() async {
    AppLogger.debug(FeatureTag.expenses, 'Carregando investimentos');
    
    try {
      final result = await _investmentRepository.getAllInvestments();
      investments.value = result;
      AppLogger.loaded(FeatureTag.expenses, 'investimentos', result.length);
    } catch (e) {
      AppLogger.error(FeatureTag.expenses, 'Erro ao carregar investimentos', error: e);
      investments.value = [];
    }
  }

  Future<void> loadCurrentMonthInvestments() async {
    AppLogger.debug(FeatureTag.expenses, 'Carregando investimentos do mês atual');
    
    try {
      final result = await _investmentRepository.getCurrentMonthInvestments();
      currentMonthInvestments.value = result;
      AppLogger.loaded(FeatureTag.expenses, 'investimentos do mês', result.length);
    } catch (e) {
      AppLogger.error(FeatureTag.expenses, 'Erro ao carregar investimentos do mês', error: e);
      currentMonthInvestments.value = [];
    }
  }

  void _calculateTotals() {
    // Total geral
    totalInvested.value = investments.fold(0.0, (sum, inv) => sum + inv.amount);
    
    // Total do mês
    totalInvestedThisMonth.value = currentMonthInvestments.fold(0.0, (sum, inv) => sum + inv.amount);
    
    AppLogger.debug(FeatureTag.expenses, 'Totais calculados', data: {
      'total_invested': totalInvested.value,
      'total_this_month': totalInvestedThisMonth.value,
    });
  }

  /// Adicionar novo investimento
  Future<bool> addInvestment() async {
    // #region agent log
    _debugLog('H5', 'investment_controller.dart:142', 'addInvestment() STARTED');
    // #endregion
    if (!_validateForm()) return false;

    final opId = AppLogger.startOp(FeatureTag.expenses, 'add_investment');
    
    try {
      isSaving.value = true;
      // #region agent log
      _debugLog('H5', 'investment_controller.dart:150', 'isSaving set to true');
      // #endregion

      final amount = double.tryParse(
        amountController.text.replaceAll('.', '').replaceAll(',', '.')
      ) ?? 0;
      
      final expectedReturn = expectedReturnController.text.isNotEmpty
          ? double.tryParse(expectedReturnController.text.replaceAll(',', '.'))
          : null;

      final investment = Investment.create(
        amount: amount,
        description: descriptionController.text.trim(),
        type: selectedType.value,
        date: selectedDate.value,
        notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
        institution: institutionController.text.trim().isNotEmpty ? institutionController.text.trim() : null,
        expectedReturn: expectedReturn,
        maturityDate: selectedMaturityDate.value,
      );

      // #region agent log
      _debugLog('H5', 'investment_controller.dart:174', 'Before _investmentRepository.addInvestment()', {'amount': amount});
      // #endregion
      await _investmentRepository.addInvestment(investment);
      // #region agent log
      _debugLog('H5', 'investment_controller.dart:178', 'After _investmentRepository.addInvestment()');
      // #endregion
      
      // Recarregar dados
      // #region agent log
      _debugLog('H5', 'investment_controller.dart:182', 'Before _loadData()');
      // #endregion
      await _loadData();
      // #region agent log
      _debugLog('H5', 'investment_controller.dart:186', 'After _loadData()');
      // #endregion
      
      // Limpar formulário
      _clearForm();

      AppLogger.completeOp(opId, message: 'Investimento adicionado', data: {
        'amount': amount,
        'type': selectedType.value.name,
      });

      Get.snackbar(
        'Sucesso!',
        'Investimento de R\$ ${amount.toStringAsFixed(2)} adicionado',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorSuccess,
        colorText: AppColors.colorTextOnDark,
      );

      // #region agent log
      _debugLog('H5', 'investment_controller.dart:206', 'addInvestment() returning TRUE');
      // #endregion
      return true;

    } catch (e) {
      // #region agent log
      _debugLog('H5', 'investment_controller.dart:211', 'addInvestment() EXCEPTION', {'error': e.toString()});
      // #endregion
      AppLogger.failOp(opId, 'Erro ao adicionar investimento', exception: e);
      Get.snackbar(
        'Erro',
        'Erro ao adicionar investimento. Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorError,
        colorText: AppColors.colorTextOnDark,
      );
      return false;
    } finally {
      // #region agent log
      _debugLog('H5', 'investment_controller.dart:224', 'Setting isSaving to false (finally block)');
      // #endregion
      isSaving.value = false;
    }
  }

  /// Editar investimento existente
  Future<bool> updateInvestment(Investment investment) async {
    final opId = AppLogger.startOp(FeatureTag.expenses, 'update_investment', data: {'id': investment.id});
    
    try {
      isSaving.value = true;

      await _investmentRepository.updateInvestment(investment);
      
      // Recarregar dados
      await _loadData();

      AppLogger.completeOp(opId, message: 'Investimento atualizado');

      Get.snackbar(
        'Sucesso!',
        'Investimento atualizado',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorSuccess,
        colorText: AppColors.colorTextOnDark,
      );

      return true;

    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao atualizar investimento', exception: e);
      Get.snackbar(
        'Erro',
        'Erro ao atualizar investimento. Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorError,
        colorText: AppColors.colorTextOnDark,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Deletar investimento
  Future<bool> deleteInvestment(String id) async {
    final opId = AppLogger.startOp(FeatureTag.expenses, 'delete_investment', data: {'id': id});
    
    try {
      await _investmentRepository.deleteInvestment(id);
      
      // Recarregar dados
      await _loadData();

      AppLogger.completeOp(opId, message: 'Investimento deletado');

      Get.snackbar(
        'Sucesso!',
        'Investimento removido',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorSuccess,
        colorText: AppColors.colorTextOnDark,
      );

      return true;

    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao deletar investimento', exception: e);
      Get.snackbar(
        'Erro',
        'Erro ao remover investimento. Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorError,
        colorText: AppColors.colorTextOnDark,
      );
      return false;
    }
  }

  /// Buscar investimentos por tipo
  Future<List<Investment>> getInvestmentsByType(InvestmentType type) async {
    try {
      return await _investmentRepository.getInvestmentsByType(type);
    } catch (e) {
      AppLogger.error(FeatureTag.expenses, 'Erro ao buscar investimentos por tipo', error: e);
      return [];
    }
  }

  /// Buscar investimentos por período
  Future<List<Investment>> getInvestmentsByDateRange(DateTime start, DateTime end) async {
    try {
      return await _investmentRepository.getInvestmentsByDateRange(start, end);
    } catch (e) {
      AppLogger.error(FeatureTag.expenses, 'Erro ao buscar investimentos por período', error: e);
      return [];
    }
  }

  /// Calcular total por tipo
  Map<InvestmentType, double> getTotalsByType() {
    final totals = <InvestmentType, double>{};
    
    for (final investment in investments) {
      totals[investment.type] = (totals[investment.type] ?? 0) + investment.amount;
    }
    
    return totals;
  }

  /// Obter distribuição percentual por tipo
  Map<InvestmentType, double> getDistributionByType() {
    final totals = getTotalsByType();
    final distribution = <InvestmentType, double>{};
    
    if (totalInvested.value > 0) {
      for (final entry in totals.entries) {
        distribution[entry.key] = (entry.value / totalInvested.value) * 100;
      }
    }
    
    return distribution;
  }

  /// Selecionar tipo de investimento
  void selectType(InvestmentType type) {
    selectedType.value = type;
  }

  /// Selecionar data
  void selectDate(DateTime date) {
    selectedDate.value = date;
  }

  /// Selecionar data de vencimento
  void selectMaturityDate(DateTime? date) {
    selectedMaturityDate.value = date;
  }

  bool _validateForm() {
    if (amountController.text.isEmpty) {
      Get.snackbar(
        'Atenção',
        'Informe o valor do investimento',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorWarning,
        colorText: AppColors.colorTextPrimary,
      );
      return false;
    }

    final amount = double.tryParse(
      amountController.text.replaceAll('.', '').replaceAll(',', '.')
    );
    
    if (amount == null || amount <= 0) {
      Get.snackbar(
        'Atenção',
        'Informe um valor válido',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorWarning,
        colorText: AppColors.colorTextPrimary,
      );
      return false;
    }

    if (descriptionController.text.trim().isEmpty) {
      Get.snackbar(
        'Atenção',
        'Informe uma descrição para o investimento',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorWarning,
        colorText: AppColors.colorTextPrimary,
      );
      return false;
    }

    return true;
  }

  void _clearForm() {
    amountController.clear();
    descriptionController.clear();
    notesController.clear();
    institutionController.clear();
    expectedReturnController.clear();
    selectedType.value = InvestmentType.savings;
    selectedDate.value = DateTime.now();
    selectedMaturityDate.value = null;
  }

  /// Atualizar dados (pull to refresh)
  Future<void> refreshData() async {
    await _loadData();
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



