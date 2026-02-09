import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Modelo de dados para categoria no ranking
class TopCategoryData {
  final String id;
  final String name;
  final double amount;
  final Color color;
  final String? icon;
  final double? percentage;
  final double? budgetLimit;
  final bool? isExceeded;

  const TopCategoryData({
    required this.id,
    required this.name,
    required this.amount,
    required this.color,
    this.icon,
    this.percentage,
    this.budgetLimit,
    this.isExceeded,
  });

  /// Cria a partir de Map (compatibilidade com código existente)
  factory TopCategoryData.fromMap(Map<String, dynamic> map) {
    Color color;
    if (map['color'] is Color) {
      color = map['color'];
    } else if (map['color'] is String) {
      final colorStr = map['color'] as String;
      color = Color(
        int.parse(colorStr.substring(1), radix: 16) + 0xFF000000,
      );
    } else {
      color = AppColors.colorTextMuted;
    }

    return TopCategoryData(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Categoria',
      amount: (map['amount'] ?? 0.0).toDouble(),
      color: color,
      icon: map['icon'],
      percentage: map['percentage']?.toDouble(),
      budgetLimit: map['budgetLimit']?.toDouble(),
      isExceeded: map['isExceeded'],
    );
  }
}

/// Widget reutilizável para exibir lista de categorias com ranking
/// 
/// Tokens utilizados:
/// - Background card: colorSurfaceCard
/// - Texto título: colorTextPrimary
/// - Texto secundário: colorTextMuted
/// - Borda: colorBorderSubtle
class TopCategoriesWidget extends StatelessWidget {
  /// Lista de categorias para exibir
  final List<TopCategoryData> categories;
  
  /// Título da seção (opcional)
  final String? title;
  
  /// Ícone do título (opcional)
  final String? titleEmoji;
  
  /// Máximo de categorias a exibir
  final int maxItems;
  
  /// Se deve mostrar o ranking numérico
  final bool showRanking;
  
  /// Se deve mostrar o ícone da categoria
  final bool showCategoryIcon;
  
  /// Se deve mostrar a porcentagem
  final bool showPercentage;
  
  /// Se deve mostrar indicador de excesso de orçamento
  final bool showBudgetIndicator;
  
  /// Callback quando uma categoria é tocada
  final void Function(TopCategoryData)? onCategoryTap;
  
  /// Se deve usar layout compacto
  final bool compact;

  const TopCategoriesWidget({
    super.key,
    required this.categories,
    this.title,
    this.titleEmoji,
    this.maxItems = 5,
    this.showRanking = true,
    this.showCategoryIcon = true,
    this.showPercentage = false,
    this.showBudgetIndicator = false,
    this.onCategoryTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final displayCategories = categories.take(maxItems).toList();

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
        ...displayCategories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          return _TopCategoryItem(
            rank: index + 1,
            category: category,
            showRanking: showRanking,
            showCategoryIcon: showCategoryIcon,
            showPercentage: showPercentage,
            showBudgetIndicator: showBudgetIndicator,
            compact: compact,
            onTap: onCategoryTap != null ? () => onCategoryTap!(category) : null,
          );
        }),
      ],
    );
  }
}

class _TopCategoryItem extends StatelessWidget {
  final int rank;
  final TopCategoryData category;
  final bool showRanking;
  final bool showCategoryIcon;
  final bool showPercentage;
  final bool showBudgetIndicator;
  final bool compact;
  final VoidCallback? onTap;

  const _TopCategoryItem({
    required this.rank,
    required this.category,
    required this.showRanking,
    required this.showCategoryIcon,
    required this.showPercentage,
    required this.showBudgetIndicator,
    required this.compact,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: compact ? 8.h : 12.h),
        padding: EdgeInsets.all(compact ? 12.w : 16.w),
        decoration: BoxDecoration(
          color: AppColors.colorSurfaceCard,
          borderRadius: BorderRadius.circular(12.r),
          border: showBudgetIndicator && category.isExceeded == true
              ? Border.all(color: AppColors.colorError.withOpacity(0.5), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: category.color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ranking ou ícone
            if (showRanking)
              Container(
                width: compact ? 32.w : 40.w,
                height: compact ? 32.w : 40.w,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      color: category.color,
                      fontSize: compact ? 14.sp : 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else if (showCategoryIcon && category.icon != null)
              Container(
                width: compact ? 32.w : 40.w,
                height: compact ? 32.w : 40.w,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Text(
                    category.icon!,
                    style: TextStyle(fontSize: compact ? 16.sp : 20.sp),
                  ),
                ),
              ),
            SizedBox(width: compact ? 12.w : 16.w),
            
            // Nome e valor
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.colorTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 14.sp : null,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                        'R\$ ${category.amount.toStringAsFixed(2)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.colorTextMuted,
                          fontSize: compact ? 12.sp : null,
                        ),
                      ),
                      if (showPercentage && category.percentage != null) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.colorBorderSubtle.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            '${category.percentage!.toStringAsFixed(0)}%',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.colorTextMuted,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Indicador de status ou ícone
            if (showBudgetIndicator && category.isExceeded != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: category.isExceeded!
                      ? AppColors.colorError.withOpacity(0.1)
                      : AppColors.colorSuccess.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  category.isExceeded! ? Icons.warning : Icons.check_circle,
                  color: category.isExceeded! ? AppColors.colorError : AppColors.colorSuccess,
                  size: compact ? 18.sp : 20.sp,
                ),
              )
            else if (showCategoryIcon && category.icon != null && showRanking)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  category.icon!,
                  style: TextStyle(fontSize: compact ? 14.sp : 16.sp),
                ),
              )
            else if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: AppColors.colorTextMuted,
                size: 20.sp,
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget simplificado para exibir categorias dominantes (sem ranking)
class DominantCategoriesWidget extends StatelessWidget {
  final List<TopCategoryData> categories;
  final String? title;
  final int maxItems;
  final void Function(TopCategoryData)? onCategoryTap;

  const DominantCategoriesWidget({
    super.key,
    required this.categories,
    this.title,
    this.maxItems = 3,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return TopCategoriesWidget(
      categories: categories,
      title: title,
      maxItems: maxItems,
      showRanking: false,
      showCategoryIcon: true,
      showPercentage: true,
      onCategoryTap: onCategoryTap,
      compact: true,
    );
  }
}



