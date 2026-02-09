import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../../expenses/domain/entities/financial_insight.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_ia_remote_datasource.dart';
import '../datasources/chat_ia_cache_datasource.dart';

/// Implementação do repositório de chat IA
class ChatRepositoryImpl implements ChatRepository {
  final ChatIaRemoteDataSource remoteDataSource;
  final ChatIaCacheDataSource cacheDataSource;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.cacheDataSource,
  });

  @override
  Future<ChatMessage> generateAssistantReply({
    required List<ChatMessage> conversationHistory,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Tenta gerar resposta usando o serviço remoto
      final response = await remoteDataSource.generateAssistantReply(
        conversationHistory: conversationHistory,
        context: context,
      );

      return response;
    } catch (e) {
      print('❌ Erro ao gerar resposta remota, usando fallback: $e');
      
      // Fallback para resposta offline
      return ChatMessage.assistant(
        content: '📡 **Conexão temporariamente indisponível**\n\n'
                'Mas você ainda pode usar o app normalmente!\n\n'
                '💰 **Registrar gastos:**\n'
                '• "Gastei 50 no mercado"\n'
                '• "Almoço 35 reais"\n\n'
                '📊 **Use as perguntas rápidas** abaixo para análises!\n\n'
                '🔄 _Verifique sua conexão e tente novamente._',
        metadata: {
          'type': 'offline_fallback',
          'has_insight': false,
          'error': e.toString(),
        },
        status: ChatMessageStatus.sent,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> analyzeUserMessage(String message) async {
    try {
      return await remoteDataSource.analyzeUserMessage(message);
    } catch (e) {
      print('❌ Erro ao analisar mensagem: $e');
      return {
        'message': message,
        'intent': 'unknown',
        'confidence': 0.0,
        'error': e.toString(),
      };
    }
  }

  @override
  Future<List<FinancialInsight>> generateFinancialInsights({
    required String userId,
    int? limitDays,
  }) async {
    try {
      // Tenta gerar insights remotamente
      final insights = await remoteDataSource.generateFinancialInsights(
        userId: userId,
        limitDays: limitDays,
      );

      // Salva insights no cache local
      for (final insight in insights) {
        try {
          await cacheDataSource.saveInsight(insight);
        } catch (e) {
          print('⚠️ Erro ao salvar insight no cache: $e');
        }
      }

      return insights;
    } catch (e) {
      print('❌ Erro ao gerar insights remotos, buscando cache: $e');
      
      // Fallback para insights do cache
      try {
        return await cacheDataSource.getUserInsights(userId);
      } catch (cacheError) {
        print('❌ Erro ao buscar insights do cache: $cacheError');
        return [];
      }
    }
  }

  @override
  Future<void> saveConversation(ChatConversation conversation) async {
    try {
      // Salva no cache local primeiro (mais rápido)
      await cacheDataSource.saveConversation(conversation);
      
      // TODO: Implementar sincronização com Firestore em background
      // await _syncConversationToFirestore(conversation);
    } catch (e) {
      print('❌ Erro ao salvar conversa: $e');
      throw Exception('Erro ao salvar conversa: $e');
    }
  }

  @override
  Future<ChatConversation?> getConversation(String conversationId) async {
    try {
      // Busca primeiro no cache local
      final conversation = await cacheDataSource.getConversation(conversationId);
      
      if (conversation != null) {
        return conversation;
      }

      // TODO: Se não encontrar no cache, buscar no Firestore
      // return await _getConversationFromFirestore(conversationId);
      
      return null;
    } catch (e) {
      print('❌ Erro ao buscar conversa: $e');
      return null;
    }
  }

  @override
  Future<List<ChatConversation>> getUserConversations(String userId) async {
    try {
      // Busca conversas do cache local
      final conversations = await cacheDataSource.getUserConversations(userId);
      
      // TODO: Sincronizar com Firestore em background
      // _syncConversationsFromFirestore(userId);
      
      return conversations;
    } catch (e) {
      print('❌ Erro ao buscar conversas do usuário: $e');
      return [];
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Remove do cache local
      await cacheDataSource.deleteConversation(conversationId);
      
      // TODO: Remover do Firestore
      // await _deleteConversationFromFirestore(conversationId);
    } catch (e) {
      print('❌ Erro ao deletar conversa: $e');
      throw Exception('Erro ao deletar conversa: $e');
    }
  }

  @override
  Future<void> saveMessage(ChatMessage message, String conversationId) async {
    try {
      // Salva mensagem no cache local
      await cacheDataSource.saveMessage(message, conversationId);
      
      // TODO: Sincronizar com Firestore
      // await _syncMessageToFirestore(message, conversationId);
    } catch (e) {
      print('❌ Erro ao salvar mensagem: $e');
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
      await cacheDataSource.updateMessageStatus(
        messageId,
        conversationId,
        status,
        errorMessage: errorMessage,
      );
      
      // TODO: Sincronizar status com Firestore
      // await _syncMessageStatusToFirestore(messageId, conversationId, status, errorMessage);
    } catch (e) {
      print('❌ Erro ao atualizar status da mensagem: $e');
      throw Exception('Erro ao atualizar status da mensagem: $e');
    }
  }

  @override
  Future<List<ChatMessage>> searchMessages(String query, String userId) async {
    try {
      // Busca no cache local
      final localResults = await cacheDataSource.searchMessages(query, userId);
      
      // TODO: Complementar com busca no Firestore se necessário
      // final remoteResults = await _searchMessagesInFirestore(query, userId);
      
      return localResults;
    } catch (e) {
      print('❌ Erro ao buscar mensagens: $e');
      return [];
    }
  }

  @override
  Future<void> clearOldConversations(String userId, {int keepDays = 30}) async {
    try {
      await cacheDataSource.clearOldConversations(userId, keepDays: keepDays);
      
      // TODO: Limpar também do Firestore
      // await _clearOldConversationsFromFirestore(userId, keepDays);
    } catch (e) {
      print('❌ Erro ao limpar conversas antigas: $e');
    }
  }

  @override
  Future<bool> isAiServiceAvailable() async {
    try {
      return await remoteDataSource.isAiServiceAvailable();
    } catch (e) {
      print('❌ Erro ao verificar disponibilidade da IA: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getChatSettings(String userId) async {
    try {
      return await remoteDataSource.getChatSettings(userId);
    } catch (e) {
      print('❌ Erro ao buscar configurações do chat: $e');
      return {
        'ai_enabled': true,
        'auto_insights': true,
        'response_style': 'friendly',
      };
    }
  }

  @override
  Future<void> updateChatSettings(String userId, Map<String, dynamic> settings) async {
    try {
      await remoteDataSource.updateChatSettings(userId, settings);
    } catch (e) {
      print('❌ Erro ao atualizar configurações do chat: $e');
      throw Exception('Erro ao atualizar configurações: $e');
    }
  }

  // TODO: Métodos privados para sincronização com Firestore
  // Estes métodos serão implementados quando necessário para sincronização completa
  
  /*
  Future<void> _syncConversationToFirestore(ChatConversation conversation) async {
    // Implementar sincronização da conversa com Firestore
  }

  Future<ChatConversation?> _getConversationFromFirestore(String conversationId) async {
    // Implementar busca de conversa no Firestore
  }

  Future<void> _syncConversationsFromFirestore(String userId) async {
    // Implementar sincronização de conversas do Firestore
  }

  Future<void> _deleteConversationFromFirestore(String conversationId) async {
    // Implementar remoção de conversa do Firestore
  }

  Future<void> _syncMessageToFirestore(ChatMessage message, String conversationId) async {
    // Implementar sincronização de mensagem com Firestore
  }

  Future<void> _syncMessageStatusToFirestore(
    String messageId,
    String conversationId,
    ChatMessageStatus status,
    String? errorMessage,
  ) async {
    // Implementar sincronização de status com Firestore
  }

  Future<List<ChatMessage>> _searchMessagesInFirestore(String query, String userId) async {
    // Implementar busca de mensagens no Firestore
  }

  Future<void> _clearOldConversationsFromFirestore(String userId, int keepDays) async {
    // Implementar limpeza de conversas antigas no Firestore
  }
  */
}
