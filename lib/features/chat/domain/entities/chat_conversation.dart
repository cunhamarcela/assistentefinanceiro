import 'package:equatable/equatable.dart';
import 'chat_message.dart';

/// Entidade que representa uma conversa completa no chat
class ChatConversation extends Equatable {
  final String id;
  final String userId;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? title;
  final Map<String, dynamic>? metadata;

  const ChatConversation({
    required this.id,
    required this.userId,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.metadata,
  });

  /// Factory para criar uma nova conversa
  factory ChatConversation.create({
    required String userId,
    String? title,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}_${userId.hashCode}';
    
    return ChatConversation(
      id: id,
      userId: userId,
      messages: [],
      createdAt: now,
      updatedAt: now,
      title: title,
      metadata: metadata,
    );
  }

  /// Cria uma cópia da conversa com novos valores
  ChatConversation copyWith({
    String? id,
    String? userId,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
    Map<String, dynamic>? metadata,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      title: title ?? this.title,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Adiciona uma mensagem à conversa
  ChatConversation addMessage(ChatMessage message) {
    final updatedMessages = List<ChatMessage>.from(messages)..add(message);
    return copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove uma mensagem da conversa
  ChatConversation removeMessage(String messageId) {
    final updatedMessages = messages.where((m) => m.id != messageId).toList();
    return copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );
  }

  /// Atualiza uma mensagem na conversa
  ChatConversation updateMessage(ChatMessage updatedMessage) {
    final updatedMessages = messages.map((m) {
      return m.id == updatedMessage.id ? updatedMessage : m;
    }).toList();
    
    return copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );
  }

  /// Retorna as últimas N mensagens
  List<ChatMessage> getLastMessages(int count) {
    if (messages.length <= count) return messages;
    return messages.sublist(messages.length - count);
  }

  /// Retorna apenas mensagens do usuário e assistente (sem sistema)
  List<ChatMessage> get conversationMessages {
    return messages.where((m) => !m.isSystem).toList();
  }

  /// Retorna a última mensagem
  ChatMessage? get lastMessage {
    return messages.isNotEmpty ? messages.last : null;
  }

  /// Retorna a última mensagem do usuário
  ChatMessage? get lastUserMessage {
    return messages.where((m) => m.isUser).lastOrNull;
  }

  /// Retorna a última mensagem do assistente
  ChatMessage? get lastAssistantMessage {
    return messages.where((m) => m.isAssistant).lastOrNull;
  }

  /// Verifica se há mensagens sendo enviadas
  bool get hasPendingMessages {
    return messages.any((m) => m.isSending);
  }

  /// Verifica se há mensagens com erro
  bool get hasErrorMessages {
    return messages.any((m) => m.hasError);
  }

  /// Conta total de mensagens
  int get messageCount => messages.length;

  /// Conta mensagens do usuário
  int get userMessageCount => messages.where((m) => m.isUser).length;

  /// Conta mensagens do assistente
  int get assistantMessageCount => messages.where((m) => m.isAssistant).length;

  /// Verifica se a conversa está vazia
  bool get isEmpty => messages.isEmpty;

  /// Verifica se a conversa tem conteúdo
  bool get isNotEmpty => messages.isNotEmpty;

  /// Gera título automático baseado na primeira mensagem do usuário
  String get autoTitle {
    if (title != null && title!.isNotEmpty) return title!;
    
    final firstUserMessage = messages.where((m) => m.isUser).firstOrNull;
    if (firstUserMessage != null) {
      final content = firstUserMessage.content;
      if (content.length <= 30) return content;
      return '${content.substring(0, 30)}...';
    }
    
    return 'Nova Conversa';
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        messages,
        createdAt,
        updatedAt,
        title,
        metadata,
      ];

  @override
  String toString() {
    return 'ChatConversation(id: $id, userId: $userId, messageCount: ${messages.length}, title: $title)';
  }
}

/// Extensão para facilitar o uso de listas
extension ListExtension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
  T? get firstOrNull => isEmpty ? null : first;
}
