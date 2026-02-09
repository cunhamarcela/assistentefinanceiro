import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/financial_profile.dart';
import '../../domain/entities/financial_goal.dart';
import '../../domain/entities/category.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../models/financial_profile_model.dart';
import '../models/financial_goal_model.dart';
import '../../../auth/data/services/auth_service.dart';
import '../datasources/expense_local_datasource.dart';

/// Serviço para gerenciar perfil financeiro e metas
class FinancialProfileService extends GetxService {
  static FinancialProfileService get instance => Get.find<FinancialProfileService>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final AuthService _authService;
  late final ExpenseLocalDataSource _localDataSource;

  // Coleções
  static const String _profilesCollection = 'financial_profiles';
  static const String _goalsCollection = 'financial_goals';

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
    _localDataSource = Get.find<ExpenseLocalDataSource>();
  }

  /// Obter referência da coleção de perfis do usuário
  CollectionReference get _userProfilesCollection {
    final userId = _authService.currentUser?.id;
    if (userId == null) throw Exception('Usuário não autenticado');
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(_profilesCollection);
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

  // ==================== PERFIL FINANCEIRO ====================

  /// Salvar perfil financeiro
  Future<void> saveFinancialProfile(FinancialProfile profile) async {
    try {
      final model = FinancialProfileModel.fromEntity(profile);
      
      // Salvar localmente primeiro
      await _saveProfileLocally(model);
      
      // Salvar no Firestore em background
      _saveProfileToFirestoreInBackground(model);
      
      // Atualizar metas baseadas no novo perfil
      await _updateGoalsFromProfile(profile);
      
      print('✅ Perfil financeiro salvo com sucesso');
    } catch (e) {
      print('❌ Erro ao salvar perfil financeiro: $e');
      throw Exception('Erro ao salvar perfil financeiro: $e');
    }
  }

  /// Buscar perfil financeiro
  Future<FinancialProfile?> getFinancialProfile() async {
    try {
      // Tentar buscar localmente primeiro
      final localProfile = await _getProfileLocally();
      if (localProfile != null) {
        return localProfile.toEntity();
      }

      // Se não encontrar localmente, buscar no Firestore
      final firestoreProfile = await _getProfileFromFirestore();
      if (firestoreProfile != null) {
        // Salvar localmente para próximas consultas
        await _saveProfileLocally(firestoreProfile);
        return firestoreProfile.toEntity();
      }

      return null;
    } catch (e) {
      print('❌ Erro ao buscar perfil financeiro: $e');
      return null;
    }
  }

  /// Salvar perfil localmente
  Future<void> _saveProfileLocally(FinancialProfileModel profile) async {
    try {
      final db = await _localDataSource.database;
      
      // Criar tabela se não existir
      await _createProfileTableIfNotExists(db);
      
      await db.insert(
        'financial_profiles',
        profile.toSQLite(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print('✅ Perfil salvo localmente');
    } catch (e) {
      print('❌ Erro ao salvar perfil localmente: $e');
      throw e;
    }
  }

  /// Buscar perfil localmente
  Future<FinancialProfileModel?> _getProfileLocally() async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return null;

      final db = await _localDataSource.database;
      
      // Verificar se tabela existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='financial_profiles'"
      );
      if (tables.isEmpty) return null;

      final result = await db.query(
        'financial_profiles',
        where: 'userId = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return FinancialProfileModel.fromSQLite(result.first);
      }

      return null;
    } catch (e) {
      print('❌ Erro ao buscar perfil localmente: $e');
      return null;
    }
  }

  /// Buscar perfil no Firestore
  Future<FinancialProfileModel?> _getProfileFromFirestore() async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return null;

      final query = await _userProfilesCollection
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return FinancialProfileModel.fromFirestore(
          query.docs.first.data() as Map<String, dynamic>
        );
      }

      return null;
    } catch (e) {
      print('❌ Erro ao buscar perfil no Firestore: $e');
      return null;
    }
  }

  /// Salvar perfil no Firestore em background
  void _saveProfileToFirestoreInBackground(FinancialProfileModel profile) {
    Future.delayed(Duration.zero, () async {
      try {
        await _userProfilesCollection
            .doc(profile.id)
            .set(profile.toFirestore());
        print('✅ Perfil salvo no Firestore');
      } catch (e) {
        print('⚠️ Erro ao salvar perfil no Firestore: $e');
      }
    });
  }

  /// Criar tabela de perfis se não existir
  Future<void> _createProfileTableIfNotExists(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS financial_profiles (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        monthlyIncome REAL NOT NULL,
        totalBudget REAL NOT NULL,
        monthlyInvestmentGoal REAL DEFAULT 0.0,
        categoryBudgets TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');
    
    // Adicionar coluna monthlyInvestmentGoal se não existir (migração)
    try {
      await db.execute('ALTER TABLE financial_profiles ADD COLUMN monthlyInvestmentGoal REAL DEFAULT 0.0');
      print('✅ Coluna monthlyInvestmentGoal adicionada');
    } catch (e) {
      // Coluna já existe, ignorar erro
    }
  }

  // ==================== METAS FINANCEIRAS ====================

  /// Atualizar metas baseadas no perfil
  Future<void> _updateGoalsFromProfile(FinancialProfile profile) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);

      // Buscar metas existentes do mês atual
      final existingGoals = await getFinancialGoals(currentMonth);
      final existingGoalsMap = {for (var goal in existingGoals) goal.categoryId: goal};

      // Criar ou atualizar metas para cada categoria do orçamento
      for (final entry in profile.categoryBudgets.entries) {
        final categoryId = entry.key;
        final monthlyLimit = entry.value;

        final existingGoal = existingGoalsMap[categoryId];
        
        if (existingGoal != null) {
          // Atualizar meta existente
          final updatedGoal = existingGoal.copyWith(
            monthlyLimit: monthlyLimit,
            updatedAt: now,
          );
          await _saveGoal(updatedGoal, userId);
        } else {
          // Criar nova meta
          final newGoal = FinancialGoal(
            id: 'goal_${categoryId}_${currentMonth.millisecondsSinceEpoch}',
            categoryId: categoryId,
            categoryName: await _getCategoryName(categoryId),
            monthlyLimit: monthlyLimit,
            currentSpent: 0.0,
            month: currentMonth,
            isActive: true,
            createdAt: now,
            updatedAt: now,
          );
          await _saveGoal(newGoal, userId);
        }
      }

      // Desativar metas de categorias que não estão mais no orçamento
      for (final goal in existingGoals) {
        if (!profile.categoryBudgets.containsKey(goal.categoryId)) {
          final deactivatedGoal = goal.copyWith(
            isActive: false,
            updatedAt: now,
          );
          await _saveGoal(deactivatedGoal, userId);
        }
      }

      print('✅ Metas atualizadas baseadas no perfil');
    } catch (e) {
      print('❌ Erro ao atualizar metas: $e');
    }
  }

  /// Buscar metas financeiras de um mês
  Future<List<FinancialGoal>> getFinancialGoals(DateTime month) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return [];

      // Buscar localmente primeiro
      final localGoals = await _getGoalsLocally(month);
      if (localGoals.isNotEmpty) {
        return localGoals.map((g) => g.toEntity()).toList();
      }

      // Buscar no Firestore
      final firestoreGoals = await _getGoalsFromFirestore(month);
      
      // Salvar localmente
      for (final goal in firestoreGoals) {
        await _saveGoalLocally(goal);
      }

      return firestoreGoals.map((g) => g.toEntity()).toList();
    } catch (e) {
      print('❌ Erro ao buscar metas: $e');
      return [];
    }
  }

  /// Salvar meta
  Future<void> _saveGoal(FinancialGoal goal, String userId) async {
    try {
      final model = FinancialGoalModel.fromEntity(goal, userId);
      
      // Salvar localmente
      await _saveGoalLocally(model);
      
      // Salvar no Firestore em background
      _saveGoalToFirestoreInBackground(model);
      
    } catch (e) {
      print('❌ Erro ao salvar meta: $e');
      throw e;
    }
  }

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
        print('✅ Meta salva no Firestore');
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
        updatedAt INTEGER NOT NULL
      )
    ''');
  }

  /// Obter nome da categoria (método auxiliar)
  Future<String> _getCategoryName(String categoryId) async {
    try {
      // Buscar categorias usando o use case
      if (Get.isRegistered<GetCategoriesUseCase>()) {
        final getCategoriesUseCase = Get.find<GetCategoriesUseCase>();
        final categories = await getCategoriesUseCase.execute();
        
        // Usar lookup flexível para encontrar a categoria
        final category = _findCategoryById(categoryId, categories);
        if (category != null) {
          return category.name;
        }
      }
      
      // Fallback: tentar obter nome pelo ID base
      return _getCategoryNameFromId(categoryId);
    } catch (e) {
      print('⚠️ Erro ao buscar nome da categoria: $e');
      return _getCategoryNameFromId(categoryId);
    }
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

  /// Atualizar valor gasto em uma meta
  Future<void> updateGoalSpentAmount(String categoryId, double newAmount) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);
      
      final goals = await getFinancialGoals(currentMonth);
      final goal = goals.firstWhereOrNull((g) => g.categoryId == categoryId);
      
      if (goal != null) {
        final updatedGoal = goal.copyWith(
          currentSpent: newAmount,
          updatedAt: now,
        );
        await _saveGoal(updatedGoal, userId);
      }
    } catch (e) {
      print('❌ Erro ao atualizar valor gasto da meta: $e');
    }
  }
}
