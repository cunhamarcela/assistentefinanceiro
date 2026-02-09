import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/expenses/domain/entities/financial_insight.dart';

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
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getInsightColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppSpacing.sm),
              _buildDescription(),
              if (insight.actionSuggestions.isNotEmpty && showAction) ...[
                const SizedBox(height: AppSpacing.md),
                _buildAction(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: _getInsightColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getInsightIcon(),
            size: 20,
            color: _getInsightColor(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insight.title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildPriorityBadge(),
            ],
          ),
        ),
        if (insight.isRead)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Lido',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      insight.description,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textSecondary,
        height: 1.4,
      ),
    );
  }

  Widget _buildAction() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onActionTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: _getInsightColor()),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Icon(
          Icons.arrow_forward,
          size: 16,
          color: _getInsightColor(),
        ),
        label: Text(
          insight.actionSuggestions.first,
          style: AppTextStyles.button.copyWith(
            color: _getInsightColor(),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _getPriorityColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getPriorityText(),
        style: AppTextStyles.caption.copyWith(
          color: _getPriorityColor(),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getInsightColor() {
    switch (insight.type) {
      case FinancialInsightType.budgetExceeded:
        return AppColors.error;
      case FinancialInsightType.budgetWarning:
        return AppColors.warning;
      case FinancialInsightType.savingsOpportunity:
        return AppColors.success;
      case FinancialInsightType.goalProgress:
        return AppColors.primary;
      case FinancialInsightType.spendingPattern:
        return AppColors.info;
      case FinancialInsightType.categoryAnalysis:
        return AppColors.primary;
      case FinancialInsightType.monthlyComparison:
        return AppColors.info;
      case FinancialInsightType.positiveProgress:
        return AppColors.success;
    }
  }

  IconData _getInsightIcon() {
    switch (insight.type) {
      case FinancialInsightType.budgetExceeded:
        return Icons.error;
      case FinancialInsightType.budgetWarning:
        return Icons.warning;
      case FinancialInsightType.savingsOpportunity:
        return Icons.lightbulb;
      case FinancialInsightType.goalProgress:
        return Icons.track_changes;
      case FinancialInsightType.spendingPattern:
        return Icons.trending_up;
      case FinancialInsightType.categoryAnalysis:
        return Icons.pie_chart;
      case FinancialInsightType.monthlyComparison:
        return Icons.compare_arrows;
      case FinancialInsightType.positiveProgress:
        return Icons.celebration;
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
      case FinancialInsightPriority.urgent:
        return AppColors.error;
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
      case FinancialInsightPriority.urgent:
        return 'Urgente';
    }
  }
}
