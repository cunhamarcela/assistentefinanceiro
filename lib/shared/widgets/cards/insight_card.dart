import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/chat/domain/entities/financial_insight.dart';

/// Card para exibir insights financeiros
class InsightCard extends StatelessWidget {
  final FinancialInsight insight;
  final VoidCallback? onTap;
  final VoidCallback? onActionTap;
  final bool showAction;

  const InsightCard({
    super.key,
    required this.insight,
    this.onTap,
    this.onActionTap,
    this.showAction = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getInsightColor().withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textSecondary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppSpacing.sm),
            _buildDescription(),
            if (insight.hasAction && showAction) ...[
              const SizedBox(height: AppSpacing.md),
              _buildAction(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: _getInsightColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getInsightIcon(),
            color: _getInsightColor(),
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insight.title,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildPriorityBadge(),
            ],
          ),
        ),
        if (insight.isExpired)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Expirado',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPriorityBadge() {
    final color = _getPriorityColor();
    final text = _getPriorityText();
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      insight.description,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textDark,
        height: 1.4,
      ),
    );
  }

  Widget _buildAction() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onActionTap,
        icon: Icon(
          Icons.arrow_forward,
          size: 16,
          color: _getInsightColor(),
        ),
        label: Text(
          insight.actionText!,
          style: AppTextStyles.button.copyWith(
            color: _getInsightColor(),
            fontSize: 14,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          backgroundColor: _getInsightColor().withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Color _getInsightColor() {
    switch (insight.type) {
      case FinancialInsightType.success:
        return AppColors.success;
      case FinancialInsightType.warning:
        return AppColors.warning;
      case FinancialInsightType.error:
        return AppColors.error;
      case FinancialInsightType.info:
        return AppColors.info;
      case FinancialInsightType.opportunity:
        return AppColors.primary;
    }
  }

  IconData _getInsightIcon() {
    switch (insight.type) {
      case FinancialInsightType.success:
        return Icons.check_circle;
      case FinancialInsightType.warning:
        return Icons.warning;
      case FinancialInsightType.error:
        return Icons.error;
      case FinancialInsightType.info:
        return Icons.info;
      case FinancialInsightType.opportunity:
        return Icons.lightbulb;
    }
  }

  Color _getPriorityColor() {
    switch (insight.priority) {
      case FinancialInsightPriority.low:
        return AppColors.info;
      case FinancialInsightPriority.medium:
        return AppColors.warning;
      case FinancialInsightPriority.high:
        return AppColors.error;
      case FinancialInsightPriority.critical:
        return const Color(0xFF8B0000); // Vermelho escuro
    }
  }

  String _getPriorityText() {
    switch (insight.priority) {
      case FinancialInsightPriority.low:
        return 'Baixa';
      case FinancialInsightPriority.medium:
        return 'Média';
      case FinancialInsightPriority.high:
        return 'Alta';
      case FinancialInsightPriority.critical:
        return 'Crítica';
    }
  }
}

/// Card compacto para insights na home
class InsightCardCompact extends StatelessWidget {
  final FinancialInsight insight;
  final VoidCallback? onTap;

  const InsightCardCompact({
    super.key,
    required this.insight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getInsightColor().withOpacity(0.1),
              _getInsightColor().withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getInsightColor().withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getInsightIcon(),
              color: _getInsightColor(),
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    insight.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Color _getInsightColor() {
    switch (insight.type) {
      case FinancialInsightType.success:
        return AppColors.success;
      case FinancialInsightType.warning:
        return AppColors.warning;
      case FinancialInsightType.error:
        return AppColors.error;
      case FinancialInsightType.info:
        return AppColors.info;
      case FinancialInsightType.opportunity:
        return AppColors.primary;
    }
  }

  IconData _getInsightIcon() {
    switch (insight.type) {
      case FinancialInsightType.success:
        return Icons.check_circle;
      case FinancialInsightType.warning:
        return Icons.warning;
      case FinancialInsightType.error:
        return Icons.error;
      case FinancialInsightType.info:
        return Icons.info;
      case FinancialInsightType.opportunity:
        return Icons.lightbulb;
    }
  }
}
