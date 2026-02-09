import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:get/get.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../../expenses/domain/entities/financial_insight.dart';
import '../../../auth/data/services/auth_service.dart';

/// Interface para cache local do chat IA
abstract class ChatIaCacheDataSource {
  Future<void> saveConversation(ChatConversation conversation);
  Future<ChatConversation?> getConversation(String conversationId);
  Future<List<ChatConversation>> getUserConversations(String userId);
  Future<void> deleteConversation(String conversationId);
  Future<void> saveMessage(ChatMessage message, String conversationId);
  Future<void> updateMessageStatus(String messageId, String conversationId, ChatMessageStatus status, {String? errorMessage});
  Future<List<ChatMessage>> searchMessages(String query, String userId);
  Future<void> clearOldConversations(String userId, {int keepDays = 30});
  Future<void> saveInsight(FinancialInsight insight);
  Future<List<FinancialInsight>> getUserInsights(String userId);
}

/// Implementação do cache local usando SQLite
class ChatIaCacheDataSourceImpl implements ChatIaCacheDataSource {
  static Database? _database;
  static const String _databaseName = 'chat_ia.db';
  static const int _databaseVersion = 1;

  // Tabelas
  static const String _conversationsTable = 'conversations';
  static const String _messagesTable = 'messages';
  static const String _insightsTable = 'insights';

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
    // Tabela de conversas
    await db.execute('''
      CREATE TABLE $_conversationsTable (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        metadata TEXT
      )
    ''');

    // Tabela de mensagens
    await db.execute('''
      CREATE TABLE $_messagesTable (
        id TEXT PRIMARY KEY,
        conversationId TEXT NOT NULL,
        content TEXT NOT NULL,
        role TEXT NOT NULL,
        status TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        metadata TEXT,
        errorMessage TEXT,
        FOREIGN KEY (conversationId) REFERENCES $_conversationsTable (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de insights financeiros
    await db.execute('''
      CREATE TABLE $_insightsTable (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL,
        priority TEXT NOT NULL,
        data TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        expiresAt INTEGER,
        tags TEXT,
        actionText TEXT,
        actionRoute TEXT
      )
    ''');

    // Índices para performance
    await db.execute('CREATE INDEX idx_conversations_userId ON $_conversationsTable (userId)');
    await db.execute('CREATE INDEX idx_conversations_updatedAt ON $_conversationsTable (updatedAt DESC)');
    await db.execute('CREATE INDEX idx_messages_conversationId ON $_messagesTable (conversationId)');
    await db.execute('CREATE INDEX idx_messages_createdAt ON $_messagesTable (createdAt)');
    await db.execute('CREATE INDEX idx_insights_userId ON $_insightsTable (userId)');
    await db.execute('CREATE INDEX idx_insights_createdAt ON $_insightsTable (createdAt DESC)');
  }

  /// Obter userId atual
  String get _currentUserId {
    try {
      final authService = Get.find<AuthService>();
      final userId = authService.currentUser?.id;
      if (userId == null || userId.isEmpty) {
        throw Exception('Usuário não autenticado');
      }
      return userId;
    } catch (e) {
      print('❌ Erro ao obter userId no chat cache: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveConversation(ChatConversation conversation) async {
    try {
      final db = await database;
      
      await db.insert(
        _conversationsTable,
        {
          'id': conversation.id,
          'userId': conversation.userId,
          'title': conversation.title,
          'createdAt': conversation.createdAt.millisecondsSinceEpoch,
          'updatedAt': conversation.updatedAt.millisecondsSinceEpoch,
          'metadata': conversation.metadata != null ? _encodeJson(conversation.metadata!) : null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('✅ Conversa salva no cache: ${conversation.id}');
    } catch (e) {
      print('❌ Erro ao salvar conversa no cache: $e');
      throw Exception('Erro ao salvar conversa: $e');
    }
  }

  @override
  Future<ChatConversation?> getConversation(String conversationId) async {
    try {
      final db = await database;
      
      // Buscar conversa
      final conversationResult = await db.query(
        _conversationsTable,
        where: 'id = ?',
        whereArgs: [conversationId],
      );

      if (conversationResult.isEmpty) return null;

      final conversationData = conversationResult.first;

      // Buscar mensagens da conversa
      final messagesResult = await db.query(
        _messagesTable,
        where: 'conversationId = ?',
        whereArgs: [conversationId],
        orderBy: 'createdAt ASC',
      );

      final messages = messagesResult.map((messageData) {
        return ChatMessage(
          id: messageData['id'] as String,
          content: messageData['content'] as String,
          role: _parseMessageRole(messageData['role'] as String),
          status: _parseMessageStatus(messageData['status'] as String),
          createdAt: DateTime.fromMillisecondsSinceEpoch(messageData['createdAt'] as int),
          metadata: messageData['metadata'] != null ? _decodeJson(messageData['metadata'] as String) : null,
          errorMessage: messageData['errorMessage'] as String?,
        );
      }).toList();

      return ChatConversation(
        id: conversationData['id'] as String,
        userId: conversationData['userId'] as String,
        title: conversationData['title'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(conversationData['createdAt'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(conversationData['updatedAt'] as int),
        metadata: conversationData['metadata'] != null ? _decodeJson(conversationData['metadata'] as String) : null,
        messages: messages,
      );
    } catch (e) {
      print('❌ Erro ao buscar conversa no cache: $e');
      return null;
    }
  }

  @override
  Future<List<ChatConversation>> getUserConversations(String userId) async {
    try {
      final db = await database;
      
      final result = await db.query(
        _conversationsTable,
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'updatedAt DESC',
      );

      final conversations = <ChatConversation>[];
      
      for (final conversationData in result) {
        final conversationId = conversationData['id'] as String;
        
        // Buscar mensagens da conversa
        final messagesResult = await db.query(
          _messagesTable,
          where: 'conversationId = ?',
          whereArgs: [conversationId],
          orderBy: 'createdAt ASC',
        );

        final messages = messagesResult.map((messageData) {
          return ChatMessage(
            id: messageData['id'] as String,
            content: messageData['content'] as String,
            role: _parseMessageRole(messageData['role'] as String),
            status: _parseMessageStatus(messageData['status'] as String),
            createdAt: DateTime.fromMillisecondsSinceEpoch(messageData['createdAt'] as int),
            metadata: messageData['metadata'] != null ? _decodeJson(messageData['metadata'] as String) : null,
            errorMessage: messageData['errorMessage'] as String?,
          );
        }).toList();

        conversations.add(ChatConversation(
          id: conversationId,
          userId: conversationData['userId'] as String,
          title: conversationData['title'] as String?,
          createdAt: DateTime.fromMillisecondsSinceEpoch(conversationData['createdAt'] as int),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(conversationData['updatedAt'] as int),
          metadata: conversationData['metadata'] != null ? _decodeJson(conversationData['metadata'] as String) : null,
          messages: messages,
        ));
      }

      return conversations;
    } catch (e) {
      print('❌ Erro ao buscar conversas do usuário: $e');
      return [];
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    try {
      final db = await database;
      
      // As mensagens serão deletadas automaticamente devido ao CASCADE
      await db.delete(
        _conversationsTable,
        where: 'id = ?',
        whereArgs: [conversationId],
      );

      print('✅ Conversa deletada do cache: $conversationId');
    } catch (e) {
      print('❌ Erro ao deletar conversa do cache: $e');
      throw Exception('Erro ao deletar conversa: $e');
    }
  }

  @override
  Future<void> saveMessage(ChatMessage message, String conversationId) async {
    try {
      final db = await database;
      
      await db.insert(
        _messagesTable,
        {
          'id': message.id,
          'conversationId': conversationId,
          'content': message.content,
          'role': message.role.name,
          'status': message.status.name,
          'createdAt': message.createdAt.millisecondsSinceEpoch,
          'metadata': message.metadata != null ? _encodeJson(message.metadata!) : null,
          'errorMessage': message.errorMessage,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('✅ Mensagem salva no cache: ${message.id}');
    } catch (e) {
      print('❌ Erro ao salvar mensagem no cache: $e');
      throw Exception('Erro ao salvar mensagem: $e');
    }
  }

  @override
  Future<void> updateMessageStatus(
    String messageId,
    String conversationId,
    ChatMessageStatus status, {
    String? errorMessage,
  }) async {
    try {
      final db = await database;
      
      await db.update(
        _messagesTable,
        {
          'status': status.name,
          'errorMessage': errorMessage,
        },
        where: 'id = ? AND conversationId = ?',
        whereArgs: [messageId, conversationId],
      );

      print('✅ Status da mensagem atualizado: $messageId -> ${status.name}');
    } catch (e) {
      print('❌ Erro ao atualizar status da mensagem: $e');
      throw Exception('Erro ao atualizar status da mensagem: $e');
    }
  }

  @override
  Future<List<ChatMessage>> searchMessages(String query, String userId) async {
    try {
      final db = await database;
      
      final result = await db.rawQuery('''
        SELECT m.* FROM $_messagesTable m
        INNER JOIN $_conversationsTable c ON m.conversationId = c.id
        WHERE c.userId = ? AND m.content LIKE ?
        ORDER BY m.createdAt DESC
        LIMIT 50
      ''', [userId, '%$query%']);

      return result.map((messageData) {
        return ChatMessage(
          id: messageData['id'] as String,
          content: messageData['content'] as String,
          role: _parseMessageRole(messageData['role'] as String),
          status: _parseMessageStatus(messageData['status'] as String),
          createdAt: DateTime.fromMillisecondsSinceEpoch(messageData['createdAt'] as int),
          metadata: messageData['metadata'] != null ? _decodeJson(messageData['metadata'] as String) : null,
          errorMessage: messageData['errorMessage'] as String?,
        );
      }).toList();
    } catch (e) {
      print('❌ Erro ao buscar mensagens: $e');
      return [];
    }
  }

  @override
  Future<void> clearOldConversations(String userId, {int keepDays = 30}) async {
    try {
      final db = await database;
      final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
      
      await db.delete(
        _conversationsTable,
        where: 'userId = ? AND updatedAt < ?',
        whereArgs: [userId, cutoffDate.millisecondsSinceEpoch],
      );

      print('✅ Conversas antigas removidas (mais de $keepDays dias)');
    } catch (e) {
      print('❌ Erro ao limpar conversas antigas: $e');
    }
  }

  @override
  Future<void> saveInsight(FinancialInsight insight) async {
    try {
      final db = await database;
      
      await db.insert(
        _insightsTable,
        {
          'id': insight.id,
          'userId': _currentUserId,
          'title': insight.title,
          'description': insight.description,
          'type': insight.type.name,
          'priority': insight.priority.name,
          'data': _encodeJson(insight.data),
          'createdAt': insight.createdAt.millisecondsSinceEpoch,
          'expiresAt': null,
          'tags': '',
          'actionText': insight.actionSuggestions.isNotEmpty ? insight.actionSuggestions.first : null,
          'actionRoute': null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('✅ Insight salvo no cache: ${insight.id}');
    } catch (e) {
      print('❌ Erro ao salvar insight no cache: $e');
      throw Exception('Erro ao salvar insight: $e');
    }
  }

  @override
  Future<List<FinancialInsight>> getUserInsights(String userId) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final result = await db.query(
        _insightsTable,
        where: 'userId = ? AND (expiresAt IS NULL OR expiresAt > ?)',
        whereArgs: [userId, now],
        orderBy: 'createdAt DESC',
      );

      return result.map((insightData) {
        return FinancialInsight(
          id: insightData['id'] as String,
          title: insightData['title'] as String,
          description: insightData['description'] as String,
          type: _parseInsightType(insightData['type'] as String),
          priority: _parseInsightPriority(insightData['priority'] as String),
          data: _decodeJson(insightData['data'] as String),
          actionSuggestions: [
            if (insightData['actionText'] != null) insightData['actionText'] as String
          ],
          createdAt: DateTime.fromMillisecondsSinceEpoch(insightData['createdAt'] as int),
          isRead: false,
        );
      }).toList();
    } catch (e) {
      print('❌ Erro ao buscar insights do usuário: $e');
      return [];
    }
  }

  // Métodos auxiliares para parsing
  ChatMessageRole _parseMessageRole(String role) {
    switch (role) {
      case 'user':
        return ChatMessageRole.user;
      case 'assistant':
        return ChatMessageRole.assistant;
      case 'system':
        return ChatMessageRole.system;
      default:
        return ChatMessageRole.user;
    }
  }

  ChatMessageStatus _parseMessageStatus(String status) {
    switch (status) {
      case 'sending':
        return ChatMessageStatus.sending;
      case 'sent':
        return ChatMessageStatus.sent;
      case 'error':
        return ChatMessageStatus.error;
      default:
        return ChatMessageStatus.sent;
    }
  }

  FinancialInsightType _parseInsightType(String type) {
    switch (type) {
      case 'budgetExceeded':
        return FinancialInsightType.budgetExceeded;
      case 'budgetWarning':
        return FinancialInsightType.budgetWarning;
      case 'savingsOpportunity':
        return FinancialInsightType.savingsOpportunity;
      case 'goalProgress':
        return FinancialInsightType.goalProgress;
      case 'spendingPattern':
        return FinancialInsightType.spendingPattern;
      case 'categoryAnalysis':
        return FinancialInsightType.categoryAnalysis;
      case 'monthlyComparison':
        return FinancialInsightType.monthlyComparison;
      default:
        return FinancialInsightType.spendingPattern;
    }
  }

  FinancialInsightPriority _parseInsightPriority(String priority) {
    switch (priority) {
      case 'low':
        return FinancialInsightPriority.low;
      case 'medium':
        return FinancialInsightPriority.medium;
      case 'high':
        return FinancialInsightPriority.high;
      case 'urgent':
        return FinancialInsightPriority.urgent;
      default:
        return FinancialInsightPriority.medium;
    }
  }

  // Métodos auxiliares para JSON
  String _encodeJson(Map<String, dynamic> data) {
    // Implementação simples - em produção usar json.encode
    return data.toString();
  }

  Map<String, dynamic> _decodeJson(String data) {
    // Implementação simples - em produção usar json.decode
    return <String, dynamic>{};
  }
}
