import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/logging_service.dart';

/// DataSource para gerenciar despesas no Firestore
class ExpenseFirestoreDataSource extends GetxService {
  static ExpenseFirestoreDataSource get instance => Get.find<ExpenseFirestoreDataSource>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final AuthService _authService;

  // Coleções
  static const String _expensesCollection = 'expenses';
  static const String _categoriesCollection = 'categories';
  static const String _reportsCollection = 'reports';

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
    AppLogger.debug(FeatureTag.database, 'ExpenseFirestoreDataSource inicializado');
  }

  /// Obter referência da coleção de despesas do usuário
  CollectionReference get _userExpensesCollection {
    final userId = _authService.currentUser?.id;
    if (userId == null) {
      AppLogger.error(FeatureTag.database, 'Usuário não autenticado no Firestore');
      throw Exception('Usuário não autenticado');
    }
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(_expensesCollection);
  }

  /// Obter referência da coleção de categorias do usuário
  CollectionReference get _userCategoriesCollection {
    final userId = _authService.currentUser?.id;
    if (userId == null) throw Exception('Usuário não autenticado');
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(_categoriesCollection);
  }

  /// Obter referência da coleção de relatórios do usuário
  CollectionReference get _userReportsCollection {
    final userId = _authService.currentUser?.id;
    if (userId == null) throw Exception('Usuário não autenticado');
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(_reportsCollection);
  }

  // ==================== DESPESAS ====================

  /// Salvar despesa no Firestore com retry
  Future<void> saveExpense(ExpenseModel expense) async {
    const maxRetries = 1; // Reduzido de 2 para 1
    const timeoutDuration = Duration(milliseconds: 1500); // Reduzido de 5s para 1.5s
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        AppLogger.debug(FeatureTag.network, 'Salvando despesa no Firestore', data: {
          'id': expense.id,
          'attempt': attempt,
          'timeout_ms': timeoutDuration.inMilliseconds,
        });
        
        // Obter referência da coleção
        final collection = _userExpensesCollection;
        
        // Converter para Firestore
        final data = expense.toFirestore();
        
        // Salvar no Firestore com timeout reduzido
        await collection
            .doc(expense.id)
            .set(data)
            .timeout(
              timeoutDuration,
              onTimeout: () {
                AppLogger.warning(FeatureTag.network, 'Timeout ao salvar despesa no Firestore', data: {
                  'id': expense.id,
                  'attempt': attempt,
                });
                throw Exception('Timeout ao salvar no Firestore');
              },
            );
        
        AppLogger.debug(FeatureTag.sync, 'Despesa salva no Firestore', data: {'id': expense.id});
        return;
        
      } catch (e) {
        AppLogger.warning(FeatureTag.network, 'Falha ao salvar despesa no Firestore', data: {
          'id': expense.id,
          'attempt': attempt,
          'error': e.toString(),
        });
        
        if (attempt == maxRetries) {
          throw Exception('Firestore indisponível');
        }
      }
    }
  }

  /// Atualizar despesa no Firestore
  Future<void> updateExpense(ExpenseModel expense) async {
    const maxRetries = 2;
    const timeoutDuration = Duration(seconds: 5);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        AppLogger.debug(FeatureTag.network, 'Atualizando despesa no Firestore', data: {
          'id': expense.id,
          'attempt': attempt,
        });
        
        await _userExpensesCollection
            .doc(expense.id)
            .update({
              ...expense.toFirestore(),
              'updatedAt': FieldValue.serverTimestamp(),
            })
            .timeout(
              timeoutDuration,
              onTimeout: () {
                AppLogger.warning(FeatureTag.network, 'Timeout ao atualizar despesa', data: {
                  'id': expense.id,
                  'attempt': attempt,
                });
                throw Exception('Timeout na tentativa $attempt');
              },
            );
        
        AppLogger.debug(FeatureTag.sync, 'Despesa atualizada no Firestore', data: {'id': expense.id});
        return;
        
      } catch (e) {
        AppLogger.warning(FeatureTag.network, 'Erro ao atualizar despesa no Firestore', data: {
          'id': expense.id,
          'attempt': attempt,
          'error': e.toString(),
        });
        
        if (attempt == maxRetries) {
          AppLogger.error(FeatureTag.sync, 'Falha ao atualizar despesa após $maxRetries tentativas', error: e);
          throw Exception('Firestore indisponível após $maxRetries tentativas');
        } else {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
  }

  /// Deletar despesa do Firestore
  Future<void> deleteExpense(String expenseId) async {
    const maxRetries = 2;
    const timeoutDuration = Duration(seconds: 5);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        AppLogger.debug(FeatureTag.network, 'Deletando despesa do Firestore', data: {
          'id': expenseId,
          'attempt': attempt,
        });
        
        await _userExpensesCollection
            .doc(expenseId)
            .delete()
            .timeout(
              timeoutDuration,
              onTimeout: () {
                throw Exception('Timeout na tentativa $attempt');
              },
            );
        
        AppLogger.debug(FeatureTag.sync, 'Despesa deletada do Firestore', data: {'id': expenseId});
        return;
        
      } catch (e) {
        AppLogger.warning(FeatureTag.network, 'Erro ao deletar despesa do Firestore', data: {
          'id': expenseId,
          'attempt': attempt,
        });
        
        if (attempt == maxRetries) {
          AppLogger.error(FeatureTag.sync, 'Falha ao deletar despesa após $maxRetries tentativas', error: e);
          throw Exception('Firestore indisponível após $maxRetries tentativas');
        } else {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
  }

  /// Buscar despesa por ID
  Future<ExpenseModel?> getExpenseById(String expenseId) async {
    try {
      AppLogger.debug(FeatureTag.database, 'Buscando despesa no Firestore', data: {'id': expenseId});
      
      final doc = await _userExpensesCollection.doc(expenseId).get();
      
      if (doc.exists && doc.data() != null) {
        AppLogger.debug(FeatureTag.database, 'Despesa encontrada no Firestore', data: {'id': expenseId});
        return ExpenseModel.fromFirestore(doc.data() as Map<String, dynamic>);
      }
      
      AppLogger.debug(FeatureTag.database, 'Despesa não encontrada no Firestore', data: {'id': expenseId});
      return null;
    } catch (e) {
      AppLogger.error(FeatureTag.database, 'Erro ao buscar despesa no Firestore', error: e, data: {
        'id': expenseId,
      });
      return null;
    }
  }

  /// Buscar todas as despesas
  Future<List<ExpenseModel>> getAllExpenses() async {
    final opId = AppLogger.startOp(FeatureTag.database, 'firestore_get_all_expenses');
    
    try {
      final query = await _userExpensesCollection
          .orderBy('date', descending: true)
          .get();

      final expenses = query.docs
          .map((doc) => ExpenseModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
      
      AppLogger.completeOp(opId, data: {'count': expenses.length});
      return expenses;
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao buscar despesas do Firestore', exception: e);
      return [];
    }
  }

  /// Buscar despesas por período
  Future<List<ExpenseModel>> getExpensesByDateRange(DateTime start, DateTime end) async {
    AppLogger.debug(FeatureTag.database, 'Buscando despesas por período no Firestore', data: {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    });
    
    try {
      final query = await _userExpensesCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('date', descending: true)
          .get();

      final results = query.docs
          .map((doc) => ExpenseModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
      
      AppLogger.debug(FeatureTag.database, 'Despesas por período encontradas', data: {
        'count': results.length,
      });
      return results;
    } catch (e) {
      AppLogger.error(FeatureTag.database, 'Erro ao buscar despesas por período no Firestore', error: e);
      return [];
    }
  }

  /// Buscar despesas por categoria
  Future<List<ExpenseModel>> getExpensesByCategory(String categoryId) async {
    AppLogger.debug(FeatureTag.database, 'Buscando despesas por categoria no Firestore', data: {
      'category_id': categoryId,
    });
    
    try {
      final query = await _userExpensesCollection
          .where('categoryId', isEqualTo: categoryId)
          .orderBy('date', descending: true)
          .get();

      final results = query.docs
          .map((doc) => ExpenseModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
      
      AppLogger.debug(FeatureTag.database, 'Despesas por categoria encontradas', data: {
        'count': results.length,
      });
      return results;
    } catch (e) {
      AppLogger.error(FeatureTag.database, 'Erro ao buscar despesas por categoria no Firestore', error: e);
      return [];
    }
  }

  /// Buscar despesas por texto
  Future<List<ExpenseModel>> searchExpenses(String query) async {
    AppLogger.debug(FeatureTag.database, 'Pesquisando despesas no Firestore', data: {'query': query});
    
    try {
      // Firestore não suporta LIKE, então fazemos busca por array de palavras
      final searchQuery = await _userExpensesCollection
          .where('searchTerms', arrayContainsAny: query.toLowerCase().split(' '))
          .orderBy('date', descending: true)
          .get();

      final results = searchQuery.docs
          .map((doc) => ExpenseModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
      
      AppLogger.debug(FeatureTag.database, 'Resultado da pesquisa', data: {
        'query': query,
        'count': results.length,
      });
      return results;
    } catch (e) {
      AppLogger.error(FeatureTag.database, 'Erro ao pesquisar despesas no Firestore', error: e);
      return [];
    }
  }

  /// Stream de despesas em tempo real
  Stream<List<ExpenseModel>> getExpensesStream() {
    AppLogger.debug(FeatureTag.database, 'Criando stream de despesas do Firestore');
    
    return _userExpensesCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // ==================== CATEGORIAS ====================

  /// Salvar categoria no Firestore
  Future<void> saveCategory(CategoryModel category) async {
    AppLogger.debug(FeatureTag.database, 'Salvando categoria no Firestore', data: {
      'id': category.id,
      'name': category.name,
    });
    
    try {
      await _userCategoriesCollection
          .doc(category.id)
          .set(category.toFirestore());
      
      AppLogger.debug(FeatureTag.sync, 'Categoria salva no Firestore', data: {'name': category.name});
    } catch (e) {
      AppLogger.error(FeatureTag.database, 'Erro ao salvar categoria no Firestore', error: e);
      throw Exception('Erro ao salvar categoria: $e');
    }
  }

  /// Buscar todas as categorias
  Future<List<CategoryModel>> getAllCategories() async {
    final opId = AppLogger.startOp(FeatureTag.database, 'firestore_get_all_categories');
    
    try {
      final query = await _userCategoriesCollection
          .orderBy('name')
          .get();

      final categories = query.docs
          .map((doc) => CategoryModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
      
      AppLogger.completeOp(opId, data: {'count': categories.length});
      return categories;
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao buscar categorias do Firestore', exception: e);
      return [];
    }
  }

  /// Deletar categoria do Firestore
  Future<void> deleteCategory(String categoryId) async {
    AppLogger.debug(FeatureTag.database, 'Deletando categoria do Firestore', data: {'id': categoryId});
    
    try {
      await _userCategoriesCollection.doc(categoryId).delete();
      AppLogger.debug(FeatureTag.sync, 'Categoria deletada do Firestore', data: {'id': categoryId});
    } catch (e) {
      AppLogger.error(FeatureTag.database, 'Erro ao deletar categoria do Firestore', error: e);
      throw Exception('Erro ao deletar categoria: $e');
    }
  }

  /// Inicializar categorias padrão para novo usuário
  Future<void> initializeDefaultCategories() async {
    final opId = AppLogger.startOp(FeatureTag.categories, 'firestore_init_default_categories');
    
    try {
      final existingCategories = await getAllCategories();
      if (existingCategories.isNotEmpty) {
        AppLogger.debug(FeatureTag.categories, 'Usuário já possui categorias, pulando inicialização', data: {
          'count': existingCategories.length,
        });
        AppLogger.completeOp(opId, message: 'Categorias já existem');
        return;
      }

      final defaultCategories = CategoryModel.defaultCategories;
      
      AppLogger.debug(FeatureTag.categories, 'Inicializando categorias padrão no Firestore', data: {
        'count': defaultCategories.length,
      });
      
      for (final category in defaultCategories) {
        await saveCategory(category);
      }
      
      AppLogger.completeOp(opId, message: 'Categorias padrão inicializadas', data: {
        'count': defaultCategories.length,
      });
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao inicializar categorias padrão', exception: e);
    }
  }

  // ==================== RELATÓRIOS ====================

  /// Salvar relatório no Firestore
  Future<void> saveReport(Map<String, dynamic> reportData) async {
    AppLogger.debug(FeatureTag.reports, 'Salvando relatório no Firestore', data: {
      'type': reportData['type'],
      'period': reportData['period'],
    });
    
    try {
      final reportId = '${reportData['type']}_${reportData['period']}_${DateTime.now().millisecondsSinceEpoch}';
      
      await _userReportsCollection
          .doc(reportId)
          .set({
            ...reportData,
            'createdAt': FieldValue.serverTimestamp(),
            'userId': _authService.currentUser?.id,
          });
      
      AppLogger.debug(FeatureTag.sync, 'Relatório salvo no Firestore', data: {
        'id': reportId,
        'type': reportData['type'],
      });
    } catch (e) {
      AppLogger.error(FeatureTag.reports, 'Erro ao salvar relatório no Firestore', error: e);
      throw Exception('Erro ao salvar relatório: $e');
    }
  }

  /// Buscar relatórios do usuário
  Future<List<Map<String, dynamic>>> getUserReports() async {
    AppLogger.debug(FeatureTag.reports, 'Buscando relatórios do Firestore');
    
    try {
      final query = await _userReportsCollection
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final reports = query.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      
      AppLogger.debug(FeatureTag.reports, 'Relatórios encontrados', data: {'count': reports.length});
      return reports;
    } catch (e) {
      AppLogger.error(FeatureTag.reports, 'Erro ao buscar relatórios do Firestore', error: e);
      return [];
    }
  }

  // ==================== ESTATÍSTICAS ====================

  /// Obter estatísticas do usuário
  Future<Map<String, dynamic>> getUserStats() async {
    final opId = AppLogger.startOp(FeatureTag.reports, 'firestore_get_user_stats');
    
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // Despesas do mês atual
      final monthExpenses = await getExpensesByDateRange(startOfMonth, endOfMonth);
      final totalMonth = monthExpenses.fold<double>(0, (sum, expense) => sum + expense.amount);

      // Despesas de hoje
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final todayExpenses = await getExpensesByDateRange(startOfDay, endOfDay);
      final totalToday = todayExpenses.fold<double>(0, (sum, expense) => sum + expense.amount);

      // Categorias mais usadas
      final allExpenses = await getAllExpenses();
      final categoryStats = <String, double>{};
      
      for (final expense in allExpenses) {
        categoryStats[expense.categoryId] = 
            (categoryStats[expense.categoryId] ?? 0) + expense.amount;
      }

      final stats = {
        'totalMonth': totalMonth,
        'totalToday': totalToday,
        'expensesCount': allExpenses.length,
        'monthExpensesCount': monthExpenses.length,
        'todayExpensesCount': todayExpenses.length,
        'categoryStats': categoryStats,
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      AppLogger.completeOp(opId, data: {
        'total_month': totalMonth,
        'total_today': totalToday,
        'expenses_count': allExpenses.length,
      });
      
      return stats;
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao obter estatísticas do Firestore', exception: e);
      return {};
    }
  }

  // ==================== SINCRONIZAÇÃO ====================

  /// Sincronizar dados locais com Firestore
  Future<void> syncLocalDataToFirestore(List<ExpenseModel> localExpenses, List<CategoryModel> localCategories) async {
    final opId = AppLogger.startOp(FeatureTag.sync, 'sync_local_to_firestore', data: {
      'expenses_count': localExpenses.length,
      'categories_count': localCategories.length,
    });
    
    try {
      AppLogger.info(FeatureTag.sync, 'Iniciando sincronização com Firestore', data: {
        'expenses': localExpenses.length,
        'categories': localCategories.length,
      });

      // Sincronizar categorias
      int syncedCategories = 0;
      for (final category in localCategories) {
        try {
          await saveCategory(category);
          syncedCategories++;
        } catch (e) {
          AppLogger.warning(FeatureTag.sync, 'Erro ao sincronizar categoria', data: {
            'id': category.id,
            'error': e.toString(),
          });
        }
      }

      // Sincronizar despesas
      int syncedExpenses = 0;
      for (final expense in localExpenses) {
        try {
          await saveExpense(expense);
          syncedExpenses++;
        } catch (e) {
          AppLogger.warning(FeatureTag.sync, 'Erro ao sincronizar despesa', data: {
            'id': expense.id,
            'error': e.toString(),
          });
        }
      }

      AppLogger.completeOp(opId, message: 'Sincronização concluída', data: {
        'synced_expenses': syncedExpenses,
        'synced_categories': syncedCategories,
        'failed_expenses': localExpenses.length - syncedExpenses,
        'failed_categories': localCategories.length - syncedCategories,
      });
    } catch (e) {
      AppLogger.failOp(opId, 'Erro na sincronização', exception: e);
      throw Exception('Erro na sincronização: $e');
    }
  }
}
