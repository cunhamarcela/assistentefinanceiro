import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/insight_report.dart';
import '../../domain/usecases/generate_insight_report_usecase.dart';

/// Barra de filtros para relatórios
class ReportFilterBar extends StatelessWidget {
  final ReportPeriod selectedPeriod;
  final InsightReportType selectedType;
  final Function(ReportPeriod) onPeriodChanged;
  final Function(InsightReportType) onTypeChanged;

  const ReportFilterBar({
    super.key,
    required this.selectedPeriod,
    required this.selectedType,
    required this.onPeriodChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildPeriodFilter(),
          const SizedBox(height: AppSpacing.md),
          _buildTypeFilter(),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Período',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ReportPeriod.values.map((period) {
              final isSelected = period == selectedPeriod;
              return Container(
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                child: FilterChip(
                  label: Text(period.displayName),
                  selected: isSelected,
                  onSelected: (_) => onPeriodChanged(period),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                  labelStyle: AppTextStyles.caption.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textDark,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Relatório',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: InsightReportType.values.map((type) {
              final isSelected = type == selectedType;
              return Container(
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                child: FilterChip(
                  label: Text(type.displayName),
                  selected: isSelected,
                  onSelected: (_) => onTypeChanged(type),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.accent.withOpacity(0.2),
                  checkmarkColor: AppColors.accent,
                  labelStyle: AppTextStyles.caption.copyWith(
                    color: isSelected ? AppColors.accent : AppColors.textDark,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.accent : AppColors.divider,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Extensões para exibir nomes amigáveis
extension ReportPeriodExtension on ReportPeriod {
  String get displayName {
    switch (this) {
      case ReportPeriod.today:
        return 'Hoje';
      case ReportPeriod.yesterday:
        return 'Ontem';
      case ReportPeriod.thisWeek:
        return 'Esta Semana';
      case ReportPeriod.lastWeek:
        return 'Semana Passada';
      case ReportPeriod.thisMonth:
        return 'Este Mês';
      case ReportPeriod.lastMonth:
        return 'Mês Passado';
      case ReportPeriod.last30Days:
        return 'Últimos 30 Dias';
      case ReportPeriod.last90Days:
        return 'Últimos 90 Dias';
    }
  }
}

extension InsightReportTypeExtension on InsightReportType {
  String get displayName {
    switch (this) {
      case InsightReportType.categorySpending:
        return 'Por Categoria';
      case InsightReportType.spendingTrend:
        return 'Tendência';
      case InsightReportType.monthlyComparison:
        return 'Comparação';
      case InsightReportType.weeklyAnalysis:
        return 'Semanal';
      case InsightReportType.budgetProgress:
        return 'Orçamento';
    }
  }
}

