import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/financial_goal.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/financial_goals_repository.dart';
import '../../domain/repositories/expense_repository.dart';
import '../models/financial_goal_model.dart';
import '../datasources/expense_local_datasource.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../domain/usecases/get_categories_usecase.dart';

/// Implementação híbrida do repositório de metas financeiras
class FinancialGoalsRepositoryImpl implements FinancialGoalsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final AuthService _authService;
  late final ExpenseLocalDataSource _localDataSource;
  late final GetCategoriesUseCase _getCategoriesUseCase;

  // Coleção no Firestore
  static const String _goalsCollection = 'financial_goals';

  FinancialGoalsRepositoryImpl() {
    _authService = Get.find<AuthService>();
    _localDataSource = Get.find<ExpenseLocalDataSource>();
    _getCategoriesUseCase = Get.find<GetCategoriesUseCase>();
  }

  /// Obter referência da coleção de metas do usuário
  CollectionReference get _userGoalsCollection {
    final userId = _authService.currentUser?.id;
    if (userId == null) throw Exception('Usuário não autenticado');
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(_goalsCollection);
  }

  @override
  Future<void> saveGoal(FinancialGoal goal) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      final model = FinancialGoalModel.fromEntity(goal, userId);
      
      // Salvar localmente primeiro
      await _saveGoalLocally(model);
      
      // Salvar no Firestore em background
      _saveGoalToFirestoreInBackground(model);
      
      print('✅ Meta salva: ${goal.categoryName} - R\$ ${goal.monthlyLimit}');
    } catch (e) {
      print('❌ Erro ao salvar meta: $e');
      throw Exception('Erro ao salvar meta: $e');
    }
  }

  @override
  Future<void> saveGoals(List<FinancialGoal> goals) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      print('💾 Salvando ${goals.length} metas financeiras...');
      
      // Converter para models
      final models = goals.map((goal) => FinancialGoalModel.fromEntity(goal, userId)).toList();
      
      // Salvar localmente em batch
      await _saveGoalsLocallyBatch(models);
      
      // Salvar no Firestore em background
      for (final model in models) {
        _saveGoalToFirestoreInBackground(model);
      }
      
      print('✅ ${goals.length} metas salvas com sucesso');
    } catch (e) {
      print('❌ Erro ao salvar metas: $e');
      throw Exception('Erro ao salvar metas: $e');
    }
  }

  @override
  Future<List<FinancialGoal>> getGoalsByMonth(DateTime month) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return [];

      // Buscar localmente primeiro (offline-first)
      final localGoals = await _getGoalsLocally(month);
      if (localGoals.isNotEmpty) {
        print('📱 ${localGoals.length} metas encontradas localmente');
        // Sincronizar com Firestore em background (não bloqueia)
        _syncGoalsFromFirestoreInBackground(month);
        return localGoals.map((g) => g.toEntity()).toList();
      }

      // Se local vazio, tentar Firestore com timeout curto (3 segundos)
      try {
        final firestoreGoals = await _getGoalsFromFirestore(month)
            .timeout(const Duration(seconds: 3), onTimeout: () {
          print('⚠️ Timeout ao buscar metas do Firestore - retornando vazio');
          return <FinancialGoalModel>[];
        });
        
        // Salvar localmente para próximas consultas
        if (firestoreGoals.isNotEmpty) {
          await _saveGoalsLocallyBatch(firestoreGoals);
          print('☁️ ${firestoreGoals.length} metas sincronizadas do Firestore');
        }

        return firestoreGoals.map((g) => g.toEntity()).toList();
      } catch (e) {
        print('⚠️ Erro ao buscar metas do Firestore: $e - retornando vazio');
        return [];
      }
    } catch (e) {
      print('❌ Erro ao buscar metas: $e');
      return [];
    }
  }
  
  /// Sincroniza metas do Firestore em background (não bloqueia UI)
  void _syncGoalsFromFirestoreInBackground(DateTime month) {
    Future.delayed(Duration.zero, () async {
      try {
        final firestoreGoals = await _getGoalsFromFirestore(month)
            .timeout(const Duration(seconds: 5), onTimeout: () => <FinancialGoalModel>[]);
        
        if (firestoreGoals.isNotEmpty) {
          await _saveGoalsLocallyBatch(firestoreGoals);
          print('☁️ Background: ${firestoreGoals.length} metas sincronizadas');
        }
      } catch (e) {
        print('⚠️ Background sync falhou: $e');
      }
    });
  }

  @override
  Future<FinancialGoal?> getGoalByCategoryAndMonth(String categoryId, DateTime month) async {
    try {
      final goals = await getGoalsByMonth(month);
      return goals.cast<FinancialGoal?>().firstWhere(
        (goal) => goal?.categoryId == categoryId,
        orElse: () => null,
      );
    } catch (e) {
      print('❌ Erro ao buscar meta por categoria: $e');
      return null;
    }
  }

  @override
  Future<List<FinancialGoal>> getAllGoals() async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return [];

      final db = await _localDataSource.database;
      
      // Verificar se tabela existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='financial_goals'"
      );
      if (tables.isEmpty) return [];

      final result = await db.query(
        'financial_goals',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'month DESC, categoryName ASC',
      );

      return result.map((data) => FinancialGoalModel.fromSQLite(data).toEntity()).toList();
    } catch (e) {
      print('❌ Erro ao buscar todas as metas: $e');
      return [];
    }
  }

  @override
  Future<void> updateGoalSpentAmount(String categoryId, DateTime month, double newAmount) async {
    try {
      final goal = await getGoalByCategoryAndMonth(categoryId, month);
      if (goal != null) {
        final updatedGoal = goal.copyWith(
          currentSpent: newAmount,
          updatedAt: DateTime.now(),
        );
        await saveGoal(updatedGoal);
        print('✅ Valor gasto atualizado: ${goal.categoryName} - R\$ $newAmount');
      }
    } catch (e) {
      print('❌ Erro ao atualizar valor gasto: $e');
    }
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      // Deletar localmente
      final db = await _localDataSource.database;
      await db.delete(
        'financial_goals',
        where: 'id = ? AND userId = ?',
        whereArgs: [goalId, userId],
      );

      // Deletar no Firestore
      await _userGoalsCollection.doc(goalId).delete();
      
      print('✅ Meta deletada: $goalId');
    } catch (e) {
      print('❌ Erro ao deletar meta: $e');
    }
  }

  @override
  Future<void> deleteGoalsByMonth(DateTime month) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      final startOfMonth = DateTime(month.year, month.month).millisecondsSinceEpoch;
      final endOfMonth = DateTime(month.year, month.month + 1).millisecondsSinceEpoch;

      // Deletar localmente
      final db = await _localDataSource.database;
      await db.delete(
        'financial_goals',
        where: 'userId = ? AND month >= ? AND month < ?',
        whereArgs: [userId, startOfMonth, endOfMonth],
      );

      // Deletar no Firestore
      final query = await _userGoalsCollection
          .where('userId', isEqualTo: userId)
          .where('month', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(month.year, month.month)))
          .where('month', isLessThan: Timestamp.fromDate(DateTime(month.year, month.month + 1)))
          .get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }
      
      print('✅ Metas do mês ${month.month}/${month.year} deletadas');
    } catch (e) {
      print('❌ Erro ao deletar metas do mês: $e');
    }
  }

  @override
  Future<List<FinancialGoal>> createGoalsFromProfile(Map<String, double> categoryBudgets, DateTime month) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      // Buscar categorias para obter nomes
      final categories = await _getCategoriesUseCase.execute();

      final goals = <FinancialGoal>[];
      final now = DateTime.now();
      final targetMonth = DateTime(month.year, month.month);

      for (final entry in categoryBudgets.entries) {
        final categoryId = entry.key;
        final monthlyLimit = entry.value;
        // Usar lookup flexível para encontrar a categoria
        final category = _findCategoryById(categoryId, categories);
        final categoryName = category?.name ?? _getCategoryNameFromId(categoryId);

        // Verificar se já existe uma meta para esta categoria neste mês
        final existingGoal = await getGoalByCategoryAndMonth(categoryId, targetMonth);
        
        if (existingGoal == null) {
          final goal = FinancialGoal(
            id: 'goal_${userId}_${categoryId}_${targetMonth.millisecondsSinceEpoch}',
            categoryId: categoryId,
            categoryName: categoryName,
            monthlyLimit: monthlyLimit,
            currentSpent: 0.0,
            month: targetMonth,
            isActive: true,
            createdAt: now,
            updatedAt: now,
          );
          
          goals.add(goal);
        } else {
          // Atualizar meta existente com novo limite
          final updatedGoal = existingGoal.copyWith(
            monthlyLimit: monthlyLimit,
            updatedAt: now,
          );
          goals.add(updatedGoal);
        }
      }

      if (goals.isNotEmpty) {
        await saveGoals(goals);
        print('✅ ${goals.length} metas criadas/atualizadas baseadas no perfil');
        
        // Recalcular gastos baseado nas despesas existentes
        await recalculateGoalsSpent(targetMonth);
      }

      return goals;
    } catch (e) {
      print('❌ Erro ao criar metas do perfil: $e');
      throw Exception('Erro ao criar metas do perfil: $e');
    }
  }

  @override
  Future<List<FinancialGoal>> recalculateGoalsSpent(DateTime month) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      print('🔄 Recalculando gastos das metas para ${month.month}/${month.year}...');

      // Buscar metas do mês
      final goals = await getGoalsByMonth(month);
      if (goals.isEmpty) {
        print('ℹ️ Nenhuma meta encontrada para recalcular');
        return [];
      }
      
      print('📋 ${goals.length} metas encontradas:');
      for (final goal in goals) {
        print('   - ${goal.categoryName} (ID: ${goal.categoryId}): limite R\$ ${goal.monthlyLimit.toStringAsFixed(2)}, gasto R\$ ${goal.currentSpent.toStringAsFixed(2)}');
      }

      // Buscar despesas do mês
      final expenses = await _getExpensesForMonth(month);
      print('📊 ${expenses.length} despesas encontradas no mês');
      
      // Debug: mostrar algumas despesas
      if (expenses.isNotEmpty) {
        print('🔍 Primeiras despesas:');
        for (final exp in expenses.take(5)) {
          print('   - ${exp.description}: R\$ ${exp.amount.toStringAsFixed(2)} (categoria: ${exp.categoryId})');
        }
      }

      // Agrupar despesas por categoria
      final expensesByCategory = <String, double>{};
      for (final expense in expenses) {
        expensesByCategory[expense.categoryId] = 
            (expensesByCategory[expense.categoryId] ?? 0) + expense.amount;
      }
      
      print('📊 Gastos agrupados por categoria:');
      for (final entry in expensesByCategory.entries) {
        print('   - ${entry.key}: R\$ ${entry.value.toStringAsFixed(2)}');
      }

      // Atualizar cada meta com o valor real gasto
      final updatedGoals = <FinancialGoal>[];
      final now = DateTime.now();

      for (final goal in goals) {
        final spent = expensesByCategory[goal.categoryId] ?? 0.0;
        
        print('🎯 Verificando meta ${goal.categoryName} (${goal.categoryId}): gasto atual = R\$ ${spent.toStringAsFixed(2)}, registrado = R\$ ${goal.currentSpent.toStringAsFixed(2)}');
        
        if (spent != goal.currentSpent) {
          final updatedGoal = goal.copyWith(
            currentSpent: spent,
            updatedAt: now,
          );
          await saveGoal(updatedGoal);
          updatedGoals.add(updatedGoal);
          print('✅ Meta ${goal.categoryName}: ATUALIZADA para R\$ ${spent.toStringAsFixed(2)} (era R\$ ${goal.currentSpent.toStringAsFixed(2)})');
        } else {
          updatedGoals.add(goal);
          print('ℹ️ Meta ${goal.categoryName}: sem alteração');
        }
      }

      print('✅ ${updatedGoals.length} metas recalculadas');
      return updatedGoals;
    } catch (e) {
      print('❌ Erro ao recalcular gastos das metas: $e');
      return [];
    }
  }

  /// Busca despesas de um mês específico
  Future<List<Expense>> _getExpensesForMonth(DateTime month) async {
    try {
      // Tentar usar o ExpenseRepository se disponível
      if (Get.isRegistered<ExpenseRepository>()) {
        final expenseRepository = Get.find<ExpenseRepository>();
        final startOfMonth = DateTime(month.year, month.month, 1);
        final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
        return await expenseRepository.getExpensesByDateRange(startOfMonth, endOfMonth);
      }
      
      // Fallback: buscar direto do banco local
      final db = await _localDataSource.database;
      
      final startOfMonth = DateTime(month.year, month.month, 1).millisecondsSinceEpoch;
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59).millisecondsSinceEpoch;
      
      final result = await db.query(
        'expenses',
        where: 'date >= ? AND date <= ?',
        whereArgs: [startOfMonth, endOfMonth],
      );
      
      // Converter para Expense (simplificado - apenas categoryId e amount)
      return result.map((data) => Expense(
        id: data['id'] as String,
        amount: data['amount'] as double,
        description: data['description'] as String,
        categoryId: data['categoryId'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )).toList();
    } catch (e) {
      print('❌ Erro ao buscar despesas do mês: $e');
      return [];
    }
  }

  // ==================== MÉTODOS PRIVADOS ====================

  /// Salvar meta localmente
  Future<void> _saveGoalLocally(FinancialGoalModel goal) async {
    try {
      final db = await _localDataSource.database;
      
      // Criar tabela se não existir
      await _createGoalsTableIfNotExists(db);
      
      await db.insert(
        'financial_goals',
        goal.toSQLite(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
    } catch (e) {
      print('❌ Erro ao salvar meta localmente: $e');
      throw e;
    }
  }

  /// Salvar múltiplas metas localmente em batch
  Future<void> _saveGoalsLocallyBatch(List<FinancialGoalModel> goals) async {
    try {
      final db = await _localDataSource.database;
      
      // Criar tabela se não existir
      await _createGoalsTableIfNotExists(db);
      
      final batch = db.batch();
      for (final goal in goals) {
        batch.insert(
          'financial_goals',
          goal.toSQLite(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit(noResult: true);
      
    } catch (e) {
      print('❌ Erro ao salvar metas localmente em batch: $e');
      throw e;
    }
  }

  /// Buscar metas localmente
  Future<List<FinancialGoalModel>> _getGoalsLocally(DateTime month) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return [];

      final db = await _localDataSource.database;
      
      // Verificar se tabela existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='financial_goals'"
      );
      if (tables.isEmpty) return [];

      final startOfMonth = DateTime(month.year, month.month).millisecondsSinceEpoch;
      final endOfMonth = DateTime(month.year, month.month + 1).millisecondsSinceEpoch;

      final result = await db.query(
        'financial_goals',
        where: 'userId = ? AND month >= ? AND month < ?',
        whereArgs: [userId, startOfMonth, endOfMonth],
        orderBy: 'categoryName ASC',
      );

      return result.map((data) => FinancialGoalModel.fromSQLite(data)).toList();
    } catch (e) {
      print('❌ Erro ao buscar metas localmente: $e');
      return [];
    }
  }

  /// Buscar metas no Firestore
  Future<List<FinancialGoalModel>> _getGoalsFromFirestore(DateTime month) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return [];

      final startOfMonth = Timestamp.fromDate(DateTime(month.year, month.month));
      final endOfMonth = Timestamp.fromDate(DateTime(month.year, month.month + 1));

      final query = await _userGoalsCollection
          .where('userId', isEqualTo: userId)
          .where('month', isGreaterThanOrEqualTo: startOfMonth)
          .where('month', isLessThan: endOfMonth)
          .get();

      return query.docs
          .map((doc) => FinancialGoalModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Erro ao buscar metas no Firestore: $e');
      return [];
    }
  }

  /// Salvar meta no Firestore em background
  void _saveGoalToFirestoreInBackground(FinancialGoalModel goal) {
    Future.delayed(Duration.zero, () async {
      try {
        await _userGoalsCollection
            .doc(goal.id)
            .set(goal.toFirestore());
      } catch (e) {
        print('⚠️ Erro ao salvar meta no Firestore: $e');
      }
    });
  }

  /// Criar tabela de metas se não existir
  Future<void> _createGoalsTableIfNotExists(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS financial_goals (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        categoryId TEXT NOT NULL,
        categoryName TEXT NOT NULL,
        monthlyLimit REAL NOT NULL,
        currentSpent REAL NOT NULL,
        month INTEGER NOT NULL,
        isActive INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        UNIQUE(userId, categoryId, month)
      )
    ''');
    
    // Criar índices para melhor performance
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_financial_goals_user_month 
      ON financial_goals (userId, month)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_financial_goals_category_month 
      ON financial_goals (categoryId, month)
    ''');
  }
  
  /// Busca categoria por ID com fallback para IDs sem sufixo do usuário
  ExpenseCategory? _findCategoryById(String categoryId, List<ExpenseCategory> categories) {
    if (categoryId.isEmpty || categories.isEmpty) return null;
    
    // 1. Tentar match exato
    final exactMatch = categories.firstWhereOrNull((cat) => cat.id == categoryId);
    if (exactMatch != null) return exactMatch;
    
    // 2. Tentar match onde o ID da categoria começa com o categoryId buscado
    final startsWithMatch = categories.firstWhereOrNull(
      (cat) => cat.id.startsWith('${categoryId}_')
    );
    if (startsWithMatch != null) return startsWithMatch;
    
    // 3. Tentar match onde o categoryId começa com o ID base da categoria
    final reverseMatch = categories.firstWhereOrNull(
      (cat) => categoryId.startsWith('${cat.id}_')
    );
    if (reverseMatch != null) return reverseMatch;
    
    // 4. Extrair ID base e tentar match
    final baseId = _extractBaseCategoryId(categoryId);
    if (baseId != categoryId) {
      return categories.firstWhereOrNull(
        (cat) => cat.id == baseId || 
                 cat.id.startsWith('${baseId}_') ||
                 _extractBaseCategoryId(cat.id) == baseId
      );
    }
    
    return null;
  }
  
  /// Extrai o ID base de uma categoria removendo o sufixo do usuário
  String _extractBaseCategoryId(String categoryId) {
    final defaultIds = [
      'alimentacao', 'transporte', 'saude', 'contas', 'lazer',
      'casa', 'educacao', 'roupas', 'tecnologia', 'pets', 'outros', 'investimentos'
    ];
    
    for (final baseId in defaultIds) {
      if (categoryId == baseId || categoryId.startsWith('${baseId}_')) {
        return baseId;
      }
    }
    return categoryId;
  }
  
  /// Obtém o nome da categoria a partir do ID base
  String _getCategoryNameFromId(String categoryId) {
    final baseId = _extractBaseCategoryId(categoryId);
    
    final categoryNames = {
      'alimentacao': 'Alimentação',
      'transporte': 'Transporte',
      'saude': 'Saúde',
      'contas': 'Contas',
      'lazer': 'Lazer',
      'casa': 'Casa',
      'educacao': 'Educação',
      'roupas': 'Roupas e Beleza',
      'tecnologia': 'Tecnologia',
      'pets': 'Pets',
      'outros': 'Outros',
      'investimentos': 'Investimentos',
    };
    
    return categoryNames[baseId] ?? 'Categoria';
  }
}

