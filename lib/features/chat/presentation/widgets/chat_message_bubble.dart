import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/chat_message.dart';

/// Widget para exibir uma mensagem do chat em formato de balão
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;
  final VoidCallback? onCopy;
  final VoidCallback? onInsightTap;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.onCopy,
    this.onInsightTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) _buildAvatar(),
          if (!message.isUser) const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: _buildMessageContent(),
          ),
          if (message.isUser) const SizedBox(width: AppSpacing.sm),
          if (message.isUser) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: message.isUser ? AppColors.primary : AppColors.accent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        message.isUser ? Icons.person : Icons.smart_toy,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildMessageContent() {
    return Column(
      crossAxisAlignment: message.isUser 
          ? CrossAxisAlignment.end 
          : CrossAxisAlignment.start,
      children: [
        _buildMessageBubble(),
        const SizedBox(height: AppSpacing.xs),
        _buildMessageInfo(),
        if (message.hasFinancialInsight) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildInsightButton(),
        ],
      ],
    );
  }

  Widget _buildMessageBubble() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: message.isUser 
            ? AppColors.primary 
            : AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(message.isUser ? 16 : 4),
          bottomRight: Radius.circular(message.isUser ? 4 : 16),
        ),
        border: message.isUser 
            ? null 
            : Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: message.isUser 
                  ? Colors.white 
                  : AppColors.textDark,
              height: 1.4,
            ),
          ),
          if (message.hasError) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildErrorIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInfo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.createdAt),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (message.isUser) ...[
          const SizedBox(width: AppSpacing.xs),
          _buildStatusIcon(),
        ],
        if (!message.isUser && (onCopy != null || onRetry != null)) ...[
          const SizedBox(width: AppSpacing.sm),
          _buildActionButtons(),
        ],
      ],
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (message.status) {
      case ChatMessageStatus.sending:
        icon = Icons.access_time;
        color = AppColors.textSecondary;
        break;
      case ChatMessageStatus.sent:
        icon = Icons.check;
        color = AppColors.success;
        break;
      case ChatMessageStatus.error:
        icon = Icons.error;
        color = AppColors.error;
        break;
    }

    return Icon(
      icon,
      size: 12,
      color: color,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onCopy != null)
          GestureDetector(
            onTap: onCopy,
            child: Icon(
              Icons.copy,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
        if (message.hasError && onRetry != null) ...[
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onRetry,
            child: Icon(
              Icons.refresh,
              size: 16,
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message.errorMessage ?? 'Erro ao processar mensagem',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightButton() {
    return GestureDetector(
      onTap: onInsightTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insights,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Ver Insight',
              style: AppTextStyles.button.copyWith(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.arrow_forward,
              size: 14,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}

