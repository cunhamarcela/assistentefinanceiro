import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_datasource.dart';
import '../datasources/expense_firestore_datasource.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/logging_service.dart';

/// Repositório híbrido que sincroniza dados entre SQLite local e Firestore
class ExpenseHybridRepository implements ExpenseRepository {
  final ExpenseLocalDataSource localDataSource;
  final ExpenseFirestoreDataSource firestoreDataSource;

  ExpenseHybridRepository({
    required this.localDataSource,
    required this.firestoreDataSource,
  });

  // ==================== DESPESAS ====================

  @override
  Future<void> addExpense(Expense expense) async {
    final opId = AppLogger.startOp(FeatureTag.expenses, 'add_expense_repo', data: {
      'description': expense.description,
      'amount': expense.amount,
    });
    
    final expenseModel = ExpenseModel.fromEntity(expense);
    
    try {
      // Salvar localmente primeiro (para funcionar offline)
      AppLogger.debug(FeatureTag.database, 'Salvando despesa localmente');
      await localDataSource.insertExpense(expenseModel);
      
      AppLogger.saved(FeatureTag.expenses, 'despesa', id: expense.id, data: {
        'source': 'local',
        'amount': expense.amount,
      });
      
      AppLogger.completeOp(opId, message: 'Despesa salva localmente');
      
      // Salvar no Firestore em background (não bloquear retorno)
      _saveToFirestoreInBackground(expenseModel);
      
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao adicionar despesa', exception: e);
      throw Exception('Erro ao adicionar despesa: $e');
    }
  }

  /// Salva no Firestore em background sem bloquear a UI
  void _saveToFirestoreInBackground(ExpenseModel expenseModel) {
    Future.delayed(Duration.zero, () async {
      final startTime = DateTime.now();
      AppLogger.syncStart('despesa', source: 'firestore');
      
      try {
        await firestoreDataSource.saveExpense(expenseModel);
        
        final duration = DateTime.now().difference(startTime);
        AppLogger.syncComplete('despesa', synced: 1, duration: duration);
        
      } catch (e) {
        AppLogger.syncFail('despesa', 'Firestore indisponível', error: e);
        // TODO: Implementar fila de sincronização para tentar novamente depois
      }
    });
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final opId = AppLogger.startOp(FeatureTag.expenses, 'update_expense_repo', data: {
      'id': expense.id,
      'description': expense.description,
    });
    
    final expenseModel = ExpenseModel.fromEntity(expense);
    
    try {
      // Atualizar localmente primeiro (offline-first)
      AppLogger.debug(FeatureTag.database, 'Atualizando despesa localmente');
      await localDataSource.updateExpense(expenseModel);
      
      AppLogger.saved(FeatureTag.expenses, 'despesa', id: expense.id, data: {
        'action': 'update',
        'source': 'local',
      });
      
      // Atualizar no Firestore em background
      _updateToFirestoreInBackground(expenseModel);
      
      AppLogger.completeOp(opId, message: 'Despesa atualizada');
      
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao atualizar despesa', exception: e);
      throw Exception('Erro ao atualizar despesa: $e');
    }
  }

  /// Atualiza no Firestore em background sem bloquear a UI
  void _updateToFirestoreInBackground(ExpenseModel expenseModel) {
    Future.delayed(Duration.zero, () async {
      AppLogger.syncStart('despesa_update', source: 'firestore');
      
      try {
        await firestoreDataSource.updateExpense(expenseModel);
        AppLogger.syncComplete('despesa_update', synced: 1);
      } catch (e) {
        AppLogger.syncFail('despesa_update', 'Firestore indisponível', error: e);
      }
    });
  }

  @override
  Future<void> deleteExpense(String id) async {
    final opId = AppLogger.startOp(FeatureTag.expenses, 'delete_expense_repo', data: {'id': id});
    
    try {
      // Deletar localmente primeiro (offline-first)
      AppLogger.debug(FeatureTag.database, 'Deletando despesa localmente');
      await localDataSource.deleteExpense(id);
      
      AppLogger.deleted(FeatureTag.expenses, 'despesa', id);
      
      // Deletar no Firestore em background
      _deleteFromFirestoreInBackground(id);
      
      AppLogger.completeOp(opId, message: 'Despesa deletada');
      
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao deletar despesa', exception: e);
      throw Exception('Erro ao deletar despesa: $e');
    }
  }
  
  /// Deleta do Firestore em background sem bloquear a UI
  void _deleteFromFirestoreInBackground(String expenseId) {
    Future.delayed(Duration.zero, () async {
      AppLogger.syncStart('despesa_delete', source: 'firestore');
      
      try {
        await firestoreDataSource.deleteExpense(expenseId);
        AppLogger.syncComplete('despesa_delete', synced: 1);
      } catch (e) {
        AppLogger.syncFail('despesa_delete', 'Firestore indisponível', error: e);
      }
    });
  }

  @override
  Future<Expense?> getExpenseById(String id) async {
    AppLogger.debug(FeatureTag.expenses, 'Buscando despesa por ID', data: {'id': id});
    
    try {
      // Tentar buscar localmente primeiro (mais rápido)
      final localExpense = await localDataSource.getExpenseById(id);
      if (localExpense != null) {
        AppLogger.cached('despesa', count: 1, source: 'sqlite');
        return localExpense.toEntity();
      }
      
      // Se não encontrar localmente, buscar no Firestore
      AppLogger.debug(FeatureTag.sync, 'Despesa não encontrada localmente, buscando no Firestore');
      final firestoreExpense = await firestoreDataSource.getExpenseById(id);
      if (firestoreExpense != null) {
        // Salvar localmente para próximas consultas
        await localDataSource.insertExpense(firestoreExpense);
        AppLogger.info(FeatureTag.sync, 'Despesa recuperada do Firestore e cacheada', data: {'id': id});
        return firestoreExpense.toEntity();
      }
      
      AppLogger.warning(FeatureTag.expenses, 'Despesa não encontrada', data: {'id': id});
      return null;
    } catch (e) {
      AppLogger.error(FeatureTag.expenses, 'Erro ao buscar despesa', error: e, data: {'id': id});
      return null;
    }
  }

  @override
  Future<List<Expense>> getAllExpenses() async {
    final opId = AppLogger.startOp(FeatureTag.expenses, 'get_all_expenses');
    
    try {
      // Buscar dados locais primeiro
      final localExpenses = await localDataSource.getAllExpenses();
      
      AppLogger.cached('despesas', count: localExpenses.length, source: 'sqlite');
      
      // Tentar sincronizar com Firestore em background
      _syncInBackground();
      
      AppLogger.completeOp(opId, data: {'count': localExpenses.length});
      return localExpenses.map((model) => model.toEntity()).toList();
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao buscar despesas', exception: e);
      return [];
    }
  }

  @override
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    AppLogger.debug(FeatureTag.expenses, 'Buscando despesas por período', data: {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    });
    
    try {
      final localExpenses = await localDataSource.getExpensesByDateRange(start, end);
      AppLogger.loaded(FeatureTag.expenses, 'despesas por período', localExpenses.length);
      return localExpenses.map((model) => model.toEntity()).toList();
    } catch (e) {
      AppLogger.error(FeatureTag.expenses, 'Erro ao buscar despesas por período', error: e);
      return [];
    }
  }

  @override
  Future<List<Expense>> getExpensesByCategory(String categoryId) async {
    AppLogger.debug(FeatureTag.expenses, 'Buscando despesas por categoria', data: {'category_id': categoryId});
    
    try {
      final localExpenses = await localDataSource.getExpensesByCategory(categoryId);
      AppLogger.loaded(FeatureTag.expenses, 'despesas por categoria', localExpenses.length);
      return localExpenses.map((model) => model.toEntity()).toList();
    } catch (e) {
      AppLogger.error(FeatureTag.expenses, 'Erro ao buscar despesas por categoria', error: e);
      return [];
    }
  }

  @override
  Future<List<Expense>> getCurrentMonthExpenses() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    AppLogger.debug(FeatureTag.expenses, 'Carregando despesas do mês atual');
    return getExpensesByDateRange(startOfMonth, endOfMonth);
  }

  @override
  Future<List<Expense>> getTodayExpenses() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    AppLogger.debug(FeatureTag.expenses, 'Carregando despesas de hoje');
    return getExpensesByDateRange(startOfDay, endOfDay);
  }

  @override
  Future<double> getTotalByDateRange(DateTime start, DateTime end) async {
    try {
      final total = await localDataSource.getTotalByDateRange(start, end);
      AppLogger.debug(FeatureTag.expenses, 'Total calculado por período', data: {'total': total});
      return total;
    } catch (e) {
      AppLogger.error(FeatureTag.expenses, 'Erro ao calcular total por período', error: e);
      return 0.0;
    }
  }

  @override
  Future<double> getTotalByCategory(String categoryId) async {
    try {
      final total = await localDataSource.getTotalByCategory(categoryId);
      AppLogger.debug(FeatureTag.expenses, 'Total calculado por categoria', data: {
        'category_id': categoryId,
        'total': total,
      });
      return total;
    } catch (e) {
      AppLogger.error(FeatureTag.expenses, 'Erro ao calcular total por categoria', error: e);
      return 0.0;
    }
  }

  @override
  Future<List<Expense>> searchExpenses(String query) async {
    AppLogger.debug(FeatureTag.expenses, 'Pesquisando despesas', data: {'query': query});
    
    try {
      final localExpenses = await localDataSource.searchExpenses(query);
      AppLogger.loaded(FeatureTag.expenses, 'resultados de busca', localExpenses.length);
      return localExpenses.map((model) => model.toEntity()).toList();
    } catch (e) {
      AppLogger.error(FeatureTag.expenses, 'Erro na busca', error: e);
      return [];
    }
  }

  // ==================== CATEGORIAS ====================

  @override
  Future<List<ExpenseCategory>> getAllCategories() async {
    final opId = AppLogger.startOp(FeatureTag.categories, 'get_all_categories');
    
    try {
      AppLogger.debug(FeatureTag.categories, 'Buscando categorias locais');
      final localCategories = await localDataSource.getAllCategories();
      
      AppLogger.debug(FeatureTag.categories, 'Categorias locais encontradas', data: {
        'count': localCategories.length,
      });
      
      // Se não há categorias locais, inicializar com padrões
      if (localCategories.isEmpty) {
        AppLogger.warning(FeatureTag.categories, 'Nenhuma categoria encontrada, inicializando padrões');
        
        try {
          await localDataSource.initializeDefaultCategoriesForUser();
          AppLogger.info(FeatureTag.categories, 'Categorias padrão inicializadas localmente');
        } catch (e) {
          AppLogger.error(FeatureTag.categories, 'Erro ao inicializar categorias localmente', error: e);
        }
        
        // Também inicializar no Firestore
        try {
          await firestoreDataSource.initializeDefaultCategories();
          AppLogger.syncComplete('categorias_padrao', synced: 1);
        } catch (e) {
          AppLogger.syncFail('categorias_padrao', 'Erro ao sincronizar com Firestore', error: e);
        }
        
        // Buscar novamente após inicialização
        final newCategories = await localDataSource.getAllCategories();
        AppLogger.loaded(FeatureTag.categories, 'categorias após inicialização', newCategories.length);
        
        AppLogger.completeOp(opId, data: {'count': newCategories.length, 'initialized': true});
        return newCategories.map((model) => model.toEntity()).toList();
      }
      
      AppLogger.completeOp(opId, data: {'count': localCategories.length});
      return localCategories.map((model) => model.toEntity()).toList();
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao buscar categorias', exception: e);
      
      // Em caso de erro, tentar forçar inicialização
      try {
        AppLogger.warning(FeatureTag.categories, 'Tentando forçar inicialização das categorias');
        await localDataSource.initializeDefaultCategoriesForUser();
        final categories = await localDataSource.getAllCategories();
        return categories.map((model) => model.toEntity()).toList();
      } catch (retryError) {
        AppLogger.error(FeatureTag.categories, 'Erro na tentativa de recuperação', error: retryError);
        return [];
      }
    }
  }

  @override
  Future<void> addCategory(ExpenseCategory category) async {
    final opId = AppLogger.startOp(FeatureTag.categories, 'add_category', data: {'name': category.name});
    
    final categoryModel = CategoryModel.fromEntity(category);
    
    try {
      // Salvar localmente primeiro (para funcionar offline)
      AppLogger.debug(FeatureTag.database, 'Salvando categoria localmente');
      await localDataSource.insertCategory(categoryModel);
      
      AppLogger.saved(FeatureTag.categories, 'categoria', id: category.id, data: {'name': category.name});
      
      // Salvar no Firestore em background (não bloquear retorno)
      _saveCategoryToFirestoreInBackground(categoryModel);
      
      AppLogger.completeOp(opId, message: 'Categoria adicionada');
      
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao adicionar categoria', exception: e);
      throw Exception('Erro ao adicionar categoria: $e');
    }
  }

  /// Salva categoria no Firestore em background sem bloquear a UI
  void _saveCategoryToFirestoreInBackground(CategoryModel categoryModel) {
    Future.delayed(Duration.zero, () async {
      AppLogger.syncStart('categoria', source: 'firestore');
      
      try {
        await firestoreDataSource.saveCategory(categoryModel);
        AppLogger.syncComplete('categoria', synced: 1);
      } catch (e) {
        AppLogger.syncFail('categoria', 'Firestore indisponível', error: e);
      }
    });
  }

  @override
  Future<void> updateCategory(ExpenseCategory category) async {
    final opId = AppLogger.startOp(FeatureTag.categories, 'update_category', data: {
      'id': category.id,
      'name': category.name,
    });
    
    final categoryModel = CategoryModel.fromEntity(category);
    
    try {
      // Atualizar localmente primeiro (para funcionar offline)
      AppLogger.debug(FeatureTag.database, 'Atualizando categoria localmente');
      await localDataSource.updateCategory(categoryModel);
      
      AppLogger.saved(FeatureTag.categories, 'categoria', id: category.id, data: {'action': 'update'});
      
      // Salvar no Firestore em background (não bloquear retorno)
      _saveCategoryToFirestoreInBackground(categoryModel);
      
      AppLogger.completeOp(opId, message: 'Categoria atualizada');
      
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao atualizar categoria', exception: e);
      throw Exception('Erro ao atualizar categoria: $e');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    final opId = AppLogger.startOp(FeatureTag.categories, 'delete_category', data: {'id': id});
    
    try {
      // Deletar localmente primeiro
      await localDataSource.deleteCategory(id);
      AppLogger.deleted(FeatureTag.categories, 'categoria', id);
      
      // Tentar deletar no Firestore
      try {
        await firestoreDataSource.deleteCategory(id);
        AppLogger.syncComplete('categoria_delete', synced: 1);
      } catch (e) {
        AppLogger.syncFail('categoria_delete', 'Erro ao deletar no Firestore', error: e);
      }
      
      AppLogger.completeOp(opId);
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao deletar categoria', exception: e);
      throw Exception('Erro ao deletar categoria: $e');
    }
  }

  @override
  Future<ExpenseCategory?> getCategoryById(String id) async {
    try {
      final categories = await getAllCategories();
      return categories.where((cat) => cat.id == id).firstOrNull;
    } catch (e) {
      AppLogger.error(FeatureTag.categories, 'Erro ao buscar categoria', error: e);
      return null;
    }
  }

  @override
  Future<String> suggestCategory(String description) async {
    AppLogger.debug(FeatureTag.categories, 'Sugerindo categoria', data: {'description': description});
    
    try {
      final categories = await getAllCategories();
      
      for (final category in categories) {
        for (final keyword in category.keywords) {
          if (description.toLowerCase().contains(keyword.toLowerCase())) {
            AppLogger.debug(FeatureTag.categories, 'Categoria sugerida via keyword', data: {
              'category': category.name,
              'keyword': keyword,
            });
            return category.id;
          }
        }
      }
      
      AppLogger.debug(FeatureTag.categories, 'Nenhuma categoria encontrada, usando "outros"');
      return 'outros';
    } catch (e) {
      AppLogger.error(FeatureTag.categories, 'Erro ao sugerir categoria', error: e);
      return 'outros';
    }
  }

  // ==================== SINCRONIZAÇÃO ====================

  /// Sincronizar dados em background
  Future<void> _syncInBackground() async {
    try {
      final startTime = DateTime.now();
      AppLogger.syncStart('dados_completos', source: 'firestore');
      
      // Buscar dados do Firestore com timeout para evitar travamentos
      await Future.wait([
        firestoreDataSource.getAllExpenses(),
        firestoreDataSource.getAllCategories(),
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          AppLogger.warning(FeatureTag.sync, 'Timeout na sincronização em background');
          return [<ExpenseModel>[], <CategoryModel>[]];
        },
      );
      
      final duration = DateTime.now().difference(startTime);
      AppLogger.syncComplete('dados_completos', duration: duration);
    } catch (e) {
      AppLogger.syncFail('dados_completos', 'Erro na sincronização em background', error: e);
    }
  }

  /// Sincronização completa (manual)
  Future<void> syncAllData() async {
    final opId = AppLogger.startOp(FeatureTag.sync, 'sync_all_data');
    
    try {
      AppLogger.info(FeatureTag.sync, 'Iniciando sincronização completa');
      
      // Obter dados locais
      final localExpenses = await localDataSource.getAllExpenses();
      final localCategories = await localDataSource.getAllCategories();
      
      AppLogger.debug(FeatureTag.sync, 'Dados locais obtidos', data: {
        'expenses': localExpenses.length,
        'categories': localCategories.length,
      });
      
      // Enviar para Firestore
      await firestoreDataSource.syncLocalDataToFirestore(localExpenses, localCategories);
      
      AppLogger.completeOp(opId, message: 'Sincronização completa finalizada', data: {
        'expenses_synced': localExpenses.length,
        'categories_synced': localCategories.length,
      });
    } catch (e) {
      AppLogger.failOp(opId, 'Erro na sincronização completa', exception: e);
      throw Exception('Erro na sincronização: $e');
    }
  }

  /// Método público para forçar inicialização das categorias padrão
  Future<void> ensureDefaultCategories() async {
    final opId = AppLogger.startOp(FeatureTag.categories, 'ensure_default_categories');
    
    try {
      final localCategories = await localDataSource.getAllCategories();
      
      if (localCategories.length < 5) {
        AppLogger.warning(FeatureTag.categories, 'Poucas categorias encontradas, forçando inicialização', data: {
          'current_count': localCategories.length,
        });
        
        await localDataSource.forceRecreateDefaultCategories();
        
        // Também inicializar no Firestore
        try {
          await firestoreDataSource.initializeDefaultCategories();
          AppLogger.syncComplete('categorias_padrao', synced: 1);
        } catch (e) {
          AppLogger.syncFail('categorias_padrao', 'Erro ao sincronizar', error: e);
        }
        
        AppLogger.completeOp(opId, message: 'Categorias padrão inicializadas');
      } else {
        AppLogger.completeOp(opId, message: 'Categorias já existem', data: {
          'count': localCategories.length,
        });
      }
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao garantir categorias padrão', exception: e);
    }
  }

  /// Forçar recriação completa das categorias padrão
  Future<void> forceRecreateDefaultCategories() async {
    final opId = AppLogger.startOp(FeatureTag.categories, 'force_recreate_categories');
    
    try {
      AppLogger.info(FeatureTag.categories, 'Forçando recriação completa das categorias padrão');
      await localDataSource.forceRecreateDefaultCategories();
      
      // Também recriar no Firestore
      try {
        await firestoreDataSource.initializeDefaultCategories();
        AppLogger.syncComplete('categorias_recriadas', synced: 1);
      } catch (e) {
        AppLogger.syncFail('categorias_recriadas', 'Erro ao recriar no Firestore', error: e);
      }
      
      AppLogger.completeOp(opId, message: 'Categorias padrão recriadas');
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao forçar recriação', exception: e);
    }
  }

  // ==================== RELATÓRIOS ====================

  /// Gerar relatório mensal
  Future<Map<String, dynamic>> generateMonthlyReport() async {
    final opId = AppLogger.startOp(FeatureTag.reports, 'generate_monthly_report');
    
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      
      final expenses = await getExpensesByDateRange(startOfMonth, endOfMonth);
      final total = await getTotalByDateRange(startOfMonth, endOfMonth);
      
      // Agrupar por categoria
      final categoryTotals = <String, double>{};
      for (final expense in expenses) {
        categoryTotals[expense.categoryId] = 
            (categoryTotals[expense.categoryId] ?? 0) + expense.amount;
      }
      
      final report = {
        'type': 'monthly',
        'period': '${now.year}-${now.month.toString().padLeft(2, '0')}',
        'total': total,
        'expensesCount': expenses.length,
        'categoryTotals': categoryTotals,
        'expenses': expenses.map((e) => ExpenseModel.fromEntity(e).toJson()).toList(),
        'generatedAt': DateTime.now().toIso8601String(),
      };
      
      AppLogger.info(FeatureTag.reports, 'Relatório mensal gerado', data: {
        'total': total,
        'expenses_count': expenses.length,
        'categories_count': categoryTotals.length,
      });
      
      // Salvar relatório no Firestore
      try {
        await firestoreDataSource.saveReport(report);
        AppLogger.syncComplete('relatorio_mensal', synced: 1);
      } catch (e) {
        AppLogger.syncFail('relatorio_mensal', 'Erro ao salvar no Firestore', error: e);
      }
      
      AppLogger.completeOp(opId);
      return report;
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao gerar relatório mensal', exception: e);
      return {};
    }
  }

  /// Obter estatísticas do usuário
  Future<Map<String, dynamic>> getUserStatistics() async {
    final opId = AppLogger.startOp(FeatureTag.reports, 'get_user_statistics');
    
    try {
      // Calcular estatísticas localmente
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      
      final monthTotal = await getTotalByDateRange(startOfMonth, endOfMonth);
      final todayTotal = await getTotalByDateRange(
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
      
      final allExpenses = await getAllExpenses();
      
      final stats = {
        'totalMonth': monthTotal,
        'totalToday': todayTotal,
        'expensesCount': allExpenses.length,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      AppLogger.debug(FeatureTag.reports, 'Estatísticas calculadas', data: stats);
      AppLogger.completeOp(opId);
      
      return stats;
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao obter estatísticas', exception: e);
      return {};
    }
  }
}
