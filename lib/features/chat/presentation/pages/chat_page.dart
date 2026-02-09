import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/quick_questions_chips.dart';
import '../../../monetization/domain/entities/usage_limit.dart';
import '../../../monetization/presentation/widgets/usage_limit_widget.dart';

/// Página principal do chat IA
class ChatPage extends GetView<ChatController> {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.debug(FeatureTag.chat, '🎨 [ChatPage] build() chamado', data: {
      'messages_count': controller.messages.length,
      'is_loading': controller.isLoading.value,
      'is_typing': controller.isTyping.value,
    });
    
    // Listener para mostrar dialog de limite atingido
    ever(controller.showLimitDialog, (show) {
      if (show) {
        _showLimitReachedDialog(context);
        controller.dismissLimitDialog();
      }
    });
    
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Banner de aviso quando próximo do limite
          _buildLimitWarningBanner(),
          Expanded(child: _buildMessagesList()),
          _buildInputArea(),
        ],
      ),
    );
  }
  
  /// Banner de aviso quando próximo do limite
  Widget _buildLimitWarningBanner() {
    return Obx(() {
      if (!controller.shouldShowLimitWarning) {
        return const SizedBox.shrink();
      }
      
      final limit = controller.currentUsageLimit.value;
      final isLastUse = limit?.isLastUse ?? false;
      
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.colorBrandPrimary,
              AppColors.colorBrandDark,
            ],
          ),
        ),
        child: Row(
          children: [
            Icon(
              isLastUse ? Icons.warning_amber_rounded : Icons.info_outline,
              color: AppColors.colorTextOnDark,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isLastUse 
                    ? '⚠️ Última mensagem gratuita! Desbloqueie 24h de uso ilimitado.'
                    : '${limit?.remainingToday ?? 0} mensagens restantes hoje',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.colorTextOnDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () => controller.showAdToUnlockChat(),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.colorActionPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
              ),
              child: Text(
                '🎬 Desbloquear',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.colorTextOnDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
  
  /// Mostra dialog quando limite é atingido
  void _showLimitReachedDialog(BuildContext context) {
    // Rastreia exibição do prompt de anúncio
    AnalyticsService.instance.trackAdPromptShown(featureType: 'aiChat');
    
    LimitReachedDialog.show(
      context,
      featureType: FeatureType.aiChat,
      onWatchAd: () {
        controller.showAdToUnlockChat();
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 1,
      shadowColor: AppColors.divider,
      iconTheme: IconThemeData(color: AppColors.colorBrandPrimary),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assistente IA',
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.textDark,
            ),
          ),
          Obx(() => Text(
            controller.isTyping.value 
                ? 'Digitando...' 
                : 'Online',
            style: AppTextStyles.caption.copyWith(
              color: controller.isTyping.value 
                  ? AppColors.primary 
                  : AppColors.success,
            ),
          )),
        ],
      ),
      actions: [
        // Indicador de uso de mensagens
        _buildUsageIndicator(),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: AppColors.textDark,
          ),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.clear_all),
                  SizedBox(width: 8),
                  Text('Limpar Conversa'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'history',
              child: Row(
                children: [
                  Icon(Icons.history),
                  SizedBox(width: 8),
                  Text('Histórico'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Configurações'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return _buildLoadingState();
      }

      if (controller.messages.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        controller: controller.scrollController,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: controller.messages.length + 
                  (controller.isTyping.value ? 1 : 0),
        itemBuilder: (context, index) {
          // Mostra indicador de digitação no final
          if (index == controller.messages.length && controller.isTyping.value) {
            return const TypingIndicator();
          }

          final message = controller.messages[index];
          return ChatMessageBubble(
            message: message,
            onRetry: () => controller.retryMessage(message),
            onCopy: () => controller.copyMessage(message),
          );
        },
      );
    });
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Perguntas rápidas acima do input
            Obx(() {
              final showQuickQuestions = !controller.isAwaitingExpenseConfirmation.value &&
                         !controller.isProcessingQuickQuestion.value &&
                         controller.messages.isNotEmpty;
              
              AppLogger.debug(FeatureTag.chat, '🎨 [ChatPage] Renderizando área de input', data: {
                'show_quick_questions': showQuickQuestions,
                'is_awaiting_expense': controller.isAwaitingExpenseConfirmation.value,
                'is_processing_quick': controller.isProcessingQuickQuestion.value,
                'has_messages': controller.messages.isNotEmpty,
              });
              
              return QuickQuestionsInputSection(
                onQuestionSelected: (question) {
                  AppLogger.info(FeatureTag.chat, '👆 [ChatPage] Pergunta rápida selecionada na área de input', data: {
                    'question_id': question.id,
                    'question_text': question.text,
                  });
                  controller.handleQuickQuestion(question);
                },
                isVisible: showQuickQuestions,
              );
            }),
            // Campo de input
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Obx(() => ChatInput(
                controller: controller.messageController,
                onSend: controller.sendMessage,
                enabled: !controller.isLoading.value && 
                         !controller.isSendingMessage.value &&
                         !controller.isProcessingQuickQuestion.value,
                isLoading: controller.isSendingMessage.value || 
                           controller.isProcessingQuickQuestion.value,
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Carregando conversa...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    AppLogger.debug(FeatureTag.chat, '🎨 [ChatPage] Renderizando estado vazio (empty state)');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.colorBrandSoft.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy,
              size: 64,
              color: AppColors.colorBrandSoft,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Olá! 👋',
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.colorTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Sou seu assistente financeiro inteligente.\nComo posso ajudar você hoje?',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.colorTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          // Perguntas rápidas organizadas por categoria
          QuickQuestionsExpanded(
            onQuestionSelected: (question) {
              AppLogger.info(FeatureTag.chat, '👆 [ChatPage] Pergunta rápida selecionada no empty state', data: {
                'question_id': question.id,
                'question_text': question.text,
              });
              controller.handleQuickQuestion(question);
            },
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear':
        _showClearConfirmation();
        break;
      case 'history':
        _showConversationHistory();
        break;
      case 'settings':
        _showChatSettings();
        break;
    }
  }

  void _showClearConfirmation() {
    Get.dialog(
      AlertDialog(
        title: const Text('Limpar Conversa'),
        content: const Text(
          'Tem certeza que deseja limpar toda a conversa atual? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.clearCurrentConversation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  void _showConversationHistory() {
    // TODO: Implementar tela de histórico de conversas
    Get.snackbar(
      'Em Desenvolvimento',
      'Histórico de conversas será implementado em breve',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showChatSettings() {
    // TODO: Implementar configurações do chat
    Get.snackbar(
      'Em Desenvolvimento',
      'Configurações do chat serão implementadas em breve',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  
  /// Indicador de uso de mensagens no AppBar
  Widget _buildUsageIndicator() {
    return Obx(() {
      final hasUnlimited = controller.hasUnlimitedAccess.value;
      final limit = controller.currentUsageLimit.value;
      
      // Se não tem dados de limite, mostra o limite padrão
      final displayLimit = limit ?? UsageLimit.create(
        userId: 'display',
        featureType: FeatureType.aiChat,
      );
      
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: GestureDetector(
          onTap: () {
            if (!hasUnlimited && displayLimit.isNearLimit) {
              _showUnlockPrompt();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getUsageIndicatorColor(hasUnlimited, displayLimit),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getUsageIndicatorIcon(hasUnlimited, displayLimit),
                  size: 14,
                  color: _getUsageIndicatorTextColor(hasUnlimited, displayLimit),
                ),
                const SizedBox(width: 4),
                Text(
                  _getUsageDisplayText(hasUnlimited, displayLimit),
                  style: AppTextStyles.caption.copyWith(
                    color: _getUsageIndicatorTextColor(hasUnlimited, displayLimit),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
  
  String _getUsageDisplayText(bool hasUnlimited, UsageLimit limit) {
    if (hasUnlimited && controller.activeUnlock.value != null) {
      return '✨ Ilimitado (${controller.activeUnlock.value!.timeRemainingFormatted})';
    }
    return '${limit.remainingToday}/${limit.dailyLimit}';
  }
  
  Color _getUsageIndicatorColor(bool hasUnlimited, UsageLimit limit) {
    if (hasUnlimited) {
      return AppColors.colorSuccess.withOpacity(0.15);
    }
    if (limit.isLimitReached) {
      return AppColors.colorError.withOpacity(0.15);
    }
    if (limit.isNearLimit) {
      return AppColors.colorWarning.withOpacity(0.15);
    }
    return AppColors.colorBackgroundSecondary;
  }
  
  IconData _getUsageIndicatorIcon(bool hasUnlimited, UsageLimit limit) {
    if (hasUnlimited) {
      return Icons.star_rounded;
    }
    if (limit.isLimitReached) {
      return Icons.lock_rounded;
    }
    if (limit.isNearLimit) {
      return Icons.warning_amber_rounded;
    }
    return Icons.chat_bubble_outline_rounded;
  }
  
  Color _getUsageIndicatorTextColor(bool hasUnlimited, UsageLimit limit) {
    if (hasUnlimited) {
      return AppColors.colorSuccess;
    }
    if (limit.isLimitReached) {
      return AppColors.colorError;
    }
    if (limit.isNearLimit) {
      return AppColors.colorWarning;
    }
    return AppColors.colorTextSecondary;
  }
  
  /// Mostra prompt para desbloquear
  void _showUnlockPrompt() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.colorSurfaceCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.colorBorderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.movie_filter_rounded,
              size: 48,
              color: AppColors.colorBrandPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              'Desbloqueie o Chat IA',
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.colorTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Assista um anúncio curto e ganhe 24 horas de mensagens ilimitadas!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.colorTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.back();
                  controller.showAdToUnlockChat();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.colorActionPrimary,
                  foregroundColor: AppColors.colorTextOnDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.play_circle_filled_rounded),
                label: const Text(
                  'Assistir Anúncio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'Agora não',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.colorTextMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

