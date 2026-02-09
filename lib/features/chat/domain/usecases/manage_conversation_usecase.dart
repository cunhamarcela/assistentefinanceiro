import '../entities/chat_conversation.dart';
import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

/// Use case para gerenciar conversas do chat
class ManageConversationUseCase {
  final ChatRepository repository;

  ManageConversationUseCase(this.repository);

  /// Cria uma nova conversa
  Future<ChatConversation> createConversation({
    required String userId,
    String? title,
    Map<String, dynamic>? metadata,
  }) async {
    final conversation = ChatConversation.create(
      userId: userId,
      title: title,
      metadata: metadata,
    );

    await repository.saveConversation(conversation);
    return conversation;
  }

  /// Adiciona uma mensagem à conversa
  Future<ChatConversation> addMessageToConversation({
    required String conversationId,
    required ChatMessage message,
  }) async {
    // Carrega a conversa atual
    final conversation = await repository.getConversation(conversationId);
    if (conversation == null) {
      throw Exception('Conversa não encontrada: $conversationId');
    }

    // Adiciona a mensagem
    final updatedConversation = conversation.addMessage(message);

    // Salva a mensagem e atualiza a conversa
    await repository.saveMessage(message, conversationId);
    await repository.saveConversation(updatedConversation);

    return updatedConversation;
  }

  /// Atualiza o status de uma mensagem
  Future<void> updateMessageStatus({
    required String messageId,
    required String conversationId,
    required ChatMessageStatus status,
    String? errorMessage,
  }) async {
    await repository.updateMessageStatus(
      messageId,
      conversationId,
      status,
      errorMessage: errorMessage,
    );
  }

  /// Carrega uma conversa por ID
  Future<ChatConversation?> getConversation(String conversationId) async {
    return await repository.getConversation(conversationId);
  }

  /// Carrega todas as conversas de um usuário
  Future<List<ChatConversation>> getUserConversations(String userId) async {
    final conversations = await repository.getUserConversations(userId);
    
    // Ordena por data de atualização (mais recente primeiro)
    conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    return conversations;
  }

  /// Deleta uma conversa
  Future<void> deleteConversation(String conversationId) async {
    await repository.deleteConversation(conversationId);
  }

  /// Busca mensagens por texto
  Future<List<ChatMessage>> searchMessages(String query, String userId) async {
    if (query.trim().isEmpty) {
      return [];
    }
    
    return await repository.searchMessages(query, userId);
  }

  /// Limpa conversas antigas
  Future<void> clearOldConversations(String userId, {int keepDays = 30}) async {
    await repository.clearOldConversations(userId, keepDays: keepDays);
  }

  /// Obtém estatísticas das conversas do usuário
  Future<Map<String, dynamic>> getConversationStats(String userId) async {
    final conversations = await repository.getUserConversations(userId);
    
    int totalConversations = conversations.length;
    int totalMessages = 0;
    int userMessages = 0;
    int assistantMessages = 0;
    DateTime? lastActivity;

    for (final conversation in conversations) {
      totalMessages += conversation.messageCount;
      userMessages += conversation.userMessageCount;
      assistantMessages += conversation.assistantMessageCount;
      
      if (lastActivity == null || conversation.updatedAt.isAfter(lastActivity)) {
        lastActivity = conversation.updatedAt;
      }
    }

    return {
      'total_conversations': totalConversations,
      'total_messages': totalMessages,
      'user_messages': userMessages,
      'assistant_messages': assistantMessages,
      'last_activity': lastActivity,
      'average_messages_per_conversation': 
          totalConversations > 0 ? totalMessages / totalConversations : 0,
    };
  }

  /// Obtém as últimas N mensagens de todas as conversas
  Future<List<ChatMessage>> getRecentMessages(String userId, {int limit = 50}) async {
    final conversations = await repository.getUserConversations(userId);
    
    final allMessages = <ChatMessage>[];
    for (final conversation in conversations) {
      allMessages.addAll(conversation.messages);
    }

    // Ordena por data de criação (mais recente primeiro)
    allMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Retorna apenas o limite solicitado
    return allMessages.take(limit).toList();
  }

  /// Verifica se há conversas ativas (com mensagens pendentes)
  Future<bool> hasActiveConversations(String userId) async {
    final conversations = await repository.getUserConversations(userId);
    
    return conversations.any((conversation) => conversation.hasPendingMessages);
  }

  /// Obtém a conversa mais recente do usuário
  Future<ChatConversation?> getMostRecentConversation(String userId) async {
    final conversations = await repository.getUserConversations(userId);
    
    if (conversations.isEmpty) return null;
    
    conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return conversations.first;
  }
}

