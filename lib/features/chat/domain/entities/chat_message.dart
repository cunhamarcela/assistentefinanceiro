import 'package:equatable/equatable.dart';

/// Entidade que representa uma mensagem no chat IA
class ChatMessage extends Equatable {
  final String id;
  final String content;
  final ChatMessageRole role;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
  final ChatMessageStatus status;
  final String? errorMessage;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
    this.metadata,
    this.status = ChatMessageStatus.sent,
    this.errorMessage,
  });

  /// Factory para criar uma nova mensagem do usuário
  factory ChatMessage.user({
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}_user';
    
    return ChatMessage(
      id: id,
      content: content,
      role: ChatMessageRole.user,
      createdAt: now,
      metadata: metadata,
      status: ChatMessageStatus.sent,
    );
  }

  /// Factory para criar uma nova mensagem do assistente
  factory ChatMessage.assistant({
    required String content,
    Map<String, dynamic>? metadata,
    ChatMessageStatus status = ChatMessageStatus.sent,
    String? errorMessage,
  }) {
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}_assistant';
    
    return ChatMessage(
      id: id,
      content: content,
      role: ChatMessageRole.assistant,
      createdAt: now,
      metadata: metadata,
      status: status,
      errorMessage: errorMessage,
    );
  }

  /// Factory para criar uma mensagem de sistema
  factory ChatMessage.system({
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}_system';
    
    return ChatMessage(
      id: id,
      content: content,
      role: ChatMessageRole.system,
      createdAt: now,
      metadata: metadata,
      status: ChatMessageStatus.sent,
    );
  }

  /// Cria uma cópia da mensagem com novos valores
  ChatMessage copyWith({
    String? id,
    String? content,
    ChatMessageRole? role,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
    ChatMessageStatus? status,
    String? errorMessage,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Verifica se a mensagem é do usuário
  bool get isUser => role == ChatMessageRole.user;

  /// Verifica se a mensagem é do assistente
  bool get isAssistant => role == ChatMessageRole.assistant;

  /// Verifica se a mensagem é do sistema
  bool get isSystem => role == ChatMessageRole.system;

  /// Verifica se a mensagem está sendo enviada
  bool get isSending => status == ChatMessageStatus.sending;

  /// Verifica se a mensagem foi enviada com sucesso
  bool get isSent => status == ChatMessageStatus.sent;

  /// Verifica se houve erro no envio
  bool get hasError => status == ChatMessageStatus.error;

  /// Verifica se a mensagem contém insights financeiros
  bool get hasFinancialInsight {
    return metadata?['type'] == 'financial_insight' ||
           metadata?['has_insight'] == true;
  }

  /// Retorna o tipo de insight se disponível
  String? get insightType => metadata?['insight_type'] as String?;

  /// Retorna dados do insight se disponível
  Map<String, dynamic>? get insightData => 
      metadata?['insight_data'] as Map<String, dynamic>?;

  @override
  List<Object?> get props => [
        id,
        content,
        role,
        createdAt,
        metadata,
        status,
        errorMessage,
      ];

  @override
  String toString() {
    return 'ChatMessage(id: $id, role: $role, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content}, status: $status)';
  }
}

/// Papel da mensagem no chat
enum ChatMessageRole {
  user,
  assistant,
  system,
}

/// Status da mensagem
enum ChatMessageStatus {
  sending,
  sent,
  error,
}

