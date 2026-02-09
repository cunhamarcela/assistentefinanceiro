import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/top_categories_widget.dart';
import '../../../../shared/widgets/interactive_line_chart.dart';
import '../../domain/entities/multi_period_comparison.dart';
import '../../domain/entities/financial_insight.dart';
import '../controllers/multi_period_comparison_controller.dart';
import '../helpers/score_color_helper.dart';

/// Tokens utilizados:
/// - Background: colorBackgroundPrimary
/// - AppBar: colorBrandDark + colorTextOnDark
/// - Cards: colorSurfaceCard
/// - Texto: colorTextPrimary, colorTextMuted, colorTextOnDark
/// - Ações: colorBrandPrimary, colorActionPrimary
/// - Estados: colorSuccess, colorWarning, colorError
class MultiPeriodComparisonPage extends GetView<MultiPeriodComparisonController> {
  const MultiPeriodComparisonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackgroundPrimary,
      appBar: AppBar(
        title: Text(
          'Comparação Multi-Período',
          style: AppTextStyles.headingMedium.copyWith(color: AppColors.colorTextOnDark),
        ),
        backgroundColor: AppColors.colorBrandDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.colorTextOnDark),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: AppColors.colorTextOnDark),
            onPressed: controller.shareComparison,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.colorBrandPrimary),
                SizedBox(height: 16.h),
                Text(
                  'Analisando seus dados...',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.colorTextMuted,
                  ),
                ),
              ],
            ),
          );
        }

        if (!controller.hasData) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.refreshComparison,
          color: AppColors.colorBrandPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seletor de Período
                _buildPeriodSelector(),
                SizedBox(height: 16.h),
                
                // Filtro de Categoria
                _buildCategoryFilter(),
                SizedBox(height: 16.h),
                
                // Card de Score Principal (expandido se disponível)
                AnimatedOpacity(
                  opacity: controller.showChart.value ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  child: controller.enhancedScore != null 
                      ? _buildEnhancedScoreCard()
                      : _buildScoreCard(),
                ),
                SizedBox(height: 16.h),
                
                // Comparação com Orçamento (se disponível)
                if (controller.hasBudgetData)
                  AnimatedOpacity(
                    opacity: controller.showBudgetComparison.value ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    child: _buildBudgetComparisonSection(),
                  ),
                if (controller.hasBudgetData) SizedBox(height: 16.h),
                
                // Gráfico de Linha
                AnimatedOpacity(
                  opacity: controller.showChart.value ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeInOut,
                  child: _buildLineChart(),
                ),
                SizedBox(height: 16.h),
                
                // Estatísticas Resumidas
                AnimatedOpacity(
                  opacity: controller.showInsights.value ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOut,
                  child: _buildStatisticsGrid(),
                ),
                SizedBox(height: 16.h),
                
                // Top Categorias
                AnimatedOpacity(
                  opacity: controller.showInsights.value ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeInOut,
                  child: _buildTopCategories(),
                ),
                SizedBox(height: 16.h),
                
                // Insights Contextuais (se disponível)
                if (controller.contextualInsights.isNotEmpty)
                  AnimatedOpacity(
                    opacity: controller.showRecommendations.value ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeInOut,
                    child: _buildContextualInsightsSection(),
                  ),
                if (controller.contextualInsights.isNotEmpty) SizedBox(height: 16.h),
                
                // Insights e Recomendações Base
                AnimatedOpacity(
                  opacity: controller.showRecommendations.value ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 1300),
                  curve: Curves.easeInOut,
                  child: _buildInsightsSection(),
                ),
                SizedBox(height: 16.h),
                
                // Gamificação (se disponível)
                if (controller.hasGamificationData)
                  AnimatedOpacity(
                    opacity: controller.showGamification.value ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 1400),
                    curve: Curves.easeInOut,
                    child: _buildGamificationSection(),
                  ),
                
                SizedBox(height: 80.h),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.colorSurfaceCard,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.colorBrandPrimary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPeriodButton(ComparisonPeriodType.threeMonths),
          ),
          Expanded(
            child: _buildPeriodButton(ComparisonPeriodType.sixMonths),
          ),
          Expanded(
            child: _buildPeriodButton(ComparisonPeriodType.twelveMonths),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final filterableCategories = controller.filterableCategories;
    if (filterableCategories.isEmpty) return const SizedBox.shrink();

    return Obx(() {
      final selectedCategory = controller.selectedCategory;
      final hasCategoryFilter = controller.hasCategoryFilter;

      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.colorSurfaceCard,
          borderRadius: BorderRadius.circular(12.r),
          border: hasCategoryFilter
              ? Border.all(color: AppColors.colorActionPrimary, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.colorBrandPrimary.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: hasCategoryFilter
                      ? AppColors.colorActionPrimary
                      : AppColors.colorTextMuted,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    hasCategoryFilter
                        ? 'Filtrado por: ${selectedCategory?.name ?? ""}'
                        : 'Filtrar por Categoria',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: hasCategoryFilter
                          ? AppColors.colorTextPrimary
                          : AppColors.colorTextMuted,
                      fontWeight: hasCategoryFilter ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (hasCategoryFilter)
                  GestureDetector(
                    onTap: controller.clearCategoryFilter,
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: AppColors.colorError.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Icon(
                        Icons.close,
                        color: AppColors.colorError,
                        size: 16.sp,
                      ),
                    ),
                  ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: controller.toggleCategoryFilter,
                  child: AnimatedRotation(
                    turns: controller.showCategoryFilter.value ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: AppColors.colorTextMuted,
                      size: 24.sp,
                    ),
                  ),
                ),
              ],
            ),
            
            // Lista de categorias expandível
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    // Opção "Todas"
                    _buildCategoryChip(
                      label: 'Todas',
                      icon: '📊',
                      color: AppColors.colorBrandPrimary,
                      isSelected: !hasCategoryFilter,
                      onTap: () => controller.clearCategoryFilter(),
                    ),
                    // Categorias
                    ...filterableCategories.map((category) {
                      return _buildCategoryChip(
                        label: category.name,
                        icon: category.icon,
                        color: category.color,
                        isSelected: controller.selectedCategoryId.value == category.id,
                        onTap: () => controller.selectCategory(category.id),
                      );
                    }),
                  ],
                ),
              ),
              crossFadeState: controller.showCategoryFilter.value
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCategoryChip({
    required String label,
    required String icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppColors.colorBackgroundPrimary,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? color : AppColors.colorBorderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: TextStyle(fontSize: 14.sp)),
            SizedBox(width: 6.w),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? color : AppColors.colorTextMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(ComparisonPeriodType type) {
    final isSelected = controller.selectedPeriodType.value == type;
    
    return GestureDetector(
      onTap: () => controller.changePeriodType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 14.h),
        margin: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.colorBrandDark : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.colorBrandDark.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              type.emoji,
              style: TextStyle(fontSize: 20.sp),
            ),
            SizedBox(height: 4.h),
            Text(
              type.displayName,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? AppColors.colorTextOnDark : AppColors.colorTextMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    final comparison = controller.currentComparison.value;
    final score = comparison?.insights.score;
    
    if (score == null) return const SizedBox.shrink();
    
    // Usando o helper da camada de apresentação ao invés de parsing de HEX
    final scoreColor = score.gradeColorToken;
    
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor.withOpacity(0.9), scoreColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                score.gradeEmoji,
                style: TextStyle(fontSize: 32.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                'Seu Score',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.colorTextOnDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            score.grade,
            style: TextStyle(
              color: AppColors.colorTextOnDark,
              fontSize: 72.sp,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${score.overallScore.toInt()}/100 pontos',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.colorTextOnDark.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.colorTextOnDark.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreMetric(
                  'Melhoria',
                  score.improvementScore,
                  Icons.trending_up,
                ),
                Container(
                  width: 1,
                  height: 40.h,
                  color: AppColors.colorTextOnDark.withOpacity(0.3),
                ),
                _buildScoreMetric(
                  'Consistência',
                  score.consistencyScore,
                  Icons.timeline,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreMetric(String label, double value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.colorTextOnDark, size: 24.sp),
        SizedBox(height: 8.h),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.colorTextOnDark.withOpacity(0.8),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value.toInt().toString(),
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.colorTextOnDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    // Usa dados filtrados se houver filtro de categoria ativo
    final chartData = controller.hasCategoryFilter 
        ? controller.filteredLineChartData 
        : controller.lineChartData;
    if (chartData.isEmpty) return const SizedBox.shrink();

    // Converte dados do controller para o modelo do widget interativo
    final comparison = controller.currentComparison.value;
    final periods = comparison?.periods ?? [];
    final selectedCategory = controller.selectedCategory;
    
    final chartPoints = chartData.asMap().entries.map((entry) {
      final period = entry.key < periods.length ? periods[entry.key] : null;
      return ChartPointData(
        label: entry.value['period'] as String,
        fullLabel: period?.periodName ?? entry.value['period'] as String,
        value: (entry.value['amount'] as num).toDouble(),
        date: period?.startDate,
        metadata: {
          'transactionCount': period?.transactionCount,
          'topCategory': period?.topCategory,
          'averagePerDay': period?.averagePerDay,
        },
      );
    }).toList();

    // Título dinâmico baseado no filtro
    final chartTitle = controller.hasCategoryFilter
        ? 'Evolução: ${selectedCategory?.name ?? ""}'
        : 'Evolução de Gastos';

    // Cor dinâmica baseada na categoria selecionada
    final chartColor = controller.hasCategoryFilter && selectedCategory != null
        ? selectedCategory.color
        : null;

    return InteractiveLineChart(
      data: chartPoints,
      title: chartTitle,
      titleIcon: Icons.show_chart,
      height: 200.h,
      showGrid: true,
      showDots: true,
      showArea: true,
      enableTouchInteraction: true,
      lineColor: chartColor,
      areaColor: chartColor,
      onPointTap: (point, index) {
        // Feedback ao tocar em um ponto
        Get.snackbar(
          point.fullLabel,
          'R\$ ${point.value.toStringAsFixed(2)}',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
        );
      },
    );
  }

  Widget _buildStatisticsGrid() {
    // Usa estatísticas filtradas se houver filtro de categoria ativo
    final stats = controller.hasCategoryFilter 
        ? controller.filteredStatistics 
        : controller.statistics;
    final selectedCategory = controller.selectedCategory;
    
    // Título dinâmico
    final statsTitle = controller.hasCategoryFilter && selectedCategory != null
        ? '📊 Estatísticas: ${selectedCategory.name}'
        : '📊 Estatísticas';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          statsTitle,
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.colorTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Média Mensal',
                'R\$ ${stats['average'].toStringAsFixed(2)}',
                Icons.analytics,
                AppColors.colorBrandPrimary,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatCard(
                'Total',
                'R\$ ${stats['total'].toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                AppColors.colorBrandSoft,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Maior Gasto',
                'R\$ ${stats['highest'].toStringAsFixed(2)}',
                Icons.trending_up,
                AppColors.error,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatCard(
                'Variação',
                '${stats['change'] > 0 ? '+' : ''}${stats['change'].toStringAsFixed(1)}%',
                stats['change'] > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                stats['change'] > 0 ? AppColors.error : AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.colorSurfaceCard,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.colorTextMuted,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.colorTextPrimary,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategories() {
    final topCategories = controller.topCategories;
    if (topCategories.isEmpty) return const SizedBox.shrink();

    // Converte os dados do controller para o modelo do widget compartilhado
    final categoryDataList = topCategories
        .map((cat) => TopCategoryData.fromMap(cat))
        .toList();

    return TopCategoriesWidget(
      categories: categoryDataList,
      title: 'Top 5 Categorias',
      titleEmoji: '🏆',
      maxItems: 5,
      showRanking: true,
      showCategoryIcon: true,
      onCategoryTap: (category) {
        // Navegar para detalhes da categoria (implementação futura)
        Get.snackbar(
          category.name,
          'R\$ ${category.amount.toStringAsFixed(2)}',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }

  Widget _buildInsightsSection() {
    final comparison = controller.currentComparison.value;
    if (comparison == null) return const SizedBox.shrink();

    final insights = comparison.insights;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tendência
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.colorActionPrimary.withOpacity(0.2),
                AppColors.colorActionPrimary.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.colorActionPrimary.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Text(
                comparison.trend.emoji,
                style: TextStyle(fontSize: 32.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tendência',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.colorTextMuted,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      comparison.trend.displayName,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.colorTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      comparison.trend.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.colorTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        if (insights.highlights.isNotEmpty) ...[
          SizedBox(height: 24.h),
          Text(
            '💡 Highlights',
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.colorTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          ...insights.highlights.map((highlight) {
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
                      highlight,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.colorTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        
        if (insights.recommendations.isNotEmpty) ...[
          SizedBox(height: 24.h),
          Text(
            '🎯 Recomendações',
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.colorTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          ...insights.recommendations.map((rec) {
            return _buildRecommendationCard(rec);
          }),
        ],
      ],
    );
  }

  Widget _buildRecommendationCard(ComparisonRecommendation rec) {
    Color priorityColor;
    switch (rec.priority) {
      case RecommendationPriority.urgent:
        priorityColor = AppColors.colorError;
        break;
      case RecommendationPriority.high:
        priorityColor = AppColors.colorWarning;
        break;
      case RecommendationPriority.medium:
        priorityColor = AppColors.colorActionPrimary;
        break;
      case RecommendationPriority.low:
        priorityColor = AppColors.colorBrandPrimary;
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.colorSurfaceCard,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: priorityColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
            ),
            child: Row(
              children: [
                Text(rec.priority.emoji, style: TextStyle(fontSize: 20.sp)),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    rec.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.colorTextPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    rec.priority.displayName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: priorityColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.colorTextMuted,
                  ),
                ),
                if (rec.actionText != null) ...[
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle action based on actionData
                        if (rec.actionData?['categoryId'] != null) {
                          // Navigate to category goals
                          Get.toNamed(AppRoutes.financialGoals);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: priorityColor,
                        foregroundColor: AppColors.colorTextOnDark,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(rec.actionText!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                color: AppColors.colorBrandSoft.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 60.sp,
                color: AppColors.colorBrandSoft,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Sem Dados Suficientes',
              textAlign: TextAlign.center,
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.colorTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              controller.emptyStateMessage,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.colorTextMuted,
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.addExpense),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Adicionar Primeiro Gasto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.colorBrandDark,
                foregroundColor: AppColors.colorTextOnDark,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // NOVOS WIDGETS PARA INTEGRAÇÃO INTELIGENTE
  // ============================================

  /// Card de Score Expandido com múltiplas métricas
  Widget _buildEnhancedScoreCard() {
    final enhancedScore = controller.enhancedScore;
    if (enhancedScore == null) return _buildScoreCard();
    
    final scoreColor = enhancedScore.gradeColorToken;
    
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor.withOpacity(0.9), scoreColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header com nota
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                enhancedScore.gradeEmoji,
                style: TextStyle(fontSize: 28.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                'Score Inteligente',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.colorTextOnDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          // Nota e Pontuação
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                enhancedScore.grade,
                style: TextStyle(
                  color: AppColors.colorTextOnDark,
                  fontSize: 56.sp,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              SizedBox(width: 12.w),
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Text(
                  '${enhancedScore.overallScore.toInt()}/100',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.colorTextOnDark.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          
          // Métricas detalhadas
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.colorTextOnDark.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                // Linha 1: Melhoria e Consistência (base)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildEnhancedScoreMetric(
                      'Melhoria',
                      enhancedScore.baseScore.improvementScore,
                      Icons.trending_up,
                    ),
                    Container(
                      width: 1,
                      height: 40.h,
                      color: AppColors.colorTextOnDark.withOpacity(0.3),
                    ),
                    _buildEnhancedScoreMetric(
                      'Consistência',
                      enhancedScore.baseScore.consistencyScore,
                      Icons.timeline,
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Divider(color: AppColors.colorTextOnDark.withOpacity(0.2)),
                SizedBox(height: 12.h),
                // Linha 2: Orçamento e Metas (expandido)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildEnhancedScoreMetric(
                      'Orçamento',
                      enhancedScore.budgetAdherenceScore,
                      Icons.account_balance_wallet,
                    ),
                    Container(
                      width: 1,
                      height: 40.h,
                      color: AppColors.colorTextOnDark.withOpacity(0.3),
                    ),
                    _buildEnhancedScoreMetric(
                      'Metas',
                      enhancedScore.goalPerformanceScore,
                      Icons.flag,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedScoreMetric(String label, double value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.colorTextOnDark, size: 20.sp),
        SizedBox(height: 6.h),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.colorTextOnDark.withOpacity(0.8),
            fontSize: 11.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value.toInt().toString(),
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.colorTextOnDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Seção de Comparação com Orçamento
  Widget _buildBudgetComparisonSection() {
    final budgetData = controller.budgetComparison;
    if (budgetData == null) return const SizedBox.shrink();

    final adherenceColor = ScoreColorHelper.getBudgetAdherenceColor(budgetData.budgetAdherence);
    final isExceeded = budgetData.isExceeded;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.colorSurfaceCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isExceeded ? AppColors.colorError.withOpacity(0.3) : AppColors.colorBorderSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: adherenceColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                isExceeded ? Icons.warning_amber_rounded : Icons.account_balance_wallet,
                color: adherenceColor,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Aderência ao Orçamento',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.colorTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          // Barra de progresso
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'R\$ ${budgetData.totalSpent.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.colorTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'de R\$ ${budgetData.totalBudget.toStringAsFixed(2)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.colorTextMuted,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: (budgetData.budgetAdherence / 100).clamp(0.0, 1.0),
                  backgroundColor: AppColors.colorBackgroundSecondary,
                  valueColor: AlwaysStoppedAnimation<Color>(adherenceColor),
                  minHeight: 8.h,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${budgetData.budgetAdherence.toStringAsFixed(1)}% utilizado',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: adherenceColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isExceeded 
                        ? 'Excedido em R\$ ${(budgetData.totalSpent - budgetData.totalBudget).abs().toStringAsFixed(2)}'
                        : 'Restam R\$ ${budgetData.remainingBudget.toStringAsFixed(2)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isExceeded ? AppColors.colorError : AppColors.colorSuccess,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          // Status das metas
          Row(
            children: [
              Expanded(
                child: _buildBudgetStatusChip(
                  'No caminho certo',
                  budgetData.goalsOnTrack,
                  Icons.check_circle_outline,
                  AppColors.colorSuccess,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildBudgetStatusChip(
                  'Excedidas',
                  budgetData.goalsExceeded,
                  Icons.warning_amber_rounded,
                  AppColors.colorError,
                ),
              ),
            ],
          ),
          
          // Botão para ver metas
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => controller.navigateToGoals(),
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Ver Metas Detalhadas'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.colorBrandPrimary,
                side: BorderSide(color: AppColors.colorBrandPrimary),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStatusChip(String label, int count, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16.sp),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              '$count $label',
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Seção de Insights Contextuais
  Widget _buildContextualInsightsSection() {
    final insights = controller.contextualInsights;
    if (insights.isEmpty) return const SizedBox.shrink();

    // Separar por prioridade
    final highPriority = controller.highPriorityInsights;
    final positiveInsights = controller.positiveInsights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🧠 Insights Inteligentes',
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.colorTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        
        // Insights de alta prioridade primeiro
        if (highPriority.isNotEmpty) ...[
          ...highPriority.take(3).map((insight) => _buildContextualInsightCard(insight)),
        ],
        
        // Insights positivos
        if (positiveInsights.isNotEmpty) ...[
          ...positiveInsights.take(2).map((insight) => _buildContextualInsightCard(insight)),
        ],
        
        // Outros insights (limitado)
        ...insights
            .where((i) => !highPriority.contains(i) && !positiveInsights.contains(i))
            .take(2)
            .map((insight) => _buildContextualInsightCard(insight)),
      ],
    );
  }

  Widget _buildContextualInsightCard(FinancialInsight insight) {
    final priorityColor = _getInsightPriorityColor(insight.priority);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.colorSurfaceCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: priorityColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: priorityColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                insight.type.icon,
                style: TextStyle(fontSize: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  insight.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.colorTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  insight.priority.displayName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: priorityColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          // Descrição
          Text(
            insight.description,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.colorTextMuted,
            ),
          ),
          
          // Ações sugeridas (se houver)
          if (insight.actionSuggestions.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: insight.actionSuggestions.take(2).map((action) {
                return GestureDetector(
                  onTap: () => controller.executeInsightAction(insight),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.colorActionPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppColors.colorActionPrimary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      action,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.colorActionPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Color _getInsightPriorityColor(FinancialInsightPriority priority) {
    switch (priority) {
      case FinancialInsightPriority.urgent:
        return AppColors.colorError;
      case FinancialInsightPriority.high:
        return AppColors.colorWarning;
      case FinancialInsightPriority.medium:
        return AppColors.colorBrandPrimary;
      case FinancialInsightPriority.low:
        return AppColors.colorBrandSoft;
    }
  }

  /// Seção de Gamificação
  Widget _buildGamificationSection() {
    final gamification = controller.gamificationImpact;
    if (gamification == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.colorActionPrimary.withOpacity(0.15),
            AppColors.colorBrandSoft.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.colorActionPrimary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.colorActionPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: AppColors.colorActionPrimary,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conquistas',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.colorTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Baseado na sua análise',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.colorTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Pontos ganhos
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.colorActionPrimary,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      color: AppColors.colorTextOnDark,
                      size: 16.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '+${gamification.pointsEarned}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.colorTextOnDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Badges desbloqueados
          if (gamification.hasUnlockedBadges) ...[
            SizedBox(height: 16.h),
            Text(
              '🎉 Badges Desbloqueados',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.colorTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: gamification.badgesUnlocked.map((badge) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.colorActionPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColors.colorActionPrimary.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        color: AppColors.colorActionPrimary,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        _getBadgeName(badge),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.colorActionPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          
          // Progresso para próximo badge
          if (gamification.nextBadgeId != null && gamification.nextBadgeProgress != null) ...[
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Próximo: ${_getBadgeName(gamification.nextBadgeId!)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.colorTextMuted,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: gamification.nextBadgeProgress!,
                          backgroundColor: AppColors.colorBackgroundSecondary,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.colorActionPrimary),
                          minHeight: 6.h,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  '${(gamification.nextBadgeProgress! * 100).toInt()}%',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.colorActionPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getBadgeName(String badgeId) {
    switch (badgeId) {
      case 'budget_master':
        return 'Mestre do Orçamento';
      case 'all_goals_met':
        return 'Todas Metas Cumpridas';
      case 'financial_excellence':
        return 'Excelência Financeira';
      case 'consistency':
        return 'Consistência';
      case 'improvement':
        return 'Melhoria Contínua';
      default:
        return badgeId.replaceAll('_', ' ').toUpperCase();
    }
  }
}

