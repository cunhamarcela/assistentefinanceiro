import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/credit_card_model.dart';

/// Datasource local para cartões de crédito (SQLite)
class CreditCardLocalDataSource {
  static Database? _database;
  static const String _databaseName = 'credit_cards.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'credit_cards';

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
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        lastFourDigits TEXT NOT NULL,
        closingDay INTEGER NOT NULL,
        dueDay INTEGER NOT NULL,
        cardLimit REAL,
        flag TEXT,
        color TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');
  }

  /// Adiciona um novo cartão
  Future<void> addCard(CreditCardModel card) async {
    print('💳 [LocalDataSource] Obtendo database...');
    final db = await database;
    print('💳 [LocalDataSource] Database obtido, convertendo para SQLite...');
    final data = card.toSQLite();
    print('💳 [LocalDataSource] Dados convertidos: $data');
    print('💳 [LocalDataSource] Inserindo no banco...');
    await db.insert(
      _tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('💳 [LocalDataSource] ✅ Cartão inserido no SQLite!');
  }

  /// Obtém todos os cartões
  Future<List<CreditCardModel>> getAllCards() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => CreditCardModel.fromSQLite(map)).toList();
  }

  /// Obtém apenas cartões ativos
  Future<List<CreditCardModel>> getActiveCards() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );

    return maps.map((map) => CreditCardModel.fromSQLite(map)).toList();
  }

  /// Obtém um cartão por ID
  Future<CreditCardModel?> getCardById(String id) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return CreditCardModel.fromSQLite(maps.first);
  }

  /// Atualiza um cartão
  Future<void> updateCard(CreditCardModel card) async {
    final db = await database;
    await db.update(
      _tableName,
      card.toSQLite(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  /// Deleta um cartão (soft delete - apenas marca como inativo)
  Future<void> deleteCard(String id) async {
    final db = await database;
    await db.update(
      _tableName,
      {'isActive': 0, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deleta permanentemente um cartão
  Future<void> permanentlyDeleteCard(String id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Limpa todos os cartões
  Future<void> clearAllCards() async {
    final db = await database;
    await db.delete(_tableName);
  }
}

