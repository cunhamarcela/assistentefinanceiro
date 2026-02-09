import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/insight_report.dart';

/// Card de resumo do relatório
class ReportSummaryCard extends StatelessWidget {
  final InsightReport report;
  final VoidCallback? onTap;

  const ReportSummaryCard({
    super.key,
    required this.report,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppSpacing.lg),
            _buildMetrics(),
            const SizedBox(height: AppSpacing.md),
            _buildPeriodInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.title,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.colorTextOnDark,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                report.description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.colorTextOnDark.withOpacity(0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.colorTextOnDark.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getReportIcon(),
            color: AppColors.colorTextOnDark,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildMetrics() {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildMetricItem(
              'Total Gasto',
              CurrencyFormatter.formatCurrency(report.totalAmount),
              Icons.account_balance_wallet,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 1,
            child: _buildMetricItem(
              'Transações',
              report.transactionCount.toString(),
              Icons.receipt_long,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: _buildMetricItem(
              'Média Diária',
              CurrencyFormatter.formatCurrency(report.dailyAverage),
              Icons.trending_up,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.colorTextOnDark.withOpacity(0.8),
              size: 14,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.colorTextOnDark.withOpacity(0.8),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.colorTextOnDark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPeriodInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.colorTextOnDark.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today,
            color: AppColors.colorTextOnDark.withOpacity(0.8),
            size: 14,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              report.periodDescription,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.colorTextOnDark.withOpacity(0.9),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (report.hasRecommendations) ...[
            const SizedBox(width: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${report.recommendations.length} dicas',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getReportIcon() {
    switch (report.type) {
      case InsightReportType.categorySpending:
        return Icons.pie_chart;
      case InsightReportType.spendingTrend:
        return Icons.show_chart;
      case InsightReportType.monthlyComparison:
        return Icons.bar_chart;
      case InsightReportType.weeklyAnalysis:
        return Icons.analytics;
      case InsightReportType.budgetProgress:
        return Icons.track_changes;
    }
  }
}
