import '../entities/chat_message.dart';
import '../entities/chat_conversation.dart';
import '../entities/financial_insight.dart';

/// Repositório abstrato para operações de chat IA
abstract class ChatRepository {
  /// Gera resposta do assistente IA baseada no histórico da conversa
  Future<ChatMessage> generateAssistantReply({
    required List<ChatMessage> conversationHistory,
    Map<String, dynamic>? context,
  });

  /// Analisa uma mensagem do usuário e extrai intenções
  Future<Map<String, dynamic>> analyzeUserMessage(String message);

  /// Gera insights financeiros baseados nos dados do usuário
  Future<List<FinancialInsight>> generateFinancialInsights({
    required String userId,
    int? limitDays,
  });

  /// Salva uma conversa completa
  Future<void> saveConversation(ChatConversation conversation);

  /// Carrega uma conversa por ID
  Future<ChatConversation?> getConversation(String conversationId);

  /// Carrega todas as conversas de um usuário
  Future<List<ChatConversation>> getUserConversations(String userId);

  /// Deleta uma conversa
  Future<void> deleteConversation(String conversationId);

  /// Salva uma mensagem individual
  Future<void> saveMessage(ChatMessage message, String conversationId);

  /// Atualiza o status de uma mensagem
  Future<void> updateMessageStatus(
    String messageId,
    String conversationId,
    ChatMessageStatus status, {
    String? errorMessage,
  });

  /// Busca mensagens por texto
  Future<List<ChatMessage>> searchMessages(String query, String userId);

  /// Limpa histórico de conversas antigas
  Future<void> clearOldConversations(String userId, {int keepDays = 30});

  /// Verifica se o serviço de IA está disponível
  Future<bool> isAiServiceAvailable();

  /// Obtém configurações do chat para o usuário
  Future<Map<String, dynamic>> getChatSettings(String userId);

  /// Atualiza configurações do chat
  Future<void> updateChatSettings(String userId, Map<String, dynamic> settings);
}
