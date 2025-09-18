import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:get/get.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';
import '../../../auth/data/services/auth_service.dart';

class ExpenseLocalDataSource {
  static Database? _database;
  static const String _databaseName = 'expenses.db';
  static const int _databaseVersion = 2; // Incrementado para migration

  // Tabelas
  static const String _expensesTable = 'expenses';
  static const String _categoriesTable = 'categories';
  
  // Lock para evitar inicialização concorrente de categorias
  static bool _isInitializingCategories = false;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Criar tabela de categorias com userId
    await db.execute('''
      CREATE TABLE $_categoriesTable (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        keywords TEXT NOT NULL,
        isDefault INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Criar tabela de despesas com userId
    await db.execute('''
      CREATE TABLE $_expensesTable (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        categoryId TEXT NOT NULL,
        date INTEGER NOT NULL,
        notes TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES $_categoriesTable (id)
      )
    ''');

    // Criar índices para melhor performance
    await db.execute('CREATE INDEX idx_expenses_userId ON $_expensesTable (userId)');
    await db.execute('CREATE INDEX idx_categories_userId ON $_categoriesTable (userId)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migração da versão 1 para 2: adicionar userId
      await db.execute('ALTER TABLE $_categoriesTable ADD COLUMN userId TEXT DEFAULT ""');
      await db.execute('ALTER TABLE $_expensesTable ADD COLUMN userId TEXT DEFAULT ""');
      
      // Criar índices
      await db.execute('CREATE INDEX idx_expenses_userId ON $_expensesTable (userId)');
      await db.execute('CREATE INDEX idx_categories_userId ON $_categoriesTable (userId)');
      
      print('✅ Migração do banco de dados concluída');
    }
  }

  /// Obter userId atual
  String get _currentUserId {
    try {
      final authService = Get.find<AuthService>();
      final userId = authService.currentUser?.id;
      if (userId == null || userId.isEmpty) {
        print('⚠️ Usuário não autenticado no datasource local');
        throw Exception('Usuário não autenticado');
      }
      return userId;
    } catch (e) {
      print('❌ Erro ao obter userId: $e');
      rethrow;
    }
  }

  /// Inicializar categorias padrão para o usuário atual
  Future<void> initializeDefaultCategoriesForUser() async {
    // Evitar execuções concorrentes
    if (_isInitializingCategories) {
      print('⏳ Inicialização de categorias já em andamento, aguardando...');
      return;
    }
    
    try {
      _isInitializingCategories = true;
      final db = await database;
      final userId = _currentUserId;
      
      print('🔍 Verificando categorias existentes para usuário: $userId');
      
      // Verificar se já existem categorias para este usuário
      final existingCategories = await db.query(
        _categoriesTable,
        where: 'userId = ?',
        whereArgs: [userId],
      );
      
      print('📊 Categorias existentes encontradas: ${existingCategories.length}');
      
      if (existingCategories.isNotEmpty) {
        print('✅ Usuário já possui ${existingCategories.length} categorias');
        return; // Já tem categorias
      }
      
      print('🏷️ Inicializando categorias padrão...');
      final defaultCategories = CategoryModel.defaultCategories;
      
      for (final category in defaultCategories) {
        try {
          final categoryData = category.toSQLite();
          categoryData['userId'] = userId; // Adicionar userId
          
          // Usar ID único por usuário para evitar conflitos
          final uniqueId = '${category.id}_$userId';
          
          // Usar INSERT OR IGNORE para evitar erro de constraint
          await db.rawInsert('''
            INSERT OR IGNORE INTO $_categoriesTable 
            (id, userId, name, icon, color, keywords, isDefault) 
            VALUES (?, ?, ?, ?, ?, ?, ?)
          ''', [
            uniqueId,
            userId,
            category.name,
            category.icon,
            category.color.value,
            category.keywords.join(','),
            category.isDefault ? 1 : 0,
          ]);
          
          print('✅ Categoria "${category.name}" criada');
        } catch (e) {
          print('⚠️ Erro ao criar categoria "${category.name}": $e');
        }
      }
      
      print('✅ Categorias padrão inicializadas para usuário: $userId');
    } catch (e) {
      print('❌ Erro ao inicializar categorias padrão: $e');
    } finally {
      _isInitializingCategories = false;
    }
  }

  /// Limpar todos os dados do usuário atual
  Future<void> clearUserData() async {
    final db = await database;
    final userId = _currentUserId;
    
    await db.delete(_expensesTable, where: 'userId = ?', whereArgs: [userId]);
    await db.delete(_categoriesTable, where: 'userId = ?', whereArgs: [userId]);
    
    print('✅ Dados do usuário limpos: $userId');
  }

  /// Limpar dados corrompidos e recriar categorias (método de emergência)
  Future<void> resetCategoriesForUser() async {
    try {
      final db = await database;
      final userId = _currentUserId;
      
      print('🔄 Resetando categorias para usuário: $userId');
      
      // Limpar categorias existentes do usuário
      await db.delete(_categoriesTable, where: 'userId = ?', whereArgs: [userId]);
      
      // Resetar flag de inicialização
      _isInitializingCategories = false;
      
      // Recriar categorias
      await initializeDefaultCategoriesForUser();
      
      print('✅ Categorias resetadas com sucesso');
    } catch (e) {
      print('❌ Erro ao resetar categorias: $e');
      rethrow;
    }
  }

  /// Forçar recriação das categorias padrão
  Future<void> forceRecreateDefaultCategories() async {
    try {
      final db = await database;
      final userId = _currentUserId;
      
      print('🔄 Forçando recriação das categorias padrão...');
      
      // Remover categorias padrão existentes do usuário
      await db.delete(
        _categoriesTable, 
        where: 'userId = ? AND isDefault = 1', 
        whereArgs: [userId]
      );
      
      print('🗑️ Categorias padrão antigas removidas');
      
      // Recriar categorias padrão
      final defaultCategories = CategoryModel.defaultCategories;
      
      for (final category in defaultCategories) {
        try {
          await db.rawInsert('''
            INSERT INTO $_categoriesTable 
            (id, userId, name, icon, color, keywords, isDefault) 
            VALUES (?, ?, ?, ?, ?, ?, ?)
          ''', [
            '${category.id}_$userId', // ID único por usuário
            userId,
            category.name,
            category.icon,
            category.color.value,
            category.keywords.join(','),
            category.isDefault ? 1 : 0,
          ]);
          
          print('✅ Categoria "${category.name}" recriada');
        } catch (e) {
          print('⚠️ Erro ao recriar categoria "${category.name}": $e');
        }
      }
      
      print('✅ Categorias padrão recriadas para usuário: $userId');
    } catch (e) {
      print('❌ Erro ao forçar recriação das categorias: $e');
    }
  }

  // CRUD Despesas
  Future<void> insertExpense(ExpenseModel expense) async {
    try {
      print('🗄️ [SQLite] Iniciando inserção de despesa: ${expense.description}');
      
      final db = await database;
      print('🗄️ [SQLite] Database obtido com sucesso');
      
      final userId = _currentUserId;
      print('🗄️ [SQLite] UserId obtido: $userId');
      
      final expenseData = expense.toSQLite();
      expenseData['userId'] = userId; // Adicionar userId
      
      print('🗄️ [SQLite] Dados preparados: ${expenseData.keys.join(', ')}');
      print('🗄️ [SQLite] ID: ${expenseData['id']}');
      print('🗄️ [SQLite] Amount: ${expenseData['amount']}');
      print('🗄️ [SQLite] Description: ${expenseData['description']}');
      print('🗄️ [SQLite] CategoryId: ${expenseData['categoryId']}');
      print('🗄️ [SQLite] UserId: ${expenseData['userId']}');
      
      final result = await db.insert(_expensesTable, expenseData);
      print('🗄️ [SQLite] ✅ Despesa inserida com sucesso! Row ID: $result');
      
      // Verificar se foi realmente inserida
      final verification = await db.query(
        _expensesTable,
        where: 'id = ? AND userId = ?',
        whereArgs: [expense.id, userId],
      );
      
      if (verification.isNotEmpty) {
        print('🗄️ [SQLite] ✅ Verificação: Despesa encontrada no banco');
        print('🗄️ [SQLite] Dados salvos: ${verification.first}');
      } else {
        print('🗄️ [SQLite] ❌ ERRO: Despesa não encontrada após inserção!');
      }
      
    } catch (e) {
      print('🗄️ [SQLite] ❌ ERRO ao inserir despesa: $e');
      print('🗄️ [SQLite] Tipo do erro: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    final db = await database;
    final userId = _currentUserId;
    
    final expenseData = expense.toSQLite();
    expenseData['userId'] = userId; // Adicionar userId
    
    await db.update(
      _expensesTable,
      expenseData,
      where: 'id = ? AND userId = ?',
      whereArgs: [expense.id, userId],
    );
  }

  Future<void> deleteExpense(String id) async {
    final db = await database;
    final userId = _currentUserId;
    
    await db.delete(
      _expensesTable,
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  Future<ExpenseModel?> getExpenseById(String id) async {
    final db = await database;
    final userId = _currentUserId;
    
    final maps = await db.query(
      _expensesTable,
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );

    if (maps.isNotEmpty) {
      return ExpenseModel.fromSQLite(maps.first);
    }
    return null;
  }

  Future<List<ExpenseModel>> getAllExpenses() async {
    try {
      print('🗄️ [SQLite] Buscando todas as despesas...');
      
      final db = await database;
      final userId = _currentUserId;
      print('🗄️ [SQLite] UserId para busca: $userId');
      
      final maps = await db.query(
        _expensesTable,
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
      );
      
      print('🗄️ [SQLite] Despesas encontradas: ${maps.length}');
      
      if (maps.isNotEmpty) {
        print('🗄️ [SQLite] Primeira despesa: ${maps.first}');
        for (int i = 0; i < maps.length && i < 3; i++) {
          final map = maps[i];
          print('🗄️ [SQLite] Despesa $i: ID=${map['id']}, Desc=${map['description']}, Amount=${map['amount']}');
        }
      } else {
        print('🗄️ [SQLite] ⚠️ Nenhuma despesa encontrada para o usuário');
        
        // Verificar se há despesas sem userId (dados antigos)
        final allMaps = await db.query(_expensesTable);
        print('🗄️ [SQLite] Total de despesas na tabela (todos usuários): ${allMaps.length}');
        
        if (allMaps.isNotEmpty) {
          print('🗄️ [SQLite] Primeira despesa geral: ${allMaps.first}');
        }
      }
      
      final expenses = maps.map((map) => ExpenseModel.fromSQLite(map)).toList();
      print('🗄️ [SQLite] ✅ Retornando ${expenses.length} despesas');
      
      return expenses;
    } catch (e) {
      print('🗄️ [SQLite] ❌ ERRO ao buscar despesas: $e');
      return [];
    }
  }

  Future<List<ExpenseModel>> getExpensesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final userId = _currentUserId;
    
    final maps = await db.query(
      _expensesTable,
      where: 'date >= ? AND date <= ? AND userId = ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch, userId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => ExpenseModel.fromSQLite(map)).toList();
  }

  Future<List<ExpenseModel>> getExpensesByCategory(String categoryId) async {
    final db = await database;
    final userId = _currentUserId;
    
    final maps = await db.query(
      _expensesTable,
      where: 'categoryId = ? AND userId = ?',
      whereArgs: [categoryId, userId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => ExpenseModel.fromSQLite(map)).toList();
  }

  Future<List<ExpenseModel>> searchExpenses(String query) async {
    final db = await database;
    final userId = _currentUserId;
    
    final maps = await db.query(
      _expensesTable,
      where: '(description LIKE ? OR notes LIKE ?) AND userId = ?',
      whereArgs: ['%$query%', '%$query%', userId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => ExpenseModel.fromSQLite(map)).toList();
  }

  Future<double> getTotalByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final userId = _currentUserId;
    
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM $_expensesTable WHERE date >= ? AND date <= ? AND userId = ?',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch, userId],
    );
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<double> getTotalByCategory(String categoryId) async {
    final db = await database;
    final userId = _currentUserId;
    
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM $_expensesTable WHERE categoryId = ? AND userId = ?',
      [categoryId, userId],
    );
    return (result.first['total'] as double?) ?? 0.0;
  }

  // CRUD Categorias
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      final db = await database;
      final userId = _currentUserId;
      
      final maps = await db.query(
        _categoriesTable,
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'name ASC',
      );
      
      final categories = maps.map((map) => CategoryModel.fromSQLite(map)).toList();
      
      // Se não encontrou categorias, tentar inicializar
      if (categories.isEmpty) {
        print('⚠️ Nenhuma categoria encontrada, tentando novamente...');
        await initializeDefaultCategoriesForUser();
        
        // Tentar buscar novamente
        final newMaps = await db.query(
          _categoriesTable,
          where: 'userId = ?',
          whereArgs: [userId],
          orderBy: 'name ASC',
        );
        
        return newMaps.map((map) => CategoryModel.fromSQLite(map)).toList();
      }
      
      return categories;
    } catch (e) {
      print('❌ Erro ao buscar categorias: $e');
      return [];
    }
  }

  Future<void> insertCategory(CategoryModel category) async {
    try {
      final db = await database;
      final userId = _currentUserId;
      
      final categoryData = category.toSQLite();
      categoryData['userId'] = userId; // Adicionar userId
      
      // Usar ID único por usuário se for categoria padrão
      final categoryId = category.isDefault ? '${category.id}_$userId' : category.id;
      
      // Usar INSERT OR IGNORE para evitar erro de constraint
      await db.rawInsert('''
        INSERT OR IGNORE INTO $_categoriesTable 
        (id, userId, name, icon, color, keywords, isDefault) 
        VALUES (?, ?, ?, ?, ?, ?, ?)
      ''', [
        categoryId,
        userId,
        category.name,
        category.icon,
        category.color.value,
        category.keywords.join(','),
        category.isDefault ? 1 : 0,
      ]);
      
      print('✅ Categoria "${category.name}" inserida/atualizada');
    } catch (e) {
      print('❌ Erro ao inserir categoria "${category.name}": $e');
      throw e;
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    final db = await database;
    final userId = _currentUserId;
    
    final categoryData = category.toSQLite();
    categoryData['userId'] = userId; // Adicionar userId
    
    await db.update(
      _categoriesTable,
      categoryData,
      where: 'id = ? AND userId = ?',
      whereArgs: [category.id, userId],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    final userId = _currentUserId;
    
    // Primeiro, move todas as despesas desta categoria para "outros"
    await db.update(
      _expensesTable,
      {'categoryId': 'outros'},
      where: 'categoryId = ? AND userId = ?',
      whereArgs: [id, userId],
    );
    
    // Depois deleta a categoria (apenas se não for padrão)
    await db.delete(
      _categoriesTable,
      where: 'id = ? AND userId = ? AND isDefault = 0',
      whereArgs: [id, userId],
    );
  }

  Future<CategoryModel?> getCategoryById(String id) async {
    final db = await database;
    final userId = _currentUserId;
    
    final maps = await db.query(
      _categoriesTable,
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );

    if (maps.isNotEmpty) {
      return CategoryModel.fromSQLite(maps.first);
    }
    return null;
  }

  // Método para resetar dados (útil para desenvolvimento)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_expensesTable);
    await db.delete(_categoriesTable);
    
    // Reinicializar categorias padrão para o usuário atual
    try {
      await initializeDefaultCategoriesForUser();
    } catch (e) {
      print('⚠️ Erro ao reinicializar categorias: $e');
    }
  }

  // Fechar banco de dados
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
