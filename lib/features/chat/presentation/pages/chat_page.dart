import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/typing_indicator.dart';

/// Página principal do chat IA
class ChatPage extends GetView<ChatController> {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 1,
      shadowColor: AppColors.divider,
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
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ChatInput(
            controller: controller.messageController,
            onSend: controller.sendMessage,
            enabled: controller.canSendMessage,
            isLoading: controller.isSendingMessage.value,
          ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Olá! 👋',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Sou seu assistente financeiro inteligente.\nComo posso ajudar você hoje?',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final quickActions = [
      {
        'title': 'Analisar Gastos',
        'subtitle': 'Ver resumo dos meus gastos',
        'icon': Icons.analytics,
        'message': 'Mostre um resumo dos meus gastos deste mês',
      },
      {
        'title': 'Criar Relatório',
        'subtitle': 'Gerar relatório visual',
        'icon': Icons.bar_chart,
        'message': 'Crie um relatório visual dos meus gastos por categoria',
      },
      {
        'title': 'Dicas de Economia',
        'subtitle': 'Sugestões personalizadas',
        'icon': Icons.lightbulb,
        'message': 'Dê dicas de como posso economizar dinheiro',
      },
    ];

    return Column(
      children: quickActions.map((action) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AppButton.outlined(
            text: action['title'] as String,
            icon: action['icon'] as IconData,
            onPressed: () => controller.sendMessage(
              text: action['message'] as String,
            ),
          ),
        );
      }).toList(),
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
}
