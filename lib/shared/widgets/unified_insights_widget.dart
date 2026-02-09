import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/expenses/data/services/unified_insights_service.dart';

/// Widget reutilizável para exibir insights unificados
/// 
/// Tokens utilizados:
/// - Background card: colorSurfaceCard
/// - Texto título: colorTextPrimary
/// - Texto descrição: colorTextMuted
/// - Prioridades: colorError, colorWarning, colorActionPrimary, colorBrandPrimary
class UnifiedInsightsWidget extends StatelessWidget {
  final List<UnifiedInsight> insights;
  final String? title;
  final String? titleEmoji;
  final int maxItems;
  final bool showPriorityBadge;
  final bool compact;
  final void Function(UnifiedInsight)? onInsightTap;
  final void Function(UnifiedInsight, String)? onActionTap;

  const UnifiedInsightsWidget({
    super.key,
    required this.insights,
    this.title,
    this.titleEmoji,
    this.maxItems = 5,
    this.showPriorityBadge = true,
    this.compact = false,
    this.onInsightTap,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    final displayInsights = insights.take(maxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            titleEmoji != null ? '$titleEmoji $title' : title!,
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.colorTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
        ],
        ...displayInsights.map((insight) => _InsightCard(
          insight: insight,
          showPriorityBadge: showPriorityBadge,
          compact: compact,
          onTap: onInsightTap != null ? () => onInsightTap!(insight) : null,
          onActionTap: onActionTap != null && insight.actionText != null
              ? () => onActionTap!(insight, insight.actionText!)
              : null,
        )),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final UnifiedInsight insight;
  final bool showPriorityBadge;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onActionTap;

  const _InsightCard({
    required this.insight,
    required this.showPriorityBadge,
    required this.compact,
    this.onTap,
    this.onActionTap,
  });

  Color get _priorityColor {
    switch (insight.priority) {
      case UnifiedInsightPriority.urgent:
        return AppColors.colorError;
      case UnifiedInsightPriority.high:
        return AppColors.colorWarning;
      case UnifiedInsightPriority.medium:
        return AppColors.colorActionPrimary;
      case UnifiedInsightPriority.low:
        return AppColors.colorBrandPrimary;
    }
  }

  Color get _typeBackgroundColor {
    switch (insight.type) {
      case UnifiedInsightType.budgetExceeded:
        return AppColors.colorError.withOpacity(0.1);
      case UnifiedInsightType.budgetWarning:
        return AppColors.colorWarning.withOpacity(0.1);
      case UnifiedInsightType.savingsOpportunity:
        return AppColors.colorActionPrimary.withOpacity(0.1);
      case UnifiedInsightType.positiveReinforcement:
        return AppColors.colorSuccess.withOpacity(0.1);
      case UnifiedInsightType.goalProgress:
        return AppColors.colorBrandPrimary.withOpacity(0.1);
      default:
        return AppColors.colorBrandSoft.withOpacity(0.1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: compact ? 8.h : 12.h),
        decoration: BoxDecoration(
          color: AppColors.colorSurfaceCard,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: _priorityColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com prioridade
            Container(
              padding: EdgeInsets.all(compact ? 12.w : 16.w),
              decoration: BoxDecoration(
                color: _typeBackgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  topRight: Radius.circular(12.r),
                ),
              ),
              child: Row(
                children: [
                  // Emoji
                  if (insight.emoji != null)
                    Text(
                      insight.emoji!,
                      style: TextStyle(fontSize: compact ? 18.sp : 20.sp),
                    )
                  else
                    Text(
                      insight.priority.emoji,
                      style: TextStyle(fontSize: compact ? 18.sp : 20.sp),
                    ),
                  SizedBox(width: 12.w),
                  
                  // Título
                  Expanded(
                    child: Text(
                      insight.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.colorTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: compact ? 14.sp : null,
                      ),
                    ),
                  ),
                  
                  // Badge de prioridade
                  if (showPriorityBadge && !compact)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _priorityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        insight.priority.displayName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _priorityColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Conteúdo
            Padding(
              padding: EdgeInsets.all(compact ? 12.w : 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Descrição
                  Text(
                    insight.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.colorTextMuted,
                      fontSize: compact ? 13.sp : null,
                    ),
                  ),
                  
                  // Sugestões de ação (se houver e não for compacto)
                  if (!compact && insight.actionSuggestions.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Text(
                      'Sugestões:',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.colorTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    ...insight.actionSuggestions.take(3).map((suggestion) => 
                      Padding(
                        padding: EdgeInsets.only(bottom: 4.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.colorTextMuted,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                suggestion,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.colorTextMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  // Botão de ação
                  if (onActionTap != null && insight.actionText != null) ...[
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onActionTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _priorityColor,
                          foregroundColor: AppColors.colorTextOnDark,
                          padding: EdgeInsets.symmetric(vertical: compact ? 10.h : 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text(insight.actionText!),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget compacto para exibir insights em lista
class CompactInsightsList extends StatelessWidget {
  final List<UnifiedInsight> insights;
  final String? title;
  final int maxItems;
  final void Function(UnifiedInsight)? onInsightTap;

  const CompactInsightsList({
    super.key,
    required this.insights,
    this.title,
    this.maxItems = 3,
    this.onInsightTap,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedInsightsWidget(
      insights: insights,
      title: title,
      maxItems: maxItems,
      compact: true,
      showPriorityBadge: false,
      onInsightTap: onInsightTap,
    );
  }
}

/// Widget para exibir apenas highlights como lista simples
class HighlightsWidget extends StatelessWidget {
  final List<String> highlights;
  final String? title;
  final String? titleEmoji;

  const HighlightsWidget({
    super.key,
    required this.highlights,
    this.title,
    this.titleEmoji,
  });

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            titleEmoji != null ? '$titleEmoji $title' : title!,
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.colorTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
        ],
        ...highlights.map((highlight) => _HighlightItem(text: highlight)),
      ],
    );
  }
}

class _HighlightItem extends StatelessWidget {
  final String text;

  const _HighlightItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.colorBrandSoft.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.colorBrandSoft.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb,
            color: AppColors.colorActionPrimary,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.colorTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



