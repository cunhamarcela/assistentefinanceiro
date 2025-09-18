import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_datasource.dart';
import '../datasources/expense_firestore_datasource.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';

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
    final expenseModel = ExpenseModel.fromEntity(expense);
    
    try {
      print('🔄 Iniciando salvamento da despesa: ${expense.description}');
      
      // Salvar localmente primeiro (para funcionar offline)
      print('💾 Salvando localmente...');
      await localDataSource.insertExpense(expenseModel);
      print('✅ Salvo localmente com sucesso');
      
      print('🎉 Despesa adicionada com sucesso: ${expense.description}');
      
      // Salvar no Firestore em background (não bloquear retorno)
      _saveToFirestoreInBackground(expenseModel);
      
    } catch (e) {
      print('❌ Erro ao adicionar despesa: $e');
      throw Exception('Erro ao adicionar despesa: $e');
    }
  }

  /// Salva no Firestore em background sem bloquear a UI
  void _saveToFirestoreInBackground(ExpenseModel expenseModel) {
    Future.delayed(Duration.zero, () async {
      try {
        print('☁️ Salvando no Firestore em background...');
        await firestoreDataSource.saveExpense(expenseModel);
        print('✅ Salvo no Firestore com sucesso');
      } catch (e) {
        print('⚠️ Firestore indisponível, mantido offline: $e');
        // TODO: Implementar fila de sincronização para tentar novamente depois
      }
    });
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final expenseModel = ExpenseModel.fromEntity(expense);
    
    try {
      // Atualizar localmente primeiro
      await localDataSource.updateExpense(expenseModel);
      
      // Tentar atualizar no Firestore
      try {
        await firestoreDataSource.updateExpense(expenseModel);
      } catch (e) {
        print('⚠️ Erro ao atualizar no Firestore, mantido localmente: $e');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar despesa: $e');
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      // Deletar localmente primeiro
      await localDataSource.deleteExpense(id);
      
      // Tentar deletar no Firestore
      try {
        await firestoreDataSource.deleteExpense(id);
      } catch (e) {
        print('⚠️ Erro ao deletar no Firestore, removido localmente: $e');
      }
    } catch (e) {
      throw Exception('Erro ao deletar despesa: $e');
    }
  }

  @override
  Future<Expense?> getExpenseById(String id) async {
    try {
      // Tentar buscar localmente primeiro (mais rápido)
      final localExpense = await localDataSource.getExpenseById(id);
      if (localExpense != null) {
        return localExpense.toEntity();
      }
      
      // Se não encontrar localmente, buscar no Firestore
      final firestoreExpense = await firestoreDataSource.getExpenseById(id);
      if (firestoreExpense != null) {
        // Salvar localmente para próximas consultas
        await localDataSource.insertExpense(firestoreExpense);
        return firestoreExpense.toEntity();
      }
      
      return null;
    } catch (e) {
      print('❌ Erro ao buscar despesa: $e');
      return null;
    }
  }

  @override
  Future<List<Expense>> getAllExpenses() async {
    try {
      // Buscar dados locais primeiro
      final localExpenses = await localDataSource.getAllExpenses();
      
      // Tentar sincronizar com Firestore em background
      _syncInBackground();
      
      return localExpenses.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('❌ Erro ao buscar despesas: $e');
      return [];
    }
  }

  @override
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    try {
      final localExpenses = await localDataSource.getExpensesByDateRange(start, end);
      return localExpenses.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('❌ Erro ao buscar despesas por período: $e');
      return [];
    }
  }

  @override
  Future<List<Expense>> getExpensesByCategory(String categoryId) async {
    try {
      final localExpenses = await localDataSource.getExpensesByCategory(categoryId);
      return localExpenses.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('❌ Erro ao buscar despesas por categoria: $e');
      return [];
    }
  }

  @override
  Future<List<Expense>> getCurrentMonthExpenses() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return getExpensesByDateRange(startOfMonth, endOfMonth);
  }

  @override
  Future<List<Expense>> getTodayExpenses() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return getExpensesByDateRange(startOfDay, endOfDay);
  }

  @override
  Future<double> getTotalByDateRange(DateTime start, DateTime end) async {
    try {
      return await localDataSource.getTotalByDateRange(start, end);
    } catch (e) {
      print('❌ Erro ao calcular total por período: $e');
      return 0.0;
    }
  }

  @override
  Future<double> getTotalByCategory(String categoryId) async {
    try {
      return await localDataSource.getTotalByCategory(categoryId);
    } catch (e) {
      print('❌ Erro ao calcular total por categoria: $e');
      return 0.0;
    }
  }

  @override
  Future<List<Expense>> searchExpenses(String query) async {
    try {
      final localExpenses = await localDataSource.searchExpenses(query);
      return localExpenses.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('❌ Erro ao buscar despesas: $e');
      return [];
    }
  }

  // ==================== CATEGORIAS ====================

  @override
  Future<List<ExpenseCategory>> getAllCategories() async {
    try {
      print('🔍 Buscando categorias locais...');
      final localCategories = await localDataSource.getAllCategories();
      print('📊 Categorias locais encontradas: ${localCategories.length}');
      
      // Se não há categorias locais, inicializar com padrões
      if (localCategories.isEmpty) {
        print('🏷️ Nenhuma categoria encontrada, inicializando padrões...');
        
        try {
          await localDataSource.initializeDefaultCategoriesForUser();
          print('✅ Categorias padrão inicializadas localmente');
        } catch (e) {
          print('⚠️ Erro ao inicializar categorias localmente: $e');
        }
        
        // Também inicializar no Firestore
        try {
          await firestoreDataSource.initializeDefaultCategories();
          print('✅ Categorias padrão sincronizadas com Firestore');
        } catch (e) {
          print('⚠️ Erro ao inicializar categorias no Firestore: $e');
        }
        
        // Buscar novamente após inicialização
        final newCategories = await localDataSource.getAllCategories();
        print('📊 Categorias após inicialização: ${newCategories.length}');
        
        return newCategories.map((model) => model.toEntity()).toList();
      }
      
      print('✅ Retornando ${localCategories.length} categorias existentes');
      return localCategories.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('❌ Erro ao buscar categorias: $e');
      
      // Em caso de erro, tentar forçar inicialização
      try {
        print('🔄 Tentando forçar inicialização das categorias...');
        await localDataSource.initializeDefaultCategoriesForUser();
        final categories = await localDataSource.getAllCategories();
        return categories.map((model) => model.toEntity()).toList();
      } catch (retryError) {
        print('❌ Erro na tentativa de recuperação: $retryError');
        return [];
      }
    }
  }

  @override
  Future<void> addCategory(ExpenseCategory category) async {
    final categoryModel = CategoryModel.fromEntity(category);
    
    try {
      print('🔄 Iniciando salvamento da categoria: ${category.name}');
      
      // Salvar localmente primeiro (para funcionar offline)
      print('💾 Salvando categoria localmente...');
      await localDataSource.insertCategory(categoryModel);
      print('✅ Categoria salva localmente com sucesso');
      
      print('🎉 Categoria adicionada com sucesso: ${category.name}');
      
      // Salvar no Firestore em background (não bloquear retorno)
      _saveCategoryToFirestoreInBackground(categoryModel);
      
    } catch (e) {
      print('❌ Erro ao adicionar categoria: $e');
      throw Exception('Erro ao adicionar categoria: $e');
    }
  }

  /// Salva categoria no Firestore em background sem bloquear a UI
  void _saveCategoryToFirestoreInBackground(CategoryModel categoryModel) {
    Future.delayed(Duration.zero, () async {
      try {
        print('☁️ Salvando categoria no Firestore em background...');
        await firestoreDataSource.saveCategory(categoryModel);
        print('✅ Categoria salva no Firestore com sucesso');
      } catch (e) {
        print('⚠️ Firestore indisponível para categoria, mantido offline: $e');
        // TODO: Implementar fila de sincronização para tentar novamente depois
      }
    });
  }

  @override
  Future<void> updateCategory(ExpenseCategory category) async {
    final categoryModel = CategoryModel.fromEntity(category);
    
    try {
      print('🔄 Iniciando atualização da categoria: ${category.name}');
      
      // Atualizar localmente primeiro (para funcionar offline)
      print('💾 Atualizando categoria localmente...');
      await localDataSource.updateCategory(categoryModel);
      print('✅ Categoria atualizada localmente com sucesso');
      
      print('🎉 Categoria atualizada com sucesso: ${category.name}');
      
      // Salvar no Firestore em background (não bloquear retorno)
      _saveCategoryToFirestoreInBackground(categoryModel);
      
    } catch (e) {
      print('❌ Erro ao atualizar categoria: $e');
      throw Exception('Erro ao atualizar categoria: $e');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      // Deletar localmente primeiro
      await localDataSource.deleteCategory(id);
      
      // Tentar deletar no Firestore
      try {
        await firestoreDataSource.deleteCategory(id);
      } catch (e) {
        print('⚠️ Erro ao deletar categoria no Firestore: $e');
      }
    } catch (e) {
      throw Exception('Erro ao deletar categoria: $e');
    }
  }

  @override
  Future<ExpenseCategory?> getCategoryById(String id) async {
    try {
      final categories = await getAllCategories();
      return categories.where((cat) => cat.id == id).firstOrNull;
    } catch (e) {
      print('❌ Erro ao buscar categoria: $e');
      return null;
    }
  }

  @override
  Future<String> suggestCategory(String description) async {
    try {
      final categories = await getAllCategories();
      
      for (final category in categories) {
        for (final keyword in category.keywords) {
          if (description.toLowerCase().contains(keyword.toLowerCase())) {
            return category.id;
          }
        }
      }
      
      // Se não encontrar, retornar categoria "outros"
      return 'outros';
    } catch (e) {
      print('❌ Erro ao sugerir categoria: $e');
      return 'outros';
    }
  }

  // ==================== SINCRONIZAÇÃO ====================

  /// Sincronizar dados em background
  Future<void> _syncInBackground() async {
    try {
      // Buscar dados do Firestore com timeout para evitar travamentos
      await Future.wait([
        firestoreDataSource.getAllExpenses(),
        firestoreDataSource.getAllCategories(),
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⚠️ Timeout na sincronização em background');
          return [<ExpenseModel>[], <CategoryModel>[]];
        },
      );
      
      print('🔄 Sincronização em background concluída');
    } catch (e) {
      print('⚠️ Erro na sincronização em background: $e');
    }
  }

  /// Sincronização completa (manual)
  Future<void> syncAllData() async {
    try {
      print('🔄 Iniciando sincronização completa...');
      
      // Obter dados locais
      final localExpenses = await localDataSource.getAllExpenses();
      final localCategories = await localDataSource.getAllCategories();
      
      // Enviar para Firestore
      await firestoreDataSource.syncLocalDataToFirestore(localExpenses, localCategories);
      
      print('✅ Sincronização completa finalizada');
    } catch (e) {
      print('❌ Erro na sincronização completa: $e');
      throw Exception('Erro na sincronização: $e');
    }
  }

  /// Método público para forçar inicialização das categorias padrão
  Future<void> ensureDefaultCategories() async {
    try {
      final localCategories = await localDataSource.getAllCategories();
      
      if (localCategories.isEmpty) {
        print('🏷️ Forçando inicialização das categorias padrão...');
        await localDataSource.initializeDefaultCategoriesForUser();
        
        // Também inicializar no Firestore
        try {
          await firestoreDataSource.initializeDefaultCategories();
          print('✅ Categorias padrão sincronizadas com Firestore');
        } catch (e) {
          print('⚠️ Erro ao inicializar categorias no Firestore: $e');
        }
      }
    } catch (e) {
      print('❌ Erro ao garantir categorias padrão: $e');
    }
  }

  /// Forçar recriação completa das categorias padrão
  Future<void> forceRecreateDefaultCategories() async {
    try {
      print('🔄 Forçando recriação completa das categorias padrão...');
      await localDataSource.forceRecreateDefaultCategories();
      
      // Também recriar no Firestore
      try {
        await firestoreDataSource.initializeDefaultCategories();
        print('✅ Categorias padrão recriadas e sincronizadas');
      } catch (e) {
        print('⚠️ Erro ao recriar no Firestore: $e');
      }
    } catch (e) {
      print('❌ Erro ao forçar recriação: $e');
    }
  }

  // ==================== RELATÓRIOS ====================

  /// Gerar relatório mensal
  Future<Map<String, dynamic>> generateMonthlyReport() async {
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
      
      // Salvar relatório no Firestore
      try {
        await firestoreDataSource.saveReport(report);
      } catch (e) {
        print('⚠️ Erro ao salvar relatório no Firestore: $e');
      }
      
      return report;
    } catch (e) {
      print('❌ Erro ao gerar relatório mensal: $e');
      return {};
    }
  }

  /// Obter estatísticas do usuário
  Future<Map<String, dynamic>> getUserStatistics() async {
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
      
      return {
        'totalMonth': monthTotal,
        'totalToday': todayTotal,
        'expensesCount': allExpenses.length,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Erro ao obter estatísticas: $e');
      return {};
    }
  }
}
