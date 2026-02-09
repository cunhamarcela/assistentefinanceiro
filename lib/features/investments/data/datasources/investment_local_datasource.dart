import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:get/get.dart';
import '../models/investment_model.dart';
import '../../../auth/data/services/auth_service.dart';

class InvestmentLocalDataSource {
  static Database? _database;
  static const String _databaseName = 'investments.db';
  static const int _databaseVersion = 1;

  static const String _investmentsTable = 'investments';

  String get _currentUserId {
    try {
      final authService = Get.find<AuthService>();
      return authService.currentUser?.id ?? '';
    } catch (e) {
      return '';
    }
  }

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
    await db.execute('''
      CREATE TABLE $_investmentsTable (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL,
        date INTEGER NOT NULL,
        notes TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        institution TEXT,
        expectedReturn REAL,
        maturityDate INTEGER
      )
    ''');

    await db.execute('CREATE INDEX idx_investments_userId ON $_investmentsTable (userId)');
    await db.execute('CREATE INDEX idx_investments_date ON $_investmentsTable (date)');
    await db.execute('CREATE INDEX idx_investments_type ON $_investmentsTable (type)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Implementar migrações futuras aqui
  }

  // CRUD Investimentos
  Future<void> insertInvestment(InvestmentModel investment) async {
    final db = await database;
    final userId = _currentUserId;
    final investmentData = investment.toSQLite();
    investmentData['userId'] = userId;
    
    await db.insert(_investmentsTable, investmentData, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateInvestment(InvestmentModel investment) async {
    final db = await database;
    final userId = _currentUserId;
    final investmentData = investment.toSQLite();
    investmentData['userId'] = userId;
    
    await db.update(
      _investmentsTable,
      investmentData,
      where: 'id = ? AND userId = ?',
      whereArgs: [investment.id, userId],
    );
  }

  Future<void> deleteInvestment(String id) async {
    final db = await database;
    final userId = _currentUserId;
    
    await db.delete(
      _investmentsTable,
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  Future<InvestmentModel?> getInvestmentById(String id) async {
    final db = await database;
    final userId = _currentUserId;
    
    final maps = await db.query(
      _investmentsTable,
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return InvestmentModel.fromSQLite(maps.first);
  }

  Future<List<InvestmentModel>> getAllInvestments() async {
    final db = await database;
    final userId = _currentUserId;
    
    final maps = await db.query(
      _investmentsTable,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    
    return maps.map((map) => InvestmentModel.fromSQLite(map)).toList();
  }

  Future<List<InvestmentModel>> getInvestmentsByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final userId = _currentUserId;
    
    final maps = await db.query(
      _investmentsTable,
      where: 'userId = ? AND date >= ? AND date <= ?',
      whereArgs: [
        userId,
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'date DESC',
    );
    
    return maps.map((map) => InvestmentModel.fromSQLite(map)).toList();
  }

  Future<List<InvestmentModel>> getInvestmentsByType(String type) async {
    final db = await database;
    final userId = _currentUserId;
    
    final maps = await db.query(
      _investmentsTable,
      where: 'userId = ? AND type = ?',
      whereArgs: [userId, type],
      orderBy: 'date DESC',
    );
    
    return maps.map((map) => InvestmentModel.fromSQLite(map)).toList();
  }

  Future<List<InvestmentModel>> getCurrentMonthInvestments() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    return getInvestmentsByDateRange(startOfMonth, endOfMonth);
  }

  Future<double> getTotalByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final userId = _currentUserId;
    
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM $_investmentsTable
      WHERE userId = ? AND date >= ? AND date <= ?
    ''', [
      userId,
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
    ]);
    
    if (result.isEmpty || result.first['total'] == null) return 0.0;
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getTotalByType(String type) async {
    final db = await database;
    final userId = _currentUserId;
    
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM $_investmentsTable
      WHERE userId = ? AND type = ?
    ''', [userId, type]);
    
    if (result.isEmpty || result.first['total'] == null) return 0.0;
    return (result.first['total'] as num).toDouble();
  }

  Future<List<InvestmentModel>> searchInvestments(String query) async {
    final db = await database;
    final userId = _currentUserId;
    final searchTerm = '%$query%';
    
    final maps = await db.query(
      _investmentsTable,
      where: 'userId = ? AND (description LIKE ? OR notes LIKE ?)',
      whereArgs: [userId, searchTerm, searchTerm],
      orderBy: 'date DESC',
    );
    
    return maps.map((map) => InvestmentModel.fromSQLite(map)).toList();
  }
}

