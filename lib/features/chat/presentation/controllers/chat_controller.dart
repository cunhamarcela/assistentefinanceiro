import 'dart:io' show File, FileMode;
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/financial_insight.dart';
import '../../domain/usecases/generate_assistant_reply_usecase.dart';
import '../../domain/usecases/manage_conversation_usecase.dart';
import '../../data/services/expense_parser_service.dart';
import '../../data/services/quick_questions_service.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/entities/category.dart';
import '../../../expenses/domain/entities/credit_card.dart';
import '../../../expenses/presentation/controllers/expense_controller.dart';
import '../../../expenses/presentation/controllers/category_controller.dart';
import '../../../expenses/presentation/controllers/credit_card_controller.dart';
import '../../../monetization/domain/entities/usage_limit.dart';
import '../../../monetization/domain/entities/feature_unlock.dart';
import '../../../monetization/data/services/usage_limit_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/ads_service.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/theme/app_colors.dart';

// #region agent log
void _debugLogChat(String hypothesisId, String location, String message, Map<String, dynamic> data) {
  try {
    final logEntry = '{"hypothesisId":"$hypothesisId","location":"$location","message":"$message","data":${data.toString().replaceAll("'", '"')},"timestamp":${DateTime.now().millisecondsSinceEpoch},"sessionId":"debug-chat"}\n';
    File('/Users/marcelacunha/meus_apps/assistente_financeiro/.cursor/debug.log').writeAsStringSync(logEntry, mode: FileMode.append);
  } catch (e) { /* ignore */ }
}
// #endregion

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

  // Serviço de parsing de despesas
  ExpenseParserService? _expenseParser;
  
  // Serviços de monetização
  UsageLimitService? _usageLimitService;
  AdsService? _adsService;
  
  // Estados de limite de uso
  final Rx<UsageLimit?> currentUsageLimit = Rx<UsageLimit?>(null);
  final Rx<FeatureUnlock?> activeUnlock = Rx<FeatureUnlock?>(null);
  final RxBool isLimitReached = false.obs;
  final RxBool hasUnlimitedAccess = false.obs;
  
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
  
  // Estados para criação de despesa via chat
  final Rx<ParsedExpense?> pendingExpense = Rx<ParsedExpense?>(null);
  final RxBool isAwaitingExpenseConfirmation = false.obs;
  
  // Estado para perguntas rápidas
  final RxBool isProcessingQuickQuestion = false.obs;
  QuickQuestionsService? _quickQuestionsService;
  
  // Controllers de texto
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // Configurações
  final RxBool autoScroll = true.obs;
  final RxBool soundEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    AppLogger.info(FeatureTag.chat, '💬 ChatController inicializando');
    _initializeServices();
    _initializeChat();
  }

  /// Inicializa os serviços necessários
  void _initializeServices() {
    AppLogger.debug(FeatureTag.chat, 'Inicializando serviços do chat');
    
    // Tenta obter o ExpenseParserService se estiver registrado
    try {
      if (Get.isRegistered<ExpenseParserService>()) {
        _expenseParser = Get.find<ExpenseParserService>();
        AppLogger.debug(FeatureTag.chat, 'ExpenseParserService obtido');
      } else {
        _expenseParser = Get.put(ExpenseParserService());
        AppLogger.debug(FeatureTag.chat, 'ExpenseParserService criado');
      }
    } catch (e) {
      AppLogger.warning(FeatureTag.chat, 'ExpenseParserService não disponível', data: {
        'error': e.toString(),
      });
    }
    
    // Inicializa o QuickQuestionsService
    try {
      if (Get.isRegistered<QuickQuestionsService>()) {
        _quickQuestionsService = Get.find<QuickQuestionsService>();
        AppLogger.debug(FeatureTag.chat, 'QuickQuestionsService obtido');
      } else {
        _quickQuestionsService = Get.put(QuickQuestionsService());
        AppLogger.debug(FeatureTag.chat, 'QuickQuestionsService criado');
      }
    } catch (e) {
      AppLogger.warning(FeatureTag.chat, 'QuickQuestionsService não disponível', data: {
        'error': e.toString(),
      });
    }
    
    // Inicializa serviços de monetização
    _initializeMonetizationServices();
  }
  
  /// Inicializa serviços de monetização (limite de uso e ads)
  void _initializeMonetizationServices() {
    // #region agent log
    _debugLogChat('H5', 'chat_controller.dart:_initializeMonetizationServices:entry', 'Iniciando servicos de monetizacao', {'usageLimitRegistered': Get.isRegistered<UsageLimitService>(), 'adsServiceRegistered': Get.isRegistered<AdsService>()});
    // #endregion
    
    AppLogger.debug(FeatureTag.chat, 'Inicializando serviços de monetização');
    
    try {
      if (Get.isRegistered<UsageLimitService>()) {
        _usageLimitService = Get.find<UsageLimitService>();
        // #region agent log
        _debugLogChat('H5', 'chat_controller.dart:_initializeMonetizationServices:usage', 'UsageLimitService obtido', {'isLoading': _usageLimitService?.isLoading.value});
        // #endregion
        AppLogger.debug(FeatureTag.chat, 'UsageLimitService obtido');
      } else {
        // #region agent log
        _debugLogChat('H5', 'chat_controller.dart:_initializeMonetizationServices:usage_not_registered', 'UsageLimitService NAO registrado', {});
        // #endregion
      }
    } catch (e) {
      // #region agent log
      _debugLogChat('H5', 'chat_controller.dart:_initializeMonetizationServices:usage_error', 'Erro ao obter UsageLimitService', {'error': e.toString()});
      // #endregion
      AppLogger.warning(FeatureTag.chat, 'UsageLimitService não disponível', data: {
        'error': e.toString(),
      });
    }
    
    try {
      if (Get.isRegistered<AdsService>()) {
        _adsService = Get.find<AdsService>();
        // #region agent log
        _debugLogChat('H5', 'chat_controller.dart:_initializeMonetizationServices:ads', 'AdsService obtido', {'isInitialized': _adsService?.isInitialized.value, 'isRewardedAdReady': _adsService?.isRewardedAdReady.value, 'lastError': _adsService?.lastError.value});
        // #endregion
        AppLogger.debug(FeatureTag.chat, 'AdsService obtido', data: {
          'isInitialized': _adsService?.isInitialized.value,
          'isRewardedAdReady': _adsService?.isRewardedAdReady.value,
        });
        
        // Pré-carrega anúncio se ainda não estiver pronto
        if (_adsService != null && !_adsService!.isRewardedAdReady.value) {
          AppLogger.debug(FeatureTag.chat, 'Iniciando pré-carregamento de anúncio');
          _adsService!.preloadAds();
        }
      } else {
        // #region agent log
        _debugLogChat('H5', 'chat_controller.dart:_initializeMonetizationServices:ads_not_registered', 'AdsService NAO registrado', {});
        // #endregion
      }
    } catch (e) {
      // #region agent log
      _debugLogChat('H5', 'chat_controller.dart:_initializeMonetizationServices:ads_error', 'Erro ao obter AdsService', {'error': e.toString()});
      // #endregion
      AppLogger.warning(FeatureTag.chat, 'AdsService não disponível', data: {
        'error': e.toString(),
      });
    }
    
    // Carrega estado inicial de uso
    _loadUsageState();
  }
  
  /// Carrega o estado atual de uso do Chat IA
  Future<void> _loadUsageState() async {
    // #region agent log
    _debugLogChat('H5', 'chat_controller.dart:_loadUsageState:entry', 'Carregando estado de uso', {'hasUsageLimitService': _usageLimitService != null});
    // #endregion
    
    if (_usageLimitService == null) {
      // #region agent log
      _debugLogChat('H5', 'chat_controller.dart:_loadUsageState:no_service', 'UsageLimitService null, criando limite local', {});
      // #endregion
      // Se não há serviço, cria limite local para exibição
      _createLocalDefaultLimit();
      return;
    }
    
    try {
      // Verifica se há desbloqueio ativo
      final unlock = _usageLimitService!.getActiveUnlock(FeatureType.aiChat);
      activeUnlock.value = unlock;
      hasUnlimitedAccess.value = unlock != null && unlock.isActive;
      
      // Usa checkUsage() que cria o limite se não existir
      final checkResult = await _usageLimitService!.checkUsage(FeatureType.aiChat);
      
      // Agora obtém o limite (que foi criado se não existia)
      final limit = _usageLimitService!.getLimit(FeatureType.aiChat);
      
      // #region agent log
      _debugLogChat('H5', 'chat_controller.dart:_loadUsageState:result', 'Estado de uso obtido', {'hasUnlock': hasUnlimitedAccess.value, 'canUse': checkResult.canUse, 'remaining': checkResult.remaining, 'dailyLimit': checkResult.dailyLimit, 'limitNotNull': limit != null});
      // #endregion
      
      if (limit != null) {
        currentUsageLimit.value = limit;
        isLimitReached.value = limit.isLimitReached;
      } else {
        // Fallback: cria limite local para exibição
        _createLocalDefaultLimit();
      }
      
      AppLogger.debug(FeatureTag.chat, 'Estado de uso carregado', data: {
        'has_unlock': hasUnlimitedAccess.value,
        'limit_reached': isLimitReached.value,
        'remaining': currentUsageLimit.value?.remainingToday,
        'daily_limit': currentUsageLimit.value?.dailyLimit,
        'can_use': checkResult.canUse,
      });
    } catch (e) {
      // #region agent log
      _debugLogChat('H5', 'chat_controller.dart:_loadUsageState:error', 'Erro ao carregar estado', {'error': e.toString()});
      // #endregion
      AppLogger.warning(FeatureTag.chat, 'Erro ao carregar estado de uso', data: {
        'error': e.toString(),
      });
      // Em caso de erro, cria limite local para exibição
      _createLocalDefaultLimit();
    }
  }
  
  /// Cria um limite local padrão para exibição quando não há dados do servidor
  void _createLocalDefaultLimit() {
    currentUsageLimit.value = UsageLimit.create(
      userId: 'local',
      featureType: FeatureType.aiChat,
    );
    isLimitReached.value = false;
    AppLogger.debug(FeatureTag.chat, 'Limite local padrão criado', data: {
      'daily_limit': currentUsageLimit.value?.dailyLimit,
    });
  }
  
  /// Verifica se pode enviar mensagem (baseado no limite)
  Future<bool> canSendMessageWithLimit() async {
    // Se não há serviço de limite, permite
    if (_usageLimitService == null) return true;
    
    try {
      final result = await _usageLimitService!.checkUsage(FeatureType.aiChat);
      
      // Atualiza estados
      hasUnlimitedAccess.value = result.hasUnlock;
      activeUnlock.value = result.activeUnlock;
      isLimitReached.value = !result.canUse;
      
      if (!result.canUse) {
        AppLogger.info(FeatureTag.chat, 'Limite de Chat IA atingido', data: {
          'daily_limit': result.dailyLimit,
          'message': result.message,
        });
      }
      
      return result.canUse;
    } catch (e) {
      AppLogger.error(FeatureTag.chat, 'Erro ao verificar limite', error: e);
      // Em caso de erro, permite para não bloquear o usuário
      return true;
    }
  }
  
  /// Registra uso de uma mensagem do Chat IA
  Future<void> _recordChatUsage() async {
    // #region agent log
    _debugLogChat('H1', 'chat_controller.dart:_recordChatUsage:entry', '_recordChatUsage chamado', {'usageLimitService_null': _usageLimitService == null, 'currentLimit': currentUsageLimit.value?.usedToday});
    // #endregion
    
    if (_usageLimitService == null) {
      // #region agent log
      _debugLogChat('H1', 'chat_controller.dart:_recordChatUsage:null_service', 'UsageLimitService é null - saindo', {});
      // #endregion
      return;
    }
    
    try {
      // #region agent log
      _debugLogChat('H2', 'chat_controller.dart:_recordChatUsage:before_record', 'Antes de chamar recordUsage', {'limitBefore': currentUsageLimit.value?.usedToday, 'remaining': currentUsageLimit.value?.remainingToday});
      // #endregion
      
      final recorded = await _usageLimitService!.recordUsage(FeatureType.aiChat);
      
      // #region agent log
      _debugLogChat('H2', 'chat_controller.dart:_recordChatUsage:after_record', 'Resultado do recordUsage', {'recorded': recorded});
      // #endregion
      
      if (recorded) {
        // Atualiza limite local
        await _loadUsageState();
        // #region agent log
        _debugLogChat('H4', 'chat_controller.dart:_recordChatUsage:after_load', 'Após _loadUsageState', {'limitAfter': currentUsageLimit.value?.usedToday, 'remaining': currentUsageLimit.value?.remainingToday});
        // #endregion
        AppLogger.debug(FeatureTag.chat, 'Uso do Chat IA registrado');
      } else {
        // #region agent log
        _debugLogChat('H2', 'chat_controller.dart:_recordChatUsage:not_recorded', 'recordUsage retornou false', {});
        // #endregion
      }
    } catch (e) {
      // #region agent log
      _debugLogChat('H2', 'chat_controller.dart:_recordChatUsage:error', 'Erro ao registrar uso', {'error': e.toString()});
      // #endregion
      AppLogger.warning(FeatureTag.chat, 'Erro ao registrar uso', data: {
        'error': e.toString(),
      });
    }
  }
  
  /// Mostra anúncio para desbloquear Chat IA por 24h
  Future<bool> showAdToUnlockChat() async {
    if (_adsService == null) {
      AppLogger.warning(FeatureTag.chat, 'AdsService não disponível para desbloqueio');
      return false;
    }
    
    AppLogger.info(FeatureTag.chat, 'Iniciando desbloqueio via anúncio');
    
    final result = await _adsService!.showRewardedAdForFeature(
      featureType: FeatureType.aiChat,
      durationHours: 24,
    );
    
    if (result.success) {
      // Atualiza estado de uso
      await _loadUsageState();
      
      AppLogger.info(FeatureTag.chat, 'Chat IA desbloqueado por 24h via anúncio');
      
      Get.snackbar(
        '🎉 Chat Desbloqueado!',
        'Você tem 24 horas de uso ilimitado do Chat IA',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.colorSuccess,
        colorText: AppColors.colorTextOnDark,
        duration: const Duration(seconds: 4),
      );
      
      return true;
    } else {
      AppLogger.warning(FeatureTag.chat, 'Falha ao desbloquear Chat IA', data: {
        'error': result.error,
      });
      
      Get.snackbar(
        'Não foi possível desbloquear',
        result.error ?? 'Tente novamente em alguns segundos',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorWarning,
        colorText: AppColors.colorTextPrimary,
      );
      
      return false;
    }
  }
  
  /// Informações de uso para exibição na UI
  String get usageDisplayText {
    if (hasUnlimitedAccess.value && activeUnlock.value != null) {
      return '✨ Ilimitado (${activeUnlock.value!.timeRemainingFormatted})';
    }
    
    final limit = currentUsageLimit.value;
    if (limit == null) return '';
    
    return '${limit.remainingToday}/${limit.dailyLimit}';
  }
  
  /// Indica se deve mostrar aviso de limite próximo
  bool get shouldShowLimitWarning {
    if (hasUnlimitedAccess.value) return false;
    final limit = currentUsageLimit.value;
    return limit != null && (limit.isLastUse || limit.isNearLimit);
  }
  
  // Callback para quando limite é atingido (UI deve escutar)
  final RxBool showLimitDialog = false.obs;
  
  /// Notifica que o limite foi atingido
  void _notifyLimitReached() {
    isLimitReached.value = true;
    showLimitDialog.value = true;
    
    // Adiciona mensagem informativa no chat
    final limitMessage = ChatMessage.assistant(
      content: '⚠️ **Você atingiu o limite diário de mensagens gratuitas.**\n\n'
               '📊 Limite: ${currentUsageLimit.value?.dailyLimit ?? 5} mensagens por dia\n\n'
               '🎬 **Assista um anúncio** para desbloquear **24 horas de uso ilimitado** do Chat IA!\n\n'
               'Ou aguarde até amanhã para novas mensagens gratuitas.',
      metadata: {
        'type': 'limit_reached',
        'feature': FeatureType.aiChat.name,
      },
    );
    
    messages.add(limitMessage);
    _scrollToBottom();
  }
  
  /// Reseta o flag do dialog de limite
  void dismissLimitDialog() {
    showLimitDialog.value = false;
  }

  @override
  void onClose() {
    AppLogger.debug(FeatureTag.chat, 'ChatController disposing');
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// Inicializa o chat
  Future<void> _initializeChat() async {
    final opId = AppLogger.startOp(FeatureTag.chat, 'initialize_chat');
    
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
      
      AppLogger.completeOp(opId, message: 'Chat inicializado', data: {
        'conversations_count': conversations.length,
        'messages_count': messages.length,
      });
    } catch (e) {
      errorMessage.value = 'Erro ao inicializar chat: $e';
      AppLogger.failOp(opId, 'Erro ao inicializar chat', exception: e);
      _showError('Erro ao carregar chat', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Carrega conversas do usuário
  Future<void> loadUserConversations() async {
    AppLogger.debug(FeatureTag.chat, 'Carregando conversas do usuário');
    
    try {
      // TODO: Obter userId do AuthController
      const userId = 'current_user_id';
      
      final userConversations = await manageConversationUseCase
          .getUserConversations(userId);
      
      conversations.value = userConversations;
      AppLogger.loaded(FeatureTag.chat, 'conversas', userConversations.length);
    } catch (e) {
      AppLogger.error(FeatureTag.chat, 'Erro ao carregar conversas', error: e);
    }
  }

  /// Carrega ou cria conversa atual
  Future<void> _loadOrCreateCurrentConversation() async {
    AppLogger.debug(FeatureTag.chat, 'Carregando ou criando conversa atual');
    
    try {
      // TODO: Obter userId do AuthController
      const userId = 'current_user_id';

      // Tenta carregar a conversa mais recente
      final recentConversation = await manageConversationUseCase
          .getMostRecentConversation(userId);

      if (recentConversation != null) {
        currentConversation.value = recentConversation;
        messages.value = recentConversation.messages;
        AppLogger.info(FeatureTag.chat, 'Conversa recente carregada', data: {
          'conversation_id': recentConversation.id,
          'messages_count': recentConversation.messages.length,
        });
      } else {
        AppLogger.debug(FeatureTag.chat, 'Nenhuma conversa encontrada, criando nova');
        // Cria nova conversa
        await createNewConversation();
      }
    } catch (e) {
      AppLogger.error(FeatureTag.chat, 'Erro ao carregar conversa', error: e);
      await createNewConversation();
    }
  }

  /// Cria nova conversa
  Future<void> createNewConversation() async {
    final opId = AppLogger.startOp(FeatureTag.chat, 'create_conversation');
    
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
      
      AppLogger.completeOp(opId, message: 'Nova conversa criada', data: {
        'conversation_id': conversation.id,
      });
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao criar conversa', exception: e);
      _showError('Erro ao criar conversa', e.toString());
    }
  }

  /// Adiciona mensagem de boas-vindas
  Future<void> _addWelcomeMessage() async {
    AppLogger.debug(FeatureTag.chat, 'Adicionando mensagem de boas-vindas');
    
    final welcomeMessage = ChatMessage.assistant(
      content: 'Olá! 👋 Sou seu assistente financeiro inteligente. '
               'Posso ajudar você a:\n\n'
               '• **Registrar gastos** - Basta me dizer de forma natural!\n'
               '• Analisar seus gastos\n'
               '• Criar relatórios personalizados\n'
               '• Dar dicas de economia\n\n'
               '💡 **Exemplos de registro:**\n'
               '• "Gastei 50 reais no mercado"\n'
               '• "Comprei uma TV de 2000 reais em 10x no Nubank"\n'
               '• "Paguei 150 no restaurante à vista"\n'
               '• "Parcelei 500 reais de roupa em 5x no cartão Inter"\n\n'
               '🔄 Eu entendo **parcelamento**, **cartão** e **forma de pagamento**!\n\n'
               'Como posso ajudar você hoje?',
      metadata: {
        'type': 'welcome_message',
        'has_insight': false,
      },
    );

    messages.add(welcomeMessage);
    AppLogger.chatMessage('assistant', welcomeMessage.content.length);

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
    
    if (messageText.isEmpty || isSendingMessage.value) {
      AppLogger.debug(FeatureTag.chat, 'Mensagem ignorada (vazia ou já enviando)');
      return;
    }
    
    // Verifica limite de uso (exceto para confirmações de despesa)
    if (!isAwaitingExpenseConfirmation.value) {
      final canSend = await canSendMessageWithLimit();
      if (!canSend) {
        AppLogger.info(FeatureTag.chat, 'Mensagem bloqueada por limite');
        // Notifica a UI para mostrar o dialog de limite
        _notifyLimitReached();
        return;
      }
    }

    final opId = AppLogger.startOp(FeatureTag.chat, 'send_message', data: {
      'text_length': messageText.length,
      'awaiting_confirmation': isAwaitingExpenseConfirmation.value,
    });

    try {
      isSendingMessage.value = true;
      errorMessage.value = '';

      // Limpa campo de texto
      messageController.clear();

      // Verifica se está aguardando confirmação de despesa
      if (isAwaitingExpenseConfirmation.value) {
        AppLogger.debug(FeatureTag.chat, 'Processando resposta de confirmação de despesa');
        await _handleExpenseConfirmation(messageText);
        AppLogger.completeOp(opId, message: 'Confirmação de despesa processada');
        return;
      }

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
      AppLogger.chatMessage('user', messageText.length);
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

      // Verifica se parece ser uma solicitação de registro de despesa
      if (_expenseParser != null && _expenseParser!.looksLikeExpenseRequest(messageText)) {
        AppLogger.info(FeatureTag.chat, 'Detectada solicitação de despesa');
        await _handleExpenseRequest(messageText);
      } else {
        // Gera resposta do assistente normal
        await _generateAssistantResponse();
      }
      
      // Registra uso da mensagem (apenas se não é confirmação de despesa)
      if (!isAwaitingExpenseConfirmation.value) {
        await _recordChatUsage();
      }
      
      AppLogger.completeOp(opId, message: 'Mensagem processada');

    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao enviar mensagem', exception: e);
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

  /// Trata solicitação de registro de despesa
  Future<void> _handleExpenseRequest(String text) async {
    AppLogger.debug(FeatureTag.chat, 'Processando solicitação de despesa', data: {'text': text});
    
    try {
      // Obtém categorias disponíveis
      final categories = _getAvailableCategories();
      
      if (categories.isEmpty) {
        AppLogger.warning(FeatureTag.chat, 'Nenhuma categoria disponível para parsing');
        // Se não há categorias, responde normalmente
        await _generateAssistantResponse();
        return;
      }
      
      // Obtém cartões de crédito disponíveis e passa para o parser
      final creditCards = _getAvailableCreditCards();
      _expenseParser!.updateCreditCards(creditCards);

      // Tenta parsear a despesa
      final parsed = await _expenseParser!.parseExpenseFromText(
        text,
        availableCategories: categories,
      );

      if (parsed != null && parsed.hasMinimumData) {
        // Armazena a despesa pendente
        pendingExpense.value = parsed;
        isAwaitingExpenseConfirmation.value = true;
        
        AppLogger.info(FeatureTag.chat, 'Despesa parseada com sucesso', data: {
          'amount': parsed.amount,
          'description': parsed.description,
          'category': parsed.categoryName,
          'confidence': parsed.confidence,
          'isInstallment': parsed.isInstallment,
          'installments': parsed.installments,
          'needsInstallmentNumber': parsed.needsInstallmentNumber,
        });

        // Define instruções baseado no estado da despesa
        String instructions;
        if (parsed.needsInstallmentNumber) {
          // Precisa do número de parcelas primeiro
          instructions = '❓ **Informe o número de parcelas** (ex: "10x" ou "em 5 vezes")\n'
                         '❌ Digite **"cancelar"** para descartar';
        } else {
          // Pode confirmar diretamente
          instructions = '✅ Digite **"sim"** ou **"confirmar"** para registrar\n'
                         '❌ Digite **"não"** ou **"cancelar"** para descartar\n'
                         '✏️ Ou me diga o que precisa corrigir';
        }

        // Cria mensagem de confirmação
        final confirmationMessage = ChatMessage.assistant(
          content: '${parsed.confirmationMessage}\n\n$instructions',
          metadata: {
            'type': 'expense_confirmation',
            'parsed_expense': parsed.rawParsedData,
            'requires_action': true,
            'needsInstallmentNumber': parsed.needsInstallmentNumber,
          },
        );

        messages.add(confirmationMessage);
        AppLogger.chatMessage('assistant', confirmationMessage.content.length, hasInsight: false);
        _scrollToBottom();

        if (currentConversation.value != null) {
          await manageConversationUseCase.addMessageToConversation(
            conversationId: currentConversation.value!.id,
            message: confirmationMessage,
          );
        }
      } else {
        AppLogger.debug(FeatureTag.chat, 'Não foi possível parsear despesa completamente');
        
        // Verifica se temos dados parciais para mostrar feedback específico
        final parseResult = await _expenseParser!.parseMessage(text);
        
        if (parseResult.isExpenseRequest && parseResult.errorMessage != null) {
          // Tem erro específico (ex: valor não identificado)
          _addHelpMessage(parseResult.errorMessage!);
        } else if (parseResult.isExpenseRequest) {
          // Reconheceu como despesa mas faltam dados
          _addHelpMessage(
            '🤔 **Entendi que você quer registrar uma despesa, mas preciso de mais informações:**\n\n'
            '${parseResult.getValidationMessage()}\n'
            '📝 **Exemplo completo:**\n'
            '"Gastei **50 reais** no **mercado**"\n'
            '"Comprei **roupa** por **R\$ 150** em **10x** no **Nubank**"'
          );
        } else {
          // Não é uma despesa, responde normalmente
          await _generateAssistantResponse();
        }
      }
    } catch (e) {
      AppLogger.error(FeatureTag.chat, 'Erro ao processar despesa', error: e);
      _addHelpMessage(
        '❌ **Ops! Ocorreu um erro ao processar sua mensagem.**\n\n'
        'Por favor, tente novamente com uma frase simples como:\n'
        '• "Gastei 50 reais no mercado"\n'
        '• "Comprei roupa por 150 reais"'
      );
    }
  }

  /// Trata confirmação/cancelamento de despesa
  Future<void> _handleExpenseConfirmation(String response) async {
    final lowerResponse = response.toLowerCase().trim();
    
    AppLogger.debug(FeatureTag.chat, 'Processando resposta de confirmação', data: {'response': response});
    
    // Cria mensagem do usuário
    final userMessage = ChatMessage.user(
      content: response,
      metadata: {
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'expense_confirmation',
      },
    );
    messages.add(userMessage);
    _scrollToBottom();

    // Se está aguardando número de parcelas, tenta extrair primeiro
    if (pendingExpense.value?.needsInstallmentNumber == true) {
      final installments = _extractInstallmentFromResponse(response);
      if (installments != null && installments > 1) {
        AppLogger.info(FeatureTag.chat, 'Número de parcelas informado', data: {'installments': installments});
        await _updateInstallmentNumber(installments);
        return;
      } else if (_isCancellation(lowerResponse)) {
        AppLogger.info(FeatureTag.chat, 'Usuário cancelou a despesa');
        await _cancelPendingExpense();
        return;
      } else {
        // Não entendeu o número de parcelas
        _addInfoMessage('Por favor, informe o número de parcelas (ex: "10x", "em 5 vezes" ou "12 parcelas")');
        return;
      }
    }

    // Verifica se é confirmação
    if (_isConfirmation(lowerResponse)) {
      AppLogger.info(FeatureTag.chat, 'Usuário confirmou a despesa');
      await _createExpenseFromParsed();
    } 
    // Verifica se é cancelamento
    else if (_isCancellation(lowerResponse)) {
      AppLogger.info(FeatureTag.chat, 'Usuário cancelou a despesa');
      await _cancelPendingExpense();
    } 
    // Verifica se é correção
    else {
      AppLogger.debug(FeatureTag.chat, 'Usuário solicitou correção');
      // Tenta re-parsear com a nova informação
      await _handleExpenseCorrection(response);
    }
  }
  
  /// Extrai número de parcelas de uma resposta
  int? _extractInstallmentFromResponse(String response) {
    final lowerResponse = response.toLowerCase();
    
    // Padrões para número de parcelas
    final patterns = [
      RegExp(r'(\d+)\s*x', caseSensitive: false),
      RegExp(r'(\d+)\s*(?:vezes|parcelas?)', caseSensitive: false),
      RegExp(r'em\s+(\d+)', caseSensitive: false),
      RegExp(r'^(\d+)$'), // Apenas número
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(lowerResponse);
      if (match != null && match.group(1) != null) {
        final number = int.tryParse(match.group(1)!);
        if (number != null && number >= 2 && number <= 48) {
          return number;
        }
      }
    }
    
    return null;
  }
  
  /// Atualiza o número de parcelas na despesa pendente
  Future<void> _updateInstallmentNumber(int installments) async {
    final current = pendingExpense.value;
    if (current == null) return;
    
    // Cria nova ParsedExpense com as parcelas
    final updated = ParsedExpense(
      amount: current.amount,
      description: current.description,
      categoryId: current.categoryId,
      categoryName: current.categoryName,
      date: current.date,
      paymentType: PaymentType.credit,
      confidence: current.confidence + 0.1,
      originalText: current.originalText,
      rawParsedData: current.rawParsedData,
      isInstallment: true,
      installments: installments,
      creditCardId: current.creditCardId,
      creditCardName: current.creditCardName,
    );
    
    pendingExpense.value = updated;
    
    // Mostra confirmação atualizada
    final confirmationMessage = ChatMessage.assistant(
      content: '${updated.confirmationMessage}\n\n'
               '✅ Digite **"sim"** ou **"confirmar"** para registrar\n'
               '❌ Digite **"não"** ou **"cancelar"** para descartar\n'
               '✏️ Ou me diga o que precisa corrigir',
      metadata: {
        'type': 'expense_confirmation_updated',
        'installments': installments,
      },
    );
    
    messages.add(confirmationMessage);
    _scrollToBottom();
  }
  
  /// Adiciona mensagem informativa
  void _addInfoMessage(String message) {
    final infoMsg = ChatMessage.assistant(
      content: '💡 $message',
      metadata: {'type': 'info'},
    );
    messages.add(infoMsg);
    _scrollToBottom();
  }
  
  /// Adiciona mensagem de ajuda formatada
  void _addHelpMessage(String message) {
    final helpMsg = ChatMessage.assistant(
      content: message,
      metadata: {'type': 'help'},
    );
    messages.add(helpMsg);
    _scrollToBottom();
  }

  /// Verifica se a resposta é uma confirmação
  bool _isConfirmation(String response) {
    final confirmations = ['sim', 's', 'yes', 'y', 'confirmar', 'confirma', 'ok', 'salvar', 'registrar'];
    return confirmations.any((c) => response == c || response.startsWith('$c '));
  }

  /// Verifica se a resposta é um cancelamento
  bool _isCancellation(String response) {
    final cancellations = ['não', 'nao', 'n', 'no', 'cancelar', 'cancela', 'descartar', 'ignorar'];
    return cancellations.any((c) => response == c || response.startsWith('$c '));
  }

  /// Cria despesa a partir dos dados parseados
  Future<void> _createExpenseFromParsed() async {
    final opId = AppLogger.startOp(FeatureTag.chat, 'create_expense_from_parsed');
    
    try {
      final parsed = pendingExpense.value;
      if (parsed == null || !parsed.hasMinimumData) {
        AppLogger.warning(FeatureTag.chat, 'Dados insuficientes para criar despesa');
        _resetExpenseState();
        return;
      }

      // Obtém o ExpenseController
      final expenseController = _getExpenseController();
      if (expenseController == null) {
        AppLogger.error(FeatureTag.chat, 'ExpenseController não disponível');
        _addHelpMessage(
          '⚠️ **Módulo de despesas não disponível**\n\n'
          'Por favor, volte para a tela inicial e tente novamente.\n'
          'Se o problema persistir, reinicie o app.'
        );
        _resetExpenseState();
        return;
      }

      AppLogger.info(FeatureTag.chat, 'Criando despesa via chat', data: {
        'amount': parsed.amount,
        'description': parsed.description,
        'category': parsed.categoryId,
        'isInstallment': parsed.isInstallment,
        'installments': parsed.installments,
        'creditCard': parsed.creditCardName,
      });

      // Define o tipo de pagamento
      var paymentType = parsed.paymentType ?? PaymentType.cash;
      
      // Se é parcelado ou tem cartão, força tipo como crédito
      if (parsed.isInstallment || parsed.creditCardId != null) {
        paymentType = PaymentType.credit;
      }
      
      // Obtém o ID do cartão de crédito (se disponível)
      String? creditCardId = parsed.creditCardId;
      if (creditCardId == null && parsed.creditCardName != null) {
        // Tenta encontrar o cartão pelo nome
        final cards = _getAvailableCreditCards();
        final matchedCard = cards.firstWhereOrNull(
          (c) => c.name.toLowerCase().contains(parsed.creditCardName!.toLowerCase()) ||
                 parsed.creditCardName!.toLowerCase().contains(c.name.toLowerCase())
        );
        creditCardId = matchedCard?.id;
      }

      // Salva a despesa usando os parâmetros nomeados do controller
      await expenseController.addExpense(
        amount: parsed.amount!,
        description: parsed.description!,
        categoryId: parsed.categoryId ?? _getDefaultCategoryId(),
        date: parsed.date,
        paymentType: paymentType,
        creditCardId: creditCardId,
        installments: parsed.isInstallment ? parsed.installments : null,
      );
      
      // Monta mensagem de sucesso com informações de parcelamento
      final successBuffer = StringBuffer();
      successBuffer.writeln('✅ **Despesa registrada com sucesso!**\n');
      successBuffer.writeln('💰 Valor: R\$ ${parsed.amount!.toStringAsFixed(2)}');
      successBuffer.writeln('📌 ${parsed.description}');
      if (parsed.categoryName != null) {
        successBuffer.writeln('🏷️ Categoria: ${parsed.categoryName}');
      }
      if (parsed.isInstallment && parsed.installments != null) {
        successBuffer.writeln('🔄 Parcelado em ${parsed.installments}x de R\$ ${(parsed.amount! / parsed.installments!).toStringAsFixed(2)}');
      }
      if (parsed.creditCardName != null) {
        successBuffer.writeln('💳 Cartão: ${parsed.creditCardName}');
      }
      successBuffer.writeln('\nPosso ajudar com mais alguma coisa?');

      // Mensagem de sucesso
      final successMessage = ChatMessage.assistant(
        content: successBuffer.toString(),
        metadata: {
          'type': 'expense_created',
          'amount': parsed.amount,
          'isInstallment': parsed.isInstallment,
          'installments': parsed.installments,
        },
      );

      messages.add(successMessage);
      _scrollToBottom();

      if (currentConversation.value != null) {
        await manageConversationUseCase.addMessageToConversation(
          conversationId: currentConversation.value!.id,
          message: successMessage,
        );
      }

      // Registra evento
      await analyticsService.trackChatEvent(
        type: ChatEventType.insightClicked,
        properties: {
          'action': 'expense_created_via_chat',
          'amount': parsed.amount,
          'confidence': parsed.confidence,
        },
      );

      AppLogger.completeOp(opId, message: 'Despesa criada via chat', data: {
        'amount': parsed.amount,
      });
      
      _resetExpenseState();
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao criar despesa via chat', exception: e);
      
      final errorStr = e.toString().toLowerCase();
      String errorMessage;
      
      if (errorStr.contains('database') || errorStr.contains('sqlite')) {
        errorMessage = '💾 **Erro ao salvar no banco de dados**\n\n'
            'Tente novamente. Se o problema persistir, reinicie o app.';
      } else if (errorStr.contains('network') || errorStr.contains('connection')) {
        errorMessage = '📡 **Sem conexão**\n\n'
            'A despesa será salva quando você reconectar à internet.';
      } else {
        errorMessage = '❌ **Não foi possível registrar a despesa**\n\n'
            'Por favor, tente novamente ou adicione manualmente pelo botão "+" na tela inicial.';
      }
      
      _addHelpMessage(errorMessage);
      _resetExpenseState();
    }
  }

  /// Cancela a despesa pendente
  Future<void> _cancelPendingExpense() async {
    AppLogger.action('cancel_pending_expense', feature: FeatureTag.chat);
    
    final cancelMessage = ChatMessage.assistant(
      content: '❌ **Despesa cancelada.**\n\nTudo bem! A despesa não foi registrada. '
               'Posso ajudar com mais alguma coisa?',
      metadata: {
        'type': 'expense_cancelled',
      },
    );

    messages.add(cancelMessage);
    _scrollToBottom();

    if (currentConversation.value != null) {
      await manageConversationUseCase.addMessageToConversation(
        conversationId: currentConversation.value!.id,
        message: cancelMessage,
      );
    }

    _resetExpenseState();
  }

  /// Trata correção de despesa
  Future<void> _handleExpenseCorrection(String correction) async {
    AppLogger.debug(FeatureTag.chat, 'Processando correção de despesa', data: {'correction': correction});
    
    try {
      // Combina a informação original com a correção
      final original = pendingExpense.value?.originalText ?? '';
      final combined = '$original $correction';
      
      final categories = _getAvailableCategories();
      
      // Atualiza cartões de crédito no parser
      final creditCards = _getAvailableCreditCards();
      _expenseParser!.updateCreditCards(creditCards);
      
      // Re-parseia com a informação adicional
      final parsed = await _expenseParser!.parseExpenseFromText(
        combined,
        availableCategories: categories,
      );

      if (parsed != null && parsed.hasMinimumData) {
        pendingExpense.value = parsed;
        
        AppLogger.info(FeatureTag.chat, 'Despesa re-parseada com correção', data: {
          'amount': parsed.amount,
          'description': parsed.description,
        });

        final confirmationMessage = ChatMessage.assistant(
          content: '📝 **Dados atualizados:**\n\n${parsed.confirmationMessage}\n\n'
                   '✅ Digite **"sim"** para confirmar\n'
                   '❌ Digite **"não"** para cancelar',
          metadata: {
            'type': 'expense_correction',
            'parsed_expense': parsed.rawParsedData,
          },
        );

        messages.add(confirmationMessage);
        _scrollToBottom();
      } else {
        AppLogger.warning(FeatureTag.chat, 'Não foi possível entender a correção');
        _addHelpMessage(
          '🤔 **Não entendi a correção**\n\n'
          'Tente ser mais específico. Exemplos:\n'
          '• "O valor é **80 reais**" (para corrigir valor)\n'
          '• "A categoria é **Alimentação**" (para corrigir categoria)\n'
          '• "Foi em **5x**" (para adicionar parcelamento)\n'
          '• "No cartão **Nubank**" (para adicionar cartão)\n\n'
          'Ou digite **"cancelar"** para descartar.'
        );
      }
    } catch (e) {
      AppLogger.error(FeatureTag.chat, 'Erro ao processar correção', error: e);
      _addHelpMessage(
        '❌ **Erro ao processar correção**\n\n'
        'Por favor, tente novamente ou digite **"cancelar"** para começar de novo.'
      );
      _resetExpenseState();
    }
  }

  /// Reseta o estado de despesa pendente
  void _resetExpenseState() {
    pendingExpense.value = null;
    isAwaitingExpenseConfirmation.value = false;
    AppLogger.state(FeatureTag.chat, 'expense_state_reset');
  }

  /// Adiciona mensagem de erro
  void _addErrorMessage(String message) {
    final errorMsg = ChatMessage.assistant(
      content: '⚠️ $message',
      metadata: {'type': 'error'},
    );
    messages.add(errorMsg);
    _scrollToBottom();
  }

  /// Obtém categorias disponíveis
  List<ExpenseCategory> _getAvailableCategories() {
    try {
      if (Get.isRegistered<CategoryController>()) {
        final categoryController = Get.find<CategoryController>();
        return categoryController.categories;
      }
    } catch (e) {
      AppLogger.warning(FeatureTag.chat, 'Não foi possível obter categorias', data: {'error': e.toString()});
    }
    return ExpenseCategory.defaultCategories;
  }

  /// Obtém o ExpenseController
  ExpenseController? _getExpenseController() {
    try {
      if (Get.isRegistered<ExpenseController>()) {
        return Get.find<ExpenseController>();
      }
    } catch (e) {
      AppLogger.warning(FeatureTag.chat, 'ExpenseController não disponível', data: {'error': e.toString()});
    }
    return null;
  }
  
  /// Obtém cartões de crédito disponíveis
  List<CreditCard> _getAvailableCreditCards() {
    try {
      if (Get.isRegistered<CreditCardController>()) {
        final creditCardController = Get.find<CreditCardController>();
        return creditCardController.creditCards;
      }
    } catch (e) {
      AppLogger.warning(FeatureTag.chat, 'Não foi possível obter cartões de crédito', data: {'error': e.toString()});
    }
    return [];
  }

  /// Obtém ID da categoria padrão
  String _getDefaultCategoryId() {
    final categories = _getAvailableCategories();
    if (categories.isNotEmpty) {
      // Tenta encontrar "Outros" ou usa a primeira
      final outros = categories.firstWhereOrNull((c) => c.name.toLowerCase() == 'outros');
      return outros?.id ?? categories.first.id;
    }
    return 'outros';
  }

  /// Gera resposta do assistente
  Future<void> _generateAssistantResponse() async {
    final opId = AppLogger.startOp(FeatureTag.chat, 'generate_response');
    final startTime = DateTime.now();
    
    try {
      // Prepara histórico da conversa
      final conversationHistory = messages.where((m) => !m.isSystem).toList();
      
      AppLogger.debug(FeatureTag.chat, 'Gerando resposta IA', data: {
        'history_length': conversationHistory.length,
      });

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

      final duration = DateTime.now().difference(startTime);
      AppLogger.chatResponse(duration: duration.inMilliseconds);
      AppLogger.chatMessage('assistant', assistantReply.content.length, hasInsight: assistantReply.hasFinancialInsight);

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
          'response_time_ms': duration.inMilliseconds,
        },
      );
      
      AppLogger.completeOp(opId, message: 'Resposta gerada', data: {
        'response_length': assistantReply.content.length,
        'duration_ms': duration.inMilliseconds,
      });

    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      AppLogger.chatResponse(hasError: true);
      AppLogger.failOp(opId, 'Erro ao gerar resposta', exception: e);
      
      // Identifica o tipo de erro e cria mensagem específica
      final errorContent = _getErrorMessageForException(e);
      
      // Cria mensagem de erro
      final errorReply = ChatMessage.assistant(
        content: errorContent,
        status: ChatMessageStatus.error,
        errorMessage: e.toString(),
      );

      messages.add(errorReply);
      _scrollToBottom();
    }
  }
  
  /// Gera mensagem de erro amigável baseada no tipo de exceção
  String _getErrorMessageForException(dynamic e) {
    final errorStr = e.toString().toLowerCase();
    
    // Erro de cota da API (429)
    if (errorStr.contains('429') || errorStr.contains('quota') || errorStr.contains('insufficient_quota')) {
      return '⚠️ **Serviço de IA temporariamente indisponível**\n\n'
             'Mas não se preocupe! Você ainda pode:\n\n'
             '📝 **Registrar gastos** de forma simples:\n'
             '• "Gastei 50 reais no mercado"\n'
             '• "Comprei roupa por 150 em 10x"\n\n'
             '📊 **Acessar suas funções** pelo menu do app:\n'
             '• Ver relatórios de gastos\n'
             '• Gerenciar categorias\n'
             '• Adicionar despesas manualmente';
    }
    
    // Erro de rede/conexão
    if (errorStr.contains('socket') || errorStr.contains('network') || 
        errorStr.contains('connection') || errorStr.contains('timeout')) {
      return '📡 **Sem conexão com a internet**\n\n'
             'Verifique sua conexão e tente novamente.\n\n'
             'Enquanto isso, você pode:\n'
             '• Registrar gastos simples (funciona offline!)\n'
             '• Navegar pelo app normalmente';
    }
    
    // Erro de autenticação
    if (errorStr.contains('401') || errorStr.contains('unauthorized') || errorStr.contains('authentication')) {
      return '🔐 **Erro de autenticação**\n\n'
             'Por favor, tente sair e entrar novamente no app.';
    }
    
    // Erro genérico
    return '😅 **Ops! Algo deu errado.**\n\n'
           'Mas você ainda pode registrar gastos!\n'
           'Tente algo como:\n'
           '• "Gastei 50 reais no mercado"\n'
           '• "Comprei roupa por 150 reais"\n\n'
           'Se o problema persistir, tente reiniciar o app.';
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
    AppLogger.action('clear_conversation', feature: FeatureTag.chat);
    
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
      AppLogger.error(FeatureTag.chat, 'Erro ao limpar conversa', error: e);
      _showError('Erro ao limpar conversa', e.toString());
    }
  }

  /// Deleta uma conversa
  Future<void> deleteConversation(String conversationId) async {
    final opId = AppLogger.startOp(FeatureTag.chat, 'delete_conversation', data: {'id': conversationId});
    
    try {
      await manageConversationUseCase.deleteConversation(conversationId);
      await loadUserConversations();
      
      // Se deletou a conversa atual, cria uma nova
      if (currentConversation.value?.id == conversationId) {
        await createNewConversation();
      }
      
      AppLogger.completeOp(opId, message: 'Conversa deletada');
      
      Get.snackbar(
        'Conversa Deletada',
        'A conversa foi removida com sucesso',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao deletar conversa', exception: e);
      _showError('Erro ao deletar conversa', e.toString());
    }
  }

  /// Carrega uma conversa específica
  Future<void> loadConversation(String conversationId) async {
    final opId = AppLogger.startOp(FeatureTag.chat, 'load_conversation', data: {'id': conversationId});
    
    try {
      isLoading.value = true;
      
      final conversation = await manageConversationUseCase
          .getConversation(conversationId);
      
      if (conversation != null) {
        currentConversation.value = conversation;
        messages.value = conversation.messages;
        _scrollToBottom();
        
        AppLogger.completeOp(opId, message: 'Conversa carregada', data: {
          'messages_count': conversation.messages.length,
        });
      } else {
        AppLogger.warning(FeatureTag.chat, 'Conversa não encontrada', data: {'id': conversationId});
      }
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao carregar conversa', exception: e);
      _showError('Erro ao carregar conversa', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Busca mensagens
  Future<void> searchMessages(String query) async {
    if (query.trim().isEmpty) return;

    AppLogger.action('search_messages', feature: FeatureTag.chat, data: {'query': query});
    
    try {
      // TODO: Obter userId do AuthController
      const userId = 'current_user_id';
      
      final results = await manageConversationUseCase.searchMessages(query, userId);
      
      AppLogger.debug(FeatureTag.chat, 'Resultados de busca', data: {
        'query': query,
        'results_count': results.length,
      });
    } catch (e) {
      AppLogger.error(FeatureTag.chat, 'Erro na busca', error: e);
      _showError('Erro na busca', e.toString());
    }
  }

  /// Reenviar mensagem com erro
  Future<void> retryMessage(ChatMessage message) async {
    if (message.hasError && message.isAssistant) {
      AppLogger.action('retry_message', feature: FeatureTag.chat);
      
      // Remove mensagem com erro
      messages.removeWhere((m) => m.id == message.id);
      
      // Gera nova resposta
      await _generateAssistantResponse();
    }
  }

  /// Copia mensagem para clipboard
  void copyMessage(ChatMessage message) {
    AppLogger.action('copy_message', feature: FeatureTag.chat);
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
    final stats = {
      'total_messages': messages.length,
      'user_messages': messages.where((m) => m.isUser).length,
      'assistant_messages': messages.where((m) => m.isAssistant).length,
      'messages_with_insights': messages.where((m) => m.hasFinancialInsight).length,
      'error_messages': messages.where((m) => m.hasError).length,
    };
    
    AppLogger.debug(FeatureTag.chat, 'Estatísticas da conversa', data: stats);
    return stats;
  }

  /// Verifica se pode enviar mensagem
  bool get canSendMessage => 
      !isSendingMessage.value && 
      !isLoading.value && 
      messageController.text.trim().isNotEmpty;

  /// Verifica se está em modo de registro de despesa
  bool get isInExpenseMode => isAwaitingExpenseConfirmation.value;

  /// Cancela o modo de despesa atual
  void cancelExpenseMode() {
    if (isAwaitingExpenseConfirmation.value) {
      AppLogger.action('cancel_expense_mode', feature: FeatureTag.chat);
      _cancelPendingExpense();
    }
  }

  // ============================================
  // PERGUNTAS RÁPIDAS
  // ============================================

  /// Processa uma pergunta rápida e adiciona a resposta ao chat
  Future<void> handleQuickQuestion(QuickQuestion question) async {
    AppLogger.info(FeatureTag.chat, '🎯 [Controller] handleQuickQuestion chamado', data: {
      'question_id': question.id,
      'question_text': question.text,
      'question_category': question.category.name,
      'is_processing': isProcessingQuickQuestion.value,
      'is_sending': isSendingMessage.value,
    });
    
    if (isProcessingQuickQuestion.value || isSendingMessage.value) {
      AppLogger.warning(FeatureTag.chat, '⚠️ [Controller] Pergunta rápida ignorada - já processando', data: {
        'is_processing': isProcessingQuickQuestion.value,
        'is_sending': isSendingMessage.value,
      });
      return;
    }

    final opId = AppLogger.startOp(FeatureTag.chat, 'handle_quick_question', data: {
      'question_id': question.id,
      'question_text': question.text,
    });
    
    final startTime = DateTime.now();

    try {
      AppLogger.debug(FeatureTag.chat, '🔄 [Controller] Iniciando processamento', data: {
        'messages_count_before': messages.length,
        'conversation_id': currentConversation.value?.id,
      });
      
      isProcessingQuickQuestion.value = true;
      isTyping.value = true;
      
      AppLogger.state(FeatureTag.chat, 'quick_question_state', data: {
        'is_processing': true,
        'is_typing': true,
      });

      // Adiciona a pergunta do usuário ao chat
      final userMessage = ChatMessage.user(
        content: question.text,
        metadata: {
          'timestamp': DateTime.now().toIso8601String(),
          'source': 'quick_question',
          'question_id': question.id,
        },
      );

      messages.add(userMessage);
      AppLogger.info(FeatureTag.chat, '📝 [Controller] Mensagem do usuário adicionada ao chat', data: {
        'message_id': userMessage.id,
        'content_length': question.text.length,
        'messages_count': messages.length,
      });
      
      AppLogger.chatMessage('user', question.text.length);
      _scrollToBottom();

      // Salva mensagem do usuário na conversa
      if (currentConversation.value != null) {
        AppLogger.debug(FeatureTag.chat, '💾 [Controller] Salvando mensagem do usuário na conversa');
        await manageConversationUseCase.addMessageToConversation(
          conversationId: currentConversation.value!.id,
          message: userMessage,
        );
        AppLogger.debug(FeatureTag.chat, '✅ [Controller] Mensagem do usuário salva');
      }

      // Verifica se o serviço está disponível
      AppLogger.debug(FeatureTag.chat, '🔍 [Controller] Verificando QuickQuestionsService', data: {
        'service_is_null': _quickQuestionsService == null,
      });
      
      if (_quickQuestionsService == null) {
        AppLogger.info(FeatureTag.chat, '🆕 [Controller] Criando nova instância do QuickQuestionsService');
        _quickQuestionsService = Get.put(QuickQuestionsService());
      }

      // Processa a pergunta e obtém resposta personalizada
      AppLogger.info(FeatureTag.chat, '🚀 [Controller] Chamando QuickQuestionsService.processQuestion', data: {
        'question_id': question.id,
      });
      
      final serviceStartTime = DateTime.now();
      final result = await _quickQuestionsService!.processQuestion(question.id);
      final serviceDuration = DateTime.now().difference(serviceStartTime);
      
      AppLogger.info(FeatureTag.chat, '📥 [Controller] Resposta recebida do serviço', data: {
        'question_id': question.id,
        'has_data': result.hasData,
        'response_length': result.response.length,
        'service_duration_ms': serviceDuration.inMilliseconds,
        'data_keys': result.data.keys.toList(),
      });

      // Cria mensagem do assistente com a resposta
      final assistantMessage = ChatMessage.assistant(
        content: result.response,
        metadata: {
          'type': 'quick_question_response',
          'question_id': question.id,
          'has_data': result.hasData,
          'data': result.data,
        },
      );

      messages.add(assistantMessage);
      AppLogger.info(FeatureTag.chat, '🤖 [Controller] Mensagem do assistente adicionada ao chat', data: {
        'message_id': assistantMessage.id,
        'content_length': result.response.length,
        'messages_count': messages.length,
      });
      
      AppLogger.chatMessage('assistant', result.response.length, hasInsight: result.hasData);
      _scrollToBottom();

      // Salva resposta na conversa
      if (currentConversation.value != null) {
        AppLogger.debug(FeatureTag.chat, '💾 [Controller] Salvando resposta do assistente na conversa');
        await manageConversationUseCase.addMessageToConversation(
          conversationId: currentConversation.value!.id,
          message: assistantMessage,
        );
        AppLogger.debug(FeatureTag.chat, '✅ [Controller] Resposta do assistente salva');
      }

      // Registra evento de analytics
      AppLogger.debug(FeatureTag.chat, '📊 [Controller] Registrando evento de analytics');
      await analyticsService.trackChatEvent(
        type: ChatEventType.promptSent,
        properties: {
          'message_type': 'quick_question',
          'question_id': question.id,
          'has_data': result.hasData,
          'conversation_id': currentConversation.value?.id,
        },
      );

      final totalDuration = DateTime.now().difference(startTime);
      AppLogger.completeOp(opId, message: 'Pergunta rápida processada com sucesso', data: {
        'question_id': question.id,
        'response_length': result.response.length,
        'has_data': result.hasData,
        'total_duration_ms': totalDuration.inMilliseconds,
        'service_duration_ms': serviceDuration.inMilliseconds,
      });
      
      AppLogger.info(FeatureTag.chat, '✅ [Controller] Fluxo completo finalizado', data: {
        'question_id': question.id,
        'total_duration_ms': totalDuration.inMilliseconds,
        'final_messages_count': messages.length,
      });
      
      // #region agent log
      _debugLogChat('H5', 'chat_controller.dart:handleQuickQuestion:before_record', 'Antes de chamar _recordChatUsage em handleQuickQuestion', {'question_id': question.id});
      // #endregion
      
      // Registra uso da mensagem de pergunta rápida
      await _recordChatUsage();
      
      // #region agent log
      _debugLogChat('H5', 'chat_controller.dart:handleQuickQuestion:after_record', 'Após chamar _recordChatUsage em handleQuickQuestion', {'question_id': question.id, 'remaining': currentUsageLimit.value?.remainingToday});
      // #endregion

    } catch (e, stackTrace) {
      final totalDuration = DateTime.now().difference(startTime);
      AppLogger.failOp(opId, 'Erro ao processar pergunta rápida', exception: e);
      AppLogger.error(FeatureTag.chat, '❌ [Controller] Exceção no handleQuickQuestion', error: e, data: {
        'question_id': question.id,
        'duration_ms': totalDuration.inMilliseconds,
        'stack_trace': stackTrace.toString().substring(0, 500),
      });
      
      // Adiciona mensagem de erro
      final errorMsg = ChatMessage.assistant(
        content: '❌ Desculpe, não consegui processar sua pergunta. Tente novamente.',
        metadata: {
          'type': 'error',
          'question_id': question.id,
          'error': e.toString(),
        },
        status: ChatMessageStatus.error,
      );

      messages.add(errorMsg);
      _scrollToBottom();
      
      AppLogger.warning(FeatureTag.chat, '⚠️ [Controller] Mensagem de erro adicionada ao chat');

    } finally {
      isProcessingQuickQuestion.value = false;
      isTyping.value = false;
      
      AppLogger.state(FeatureTag.chat, 'quick_question_state_final', data: {
        'is_processing': false,
        'is_typing': false,
      });
    }
  }

  /// Verifica se está processando uma pergunta rápida
  bool get isInQuickQuestionMode => isProcessingQuickQuestion.value;
}