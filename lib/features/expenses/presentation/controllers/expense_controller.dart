import 'package:get/get.dart';
import 'package:flutter/material.dart';
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

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  /// Carrega dados iniciais
  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      await Future.wait([
        loadExpenses(),
        loadCategories(),
        loadStats(),
      ]);
    } catch (e) {
      errorMessage.value = 'Erro ao carregar dados: $e';
      Get.snackbar(
        'Erro',
        'Erro ao carregar dados: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Carrega todas as despesas
  Future<void> loadExpenses() async {
    try {
      print('🎮 [Controller] Carregando despesas...');
      final result = await getExpensesUseCase.getAllExpenses();
      print('🎮 [Controller] Use case retornou ${result.length} despesas');
      
      expenses.value = result;
      print('🎮 [Controller] ✅ Despesas atualizadas no observable: ${expenses.length}');
      
      if (result.isNotEmpty) {
        for (int i = 0; i < result.length && i < 3; i++) {
          final expense = result[i];
          print('🎮 [Controller] Despesa $i: ${expense.description} - R\$ ${expense.amount}');
        }
      }
    } catch (e) {
      print('🎮 [Controller] ❌ ERRO ao carregar despesas: $e');
      throw Exception('Erro ao carregar despesas: $e');
    }
  }

  /// Carrega categorias
  Future<void> loadCategories() async {
    try {
      final result = await categorizeExpenseUseCase.getAllCategories();
      categories.value = result;
      
      // Se não há categorias, algo deu errado - tentar novamente
      if (result.isEmpty) {
        print('⚠️ Nenhuma categoria encontrada, tentando forçar recriação...');
        
        // Tentar forçar recriação das categorias padrão
        try {
          final repository = Get.find<ExpenseRepository>();
          if (repository is ExpenseHybridRepository) {
            await repository.forceRecreateDefaultCategories();
          }
        } catch (e) {
          print('⚠️ Erro ao forçar recriação: $e');
        }
        
        await Future.delayed(const Duration(milliseconds: 500));
        final retryResult = await categorizeExpenseUseCase.getAllCategories();
        categories.value = retryResult;
      }
      
      print('✅ ${categories.length} categorias carregadas');
    } catch (e) {
      print('❌ Erro ao carregar categorias: $e');
      throw Exception('Erro ao carregar categorias: $e');
    }
  }

  /// Carrega estatísticas
  Future<void> loadStats() async {
    try {
      final result = await getExpensesUseCase.getExpenseStats();
      stats.value = result;
    } catch (e) {
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
  }) async {
    try {
      print('🎯 Controller: Iniciando adição de despesa');
      isAddingExpense.value = true;
      errorMessage.value = '';

      print('🎯 Controller: Chamando use case com metas...');
      await addExpenseWithGoalsUseCase.call(
        amount: amount,
        description: description,
        categoryId: categoryId,
        date: date,
        notes: notes,
      );
      print('🎯 Controller: Use case com metas concluído');

      print('🎯 Controller: Voltando para tela anterior imediatamente');
      // Volta para tela anterior IMEDIATAMENTE
      Get.back();

      // Mostra snackbar após voltar
      Get.snackbar(
        'Sucesso',
        'Despesa adicionada com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      print('🎯 Controller: Iniciando reload em background');
      // Recarrega dados em background (sem bloquear a UI)
      _reloadDataInBackground();
    } catch (e) {
      print('❌ Controller: Erro ao adicionar despesa: $e');
      errorMessage.value = e.toString();
      Get.snackbar(
        'Erro',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      print('🎯 Controller: Finalizando (isAddingExpense = false)');
      isAddingExpense.value = false;
    }
  }

  /// Recarrega dados em background sem bloquear a UI
  void _reloadDataInBackground() {
    print('🔄 [Controller] Iniciando reload rápido em background...');
    
    // Executa em background com timeout reduzido para ser mais rápido
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        print('🔄 [Controller] Carregando despesas em background...');
        await loadExpenses().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('⚠️ [Controller] Timeout ao carregar despesas');
          },
        );
        print('🔄 [Controller] ✅ Despesas recarregadas em background');
      } catch (e) {
        print('⚠️ [Controller] Erro ao recarregar despesas: $e');
      }

      // Carregar estatísticas em paralelo (não sequencial)
      Future.delayed(Duration.zero, () async {
        try {
          print('🔄 [Controller] Carregando estatísticas em background...');
          await loadStats().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('⚠️ [Controller] Timeout ao carregar estatísticas');
            },
          );
          print('🔄 [Controller] ✅ Estatísticas recarregadas em background');
        } catch (e) {
          print('⚠️ [Controller] Erro ao recarregar estatísticas: $e');
        }
      });
      
      print('🔄 [Controller] ✅ Reload em background iniciado');
    });
  }

  /// Analisa texto para extrair despesa
  Future<ExpenseAnalysis> analyzeExpenseText(String text) async {
    try {
      return await categorizeExpenseUseCase.analyzeExpenseText(text);
    } catch (e) {
      throw Exception('Erro ao analisar texto: $e');
    }
  }

  /// Sugere categoria baseada na descrição
  Future<String> suggestCategory(String description) async {
    try {
      return await categorizeExpenseUseCase.suggestCategory(description);
    } catch (e) {
      return 'outros';
    }
  }

  /// Busca despesas por texto
  Future<void> searchExpenses(String query) async {
    try {
      searchQuery.value = query;
      
      if (query.trim().isEmpty) {
        await loadExpenses();
      } else {
        final result = await getExpensesUseCase.searchExpenses(query);
        expenses.value = result;
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao buscar despesas: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Filtra despesas por categoria
  Future<void> filterByCategory(String categoryId) async {
    try {
      selectedCategoryFilter.value = categoryId;
      
      if (categoryId.isEmpty) {
        await loadExpenses();
      } else {
        final result = await getExpensesUseCase.getExpensesByCategory(categoryId);
        expenses.value = result;
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao filtrar despesas: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Filtra despesas por período
  Future<void> filterByDateRange(DateTime? start, DateTime? end) async {
    try {
      startDateFilter.value = start;
      endDateFilter.value = end;
      
      if (start == null || end == null) {
        await loadExpenses();
      } else {
        final result = await getExpensesUseCase.getExpensesByDateRange(start, end);
        expenses.value = result;
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao filtrar despesas: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Limpa todos os filtros
  Future<void> clearFilters() async {
    selectedCategoryFilter.value = '';
    searchQuery.value = '';
    startDateFilter.value = null;
    endDateFilter.value = null;
    await loadExpenses();
  }

  /// Carrega despesas do mês atual
  Future<void> loadCurrentMonthExpenses() async {
    try {
      final result = await getExpensesUseCase.getCurrentMonthExpenses();
      expenses.value = result;
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao carregar despesas do mês: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Carrega despesas de hoje
  Future<void> loadTodayExpenses() async {
    try {
      final result = await getExpensesUseCase.getTodayExpenses();
      expenses.value = result;
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao carregar despesas de hoje: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Refresh dos dados
  Future<void> refreshData() async {
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
           endDateFilter.value != null;
  }

  /// Texto do filtro ativo
  String get activeFilterText {
    final filters = <String>[];
    
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
    try {
      return await getExpenseByIdUseCase.call(id);
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao buscar despesa: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
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

      // Recarrega dados
      await Future.wait([
        loadExpenses(),
        loadStats(),
      ]);

      Get.snackbar(
        'Sucesso',
        'Despesa atualizada com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Volta para tela anterior
      Get.back();
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Erro',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isAddingExpense.value = false;
    }
  }

  /// Deleta despesa
  Future<void> deleteExpense(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await deleteExpenseUseCase.call(id);

      // Recarrega dados
      await Future.wait([
        loadExpenses(),
        loadStats(),
      ]);

      Get.snackbar(
        'Sucesso',
        'Despesa excluída com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Erro',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Confirma exclusão de despesa
  Future<void> confirmDeleteExpense(Expense expense) async {
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
              backgroundColor: Colors.red,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (result == true) {
      await deleteExpense(expense.id);
    }
  }
}
