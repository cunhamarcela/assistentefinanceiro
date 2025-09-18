import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/financial_insight.dart';
import '../../domain/usecases/generate_assistant_reply_usecase.dart';
import '../../domain/usecases/manage_conversation_usecase.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Controller para gerenciar o chat IA
class ChatController extends GetxController {
  final GenerateAssistantReplyUseCase generateReplyUseCase;
  final ManageConversationUseCase manageConversationUseCase;
  final AnalyticsService analyticsService;

  ChatController({
    required this.generateReplyUseCase,
    required this.manageConversationUseCase,
    required this.analyticsService,
  });

  // Estados observáveis
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final Rx<ChatConversation?> currentConversation = Rx<ChatConversation?>(null);
  final RxList<ChatConversation> conversations = <ChatConversation>[].obs;
  final RxList<FinancialInsight> insights = <FinancialInsight>[].obs;
  
  // Estados de UI
  final RxBool isLoading = false.obs;
  final RxBool isSendingMessage = false.obs;
  final RxBool isTyping = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Controllers de texto
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // Configurações
  final RxBool autoScroll = true.obs;
  final RxBool soundEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeChat();
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// Inicializa o chat
  Future<void> _initializeChat() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Carrega conversas do usuário
      await loadUserConversations();

      // Carrega ou cria conversa atual
      await _loadOrCreateCurrentConversation();

      // Registra evento de início de sessão
      await analyticsService.trackChatEvent(
        type: ChatEventType.conversationStarted,
        properties: {
          'conversation_id': currentConversation.value?.id,
          'message_count': messages.length,
        },
      );
    } catch (e) {
      errorMessage.value = 'Erro ao inicializar chat: $e';
      _showError('Erro ao carregar chat', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Carrega conversas do usuário
  Future<void> loadUserConversations() async {
    try {
      // TODO: Obter userId do AuthController
      const userId = 'current_user_id';
      
      final userConversations = await manageConversationUseCase
          .getUserConversations(userId);
      
      conversations.value = userConversations;
    } catch (e) {
      print('Erro ao carregar conversas: $e');
    }
  }

  /// Carrega ou cria conversa atual
  Future<void> _loadOrCreateCurrentConversation() async {
    try {
      // TODO: Obter userId do AuthController
      const userId = 'current_user_id';

      // Tenta carregar a conversa mais recente
      final recentConversation = await manageConversationUseCase
          .getMostRecentConversation(userId);

      if (recentConversation != null) {
        currentConversation.value = recentConversation;
        messages.value = recentConversation.messages;
      } else {
        // Cria nova conversa
        await createNewConversation();
      }
    } catch (e) {
      print('Erro ao carregar conversa atual: $e');
      await createNewConversation();
    }
  }

  /// Cria nova conversa
  Future<void> createNewConversation() async {
    try {
      // TODO: Obter userId do AuthController
      const userId = 'current_user_id';

      final conversation = await manageConversationUseCase.createConversation(
        userId: userId,
        title: 'Nova Conversa',
        metadata: {
          'created_from': 'chat_page',
          'app_version': '1.0.0',
        },
      );

      currentConversation.value = conversation;
      messages.clear();

      // Adiciona mensagem de boas-vindas
      await _addWelcomeMessage();

      // Atualiza lista de conversas
      await loadUserConversations();
    } catch (e) {
      _showError('Erro ao criar conversa', e.toString());
    }
  }

  /// Adiciona mensagem de boas-vindas
  Future<void> _addWelcomeMessage() async {
    final welcomeMessage = ChatMessage.assistant(
      content: 'Olá! 👋 Sou seu assistente financeiro inteligente. '
               'Posso ajudar você a:\n\n'
               '• Analisar seus gastos\n'
               '• Criar relatórios personalizados\n'
               '• Dar dicas de economia\n'
               '• Responder dúvidas sobre finanças\n\n'
               'Como posso ajudar você hoje?',
      metadata: {
        'type': 'welcome_message',
        'has_insight': false,
      },
    );

    messages.add(welcomeMessage);

    if (currentConversation.value != null) {
      await manageConversationUseCase.addMessageToConversation(
        conversationId: currentConversation.value!.id,
        message: welcomeMessage,
      );
    }
  }

  /// Envia mensagem do usuário
  Future<void> sendMessage({String? text}) async {
    final messageText = text ?? messageController.text.trim();
    
    if (messageText.isEmpty || isSendingMessage.value) return;

    try {
      isSendingMessage.value = true;
      errorMessage.value = '';

      // Limpa campo de texto
      messageController.clear();

      // Cria mensagem do usuário
      final userMessage = ChatMessage.user(
        content: messageText,
        metadata: {
          'timestamp': DateTime.now().toIso8601String(),
          'source': 'chat_input',
        },
      );

      // Adiciona mensagem à lista
      messages.add(userMessage);
      _scrollToBottom();

      // Salva mensagem na conversa
      if (currentConversation.value != null) {
        await manageConversationUseCase.addMessageToConversation(
          conversationId: currentConversation.value!.id,
          message: userMessage,
        );
      }

      // Registra evento de envio
      await analyticsService.trackChatEvent(
        type: ChatEventType.promptSent,
        properties: {
          'message_length': messageText.length,
          'conversation_id': currentConversation.value?.id,
        },
      );

      // Mostra indicador de digitação
      isTyping.value = true;

      // Gera resposta do assistente
      await _generateAssistantResponse();

    } catch (e) {
      _showError('Erro ao enviar mensagem', e.toString());
      
      // Registra evento de erro
      await analyticsService.trackChatEvent(
        type: ChatEventType.responseError,
        properties: {
          'error': e.toString(),
          'conversation_id': currentConversation.value?.id,
        },
      );
    } finally {
      isSendingMessage.value = false;
      isTyping.value = false;
    }
  }

  /// Gera resposta do assistente
  Future<void> _generateAssistantResponse() async {
    try {
      // Prepara histórico da conversa
      final conversationHistory = messages.where((m) => !m.isSystem).toList();

      // Gera resposta usando o use case
      final assistantReply = await generateReplyUseCase.call(
        conversationHistory: conversationHistory,
        context: {
          'user_id': 'current_user_id', // TODO: Obter do AuthController
          'conversation_id': currentConversation.value?.id,
          'app_context': 'financial_assistant',
        },
      );

      // Adiciona resposta à lista
      messages.add(assistantReply);
      _scrollToBottom();

      // Salva resposta na conversa
      if (currentConversation.value != null) {
        await manageConversationUseCase.addMessageToConversation(
          conversationId: currentConversation.value!.id,
          message: assistantReply,
        );
      }

      // Registra evento de resposta recebida
      await analyticsService.trackChatEvent(
        type: ChatEventType.responseReceived,
        properties: {
          'response_length': assistantReply.content.length,
          'has_insight': assistantReply.hasFinancialInsight,
          'conversation_id': currentConversation.value?.id,
        },
      );

    } catch (e) {
      // Cria mensagem de erro
      final errorReply = ChatMessage.assistant(
        content: 'Desculpe, ocorreu um erro ao processar sua mensagem. '
                'Tente novamente em alguns instantes.',
        status: ChatMessageStatus.error,
        errorMessage: e.toString(),
      );

      messages.add(errorReply);
      _scrollToBottom();

      _showError('Erro na resposta', e.toString());
    }
  }

  /// Rola para o final da conversa
  void _scrollToBottom() {
    if (!autoScroll.value) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Limpa conversa atual
  Future<void> clearCurrentConversation() async {
    try {
      messages.clear();
      await createNewConversation();
      
      Get.snackbar(
        'Conversa Limpa',
        'Uma nova conversa foi iniciada',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      _showError('Erro ao limpar conversa', e.toString());
    }
  }

  /// Deleta uma conversa
  Future<void> deleteConversation(String conversationId) async {
    try {
      await manageConversationUseCase.deleteConversation(conversationId);
      await loadUserConversations();
      
      // Se deletou a conversa atual, cria uma nova
      if (currentConversation.value?.id == conversationId) {
        await createNewConversation();
      }
      
      Get.snackbar(
        'Conversa Deletada',
        'A conversa foi removida com sucesso',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      _showError('Erro ao deletar conversa', e.toString());
    }
  }

  /// Carrega uma conversa específica
  Future<void> loadConversation(String conversationId) async {
    try {
      isLoading.value = true;
      
      final conversation = await manageConversationUseCase
          .getConversation(conversationId);
      
      if (conversation != null) {
        currentConversation.value = conversation;
        messages.value = conversation.messages;
        _scrollToBottom();
      }
    } catch (e) {
      _showError('Erro ao carregar conversa', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Busca mensagens
  Future<void> searchMessages(String query) async {
    if (query.trim().isEmpty) return;

    try {
      // TODO: Obter userId do AuthController
      const userId = 'current_user_id';
      
      final results = await manageConversationUseCase.searchMessages(query, userId);
      
      // TODO: Implementar exibição dos resultados de busca
      print('Encontradas ${results.length} mensagens para "$query"');
    } catch (e) {
      _showError('Erro na busca', e.toString());
    }
  }

  /// Reenviar mensagem com erro
  Future<void> retryMessage(ChatMessage message) async {
    if (message.hasError && message.isAssistant) {
      // Remove mensagem com erro
      messages.removeWhere((m) => m.id == message.id);
      
      // Gera nova resposta
      await _generateAssistantResponse();
    }
  }

  /// Copia mensagem para clipboard
  void copyMessage(ChatMessage message) {
    // TODO: Implementar cópia para clipboard
    Get.snackbar(
      'Copiado',
      'Mensagem copiada para a área de transferência',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  /// Mostra erro
  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.error,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  /// Obtém estatísticas da conversa
  Map<String, dynamic> get conversationStats {
    return {
      'total_messages': messages.length,
      'user_messages': messages.where((m) => m.isUser).length,
      'assistant_messages': messages.where((m) => m.isAssistant).length,
      'messages_with_insights': messages.where((m) => m.hasFinancialInsight).length,
      'error_messages': messages.where((m) => m.hasError).length,
    };
  }

  /// Verifica se pode enviar mensagem
  bool get canSendMessage => 
      !isSendingMessage.value && 
      !isLoading.value && 
      messageController.text.trim().isNotEmpty;
}
