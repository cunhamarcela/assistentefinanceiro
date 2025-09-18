import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';
import '../../../auth/data/services/auth_service.dart';

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
  }

  /// Obter referência da coleção de despesas do usuário
  CollectionReference get _userExpensesCollection {
    final userId = _authService.currentUser?.id;
    if (userId == null) {
      print('❌ Usuário não autenticado no Firestore');
      throw Exception('Usuário não autenticado');
    }
    
    print('🔗 Criando referência Firestore para usuário: $userId');
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
    const maxRetries = 2;
    const timeoutDuration = Duration(seconds: 5);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🔥 Tentativa $attempt/$maxRetries - Salvando: ${expense.description}');
        
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
                print('⏰ Timeout na tentativa $attempt (${timeoutDuration.inSeconds}s)');
                throw Exception('Timeout na tentativa $attempt');
              },
            );
        
        print('✅ Despesa salva no Firestore: ${expense.description}');
        return; // Sucesso, sair do loop
        
      } catch (e) {
        print('❌ Erro na tentativa $attempt: $e');
        
        if (attempt == maxRetries) {
          // Última tentativa falhou
          print('💥 Todas as tentativas falharam. Funcionando offline.');
          throw Exception('Firestore indisponível após $maxRetries tentativas');
        } else {
          // Aguardar antes da próxima tentativa
          print('⏳ Aguardando 2s antes da próxima tentativa...');
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
  }

  /// Atualizar despesa no Firestore
  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      await _userExpensesCollection
          .doc(expense.id)
          .update({
            ...expense.toFirestore(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      print('✅ Despesa atualizada no Firestore: ${expense.description}');
    } catch (e) {
      print('❌ Erro ao atualizar despesa no Firestore: $e');
      throw Exception('Erro ao atualizar despesa: $e');
    }
  }

  /// Deletar despesa do Firestore
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _userExpensesCollection.doc(expenseId).delete();
      print('✅ Despesa removida do Firestore');
    } catch (e) {
      print('❌ Erro ao deletar despesa do Firestore: $e');
      throw Exception('Erro ao deletar despesa: $e');
    }
  }

  /// Buscar despesa por ID
  Future<ExpenseModel?> getExpenseById(String expenseId) async {
    try {
      final doc = await _userExpensesCollection.doc(expenseId).get();
      
      if (doc.exists && doc.data() != null) {
        return ExpenseModel.fromFirestore(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao buscar despesa no Firestore: $e');
      return null;
    }
  }

  /// Buscar todas as despesas
  Future<List<ExpenseModel>> getAllExpenses() async {
    try {
      final query = await _userExpensesCollection
          .orderBy('date', descending: true)
          .get();

      return query.docs
          .map((doc) => ExpenseModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Erro ao buscar despesas no Firestore: $e');
      return [];
    }
  }

  /// Buscar despesas por período
  Future<List<ExpenseModel>> getExpensesByDateRange(DateTime start, DateTime end) async {
    try {
      final query = await _userExpensesCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('date', descending: true)
          .get();

      return query.docs
          .map((doc) => ExpenseModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Erro ao buscar despesas por período no Firestore: $e');
      return [];
    }
  }

  /// Buscar despesas por categoria
  Future<List<ExpenseModel>> getExpensesByCategory(String categoryId) async {
    try {
      final query = await _userExpensesCollection
          .where('categoryId', isEqualTo: categoryId)
          .orderBy('date', descending: true)
          .get();

      return query.docs
          .map((doc) => ExpenseModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Erro ao buscar despesas por categoria no Firestore: $e');
      return [];
    }
  }

  /// Buscar despesas por texto
  Future<List<ExpenseModel>> searchExpenses(String query) async {
    try {
      // Firestore não suporta LIKE, então fazemos busca por array de palavras
      final searchQuery = await _userExpensesCollection
          .where('searchTerms', arrayContainsAny: query.toLowerCase().split(' '))
          .orderBy('date', descending: true)
          .get();

      return searchQuery.docs
          .map((doc) => ExpenseModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Erro ao buscar despesas por texto no Firestore: $e');
      return [];
    }
  }

  /// Stream de despesas em tempo real
  Stream<List<ExpenseModel>> getExpensesStream() {
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
    try {
      await _userCategoriesCollection
          .doc(category.id)
          .set(category.toFirestore());
      
      print('✅ Categoria salva no Firestore: ${category.name}');
    } catch (e) {
      print('❌ Erro ao salvar categoria no Firestore: $e');
      throw Exception('Erro ao salvar categoria: $e');
    }
  }

  /// Buscar todas as categorias
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      final query = await _userCategoriesCollection
          .orderBy('name')
          .get();

      return query.docs
          .map((doc) => CategoryModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Erro ao buscar categorias no Firestore: $e');
      return [];
    }
  }

  /// Deletar categoria do Firestore
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _userCategoriesCollection.doc(categoryId).delete();
      print('✅ Categoria removida do Firestore');
    } catch (e) {
      print('❌ Erro ao deletar categoria do Firestore: $e');
      throw Exception('Erro ao deletar categoria: $e');
    }
  }

  /// Inicializar categorias padrão para novo usuário
  Future<void> initializeDefaultCategories() async {
    try {
      final existingCategories = await getAllCategories();
      if (existingCategories.isNotEmpty) return; // Já tem categorias

      final defaultCategories = CategoryModel.defaultCategories;
      
      for (final category in defaultCategories) {
        await saveCategory(category);
      }
      
      print('✅ Categorias padrão inicializadas no Firestore');
    } catch (e) {
      print('❌ Erro ao inicializar categorias padrão: $e');
    }
  }

  // ==================== RELATÓRIOS ====================

  /// Salvar relatório no Firestore
  Future<void> saveReport(Map<String, dynamic> reportData) async {
    try {
      final reportId = '${reportData['type']}_${reportData['period']}_${DateTime.now().millisecondsSinceEpoch}';
      
      await _userReportsCollection
          .doc(reportId)
          .set({
            ...reportData,
            'createdAt': FieldValue.serverTimestamp(),
            'userId': _authService.currentUser?.id,
          });
      
      print('✅ Relatório salvo no Firestore: ${reportData['type']}');
    } catch (e) {
      print('❌ Erro ao salvar relatório no Firestore: $e');
      throw Exception('Erro ao salvar relatório: $e');
    }
  }

  /// Buscar relatórios do usuário
  Future<List<Map<String, dynamic>>> getUserReports() async {
    try {
      final query = await _userReportsCollection
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return query.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('❌ Erro ao buscar relatórios no Firestore: $e');
      return [];
    }
  }

  // ==================== ESTATÍSTICAS ====================

  /// Obter estatísticas do usuário
  Future<Map<String, dynamic>> getUserStats() async {
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

      return {
        'totalMonth': totalMonth,
        'totalToday': totalToday,
        'expensesCount': allExpenses.length,
        'monthExpensesCount': monthExpenses.length,
        'todayExpensesCount': todayExpenses.length,
        'categoryStats': categoryStats,
        'lastUpdated': FieldValue.serverTimestamp(),
      };
    } catch (e) {
      print('❌ Erro ao obter estatísticas no Firestore: $e');
      return {};
    }
  }

  // ==================== SINCRONIZAÇÃO ====================

  /// Sincronizar dados locais com Firestore
  Future<void> syncLocalDataToFirestore(List<ExpenseModel> localExpenses, List<CategoryModel> localCategories) async {
    try {
      print('🔄 Iniciando sincronização com Firestore...');

      // Sincronizar categorias
      for (final category in localCategories) {
        await saveCategory(category);
      }

      // Sincronizar despesas
      for (final expense in localExpenses) {
        await saveExpense(expense);
      }

      print('✅ Sincronização concluída com sucesso!');
    } catch (e) {
      print('❌ Erro na sincronização: $e');
      throw Exception('Erro na sincronização: $e');
    }
  }
}
