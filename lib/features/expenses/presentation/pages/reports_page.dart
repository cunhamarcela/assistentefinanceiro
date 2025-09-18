import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/charts/insight_chart.dart';
import '../../../../shared/widgets/cards/insight_card.dart';
import '../controllers/reports_controller.dart';
import '../widgets/report_filter_bar.dart';
import '../widgets/report_summary_card.dart';

/// Página de relatórios visuais personalizados
class ReportsPage extends GetView<ReportsController> {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingState();
        }

        return RefreshIndicator(
          onRefresh: controller.refreshReports,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              _buildFilterBar(),
              _buildSummarySection(),
              _buildChartsSection(),
              _buildInsightsSection(),
              _buildRecommendationsSection(),
            ],
          ),
        );
      }),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 1,
      shadowColor: AppColors.divider,
      title: Text(
        'Relatórios',
        style: AppTextStyles.headingSmall.copyWith(
          color: AppColors.textDark,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.share,
            color: AppColors.textDark,
          ),
          onPressed: controller.shareCurrentReport,
        ),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: AppColors.textDark,
          ),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('Exportar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'schedule',
              child: Row(
                children: [
                  Icon(Icons.schedule),
                  SizedBox(width: 8),
                  Text('Agendar'),
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

  Widget _buildFilterBar() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Obx(() => ReportFilterBar(
          selectedPeriod: controller.selectedPeriod.value,
          selectedType: controller.selectedReportType.value,
          onPeriodChanged: controller.changePeriod,
          onTypeChanged: controller.changeReportType,
        )),
      ),
    );
  }

  Widget _buildSummarySection() {
    return SliverToBoxAdapter(
      child: Obx(() {
        final currentReport = controller.currentReport.value;
        if (currentReport == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: ReportSummaryCard(
            report: currentReport,
            onTap: () => controller.showReportDetails(currentReport),
          ),
        );
      }),
    );
  }

  Widget _buildChartsSection() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análise Visual',
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildChartTabs(),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTabs() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            child: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              isScrollable: false,
              tabs: const [
                Tab(text: 'Categorias'),
                Tab(text: 'Tendência'),
                Tab(text: 'Comparação'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 300,
            child: TabBarView(
              children: [
                _buildCategoryChart(),
                _buildTrendChart(),
                _buildComparisonChart(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart() {
    return Obx(() {
      final chartData = controller.categoryChartData;
      return InsightChart.pie(
        data: chartData,
        title: 'Gastos por Categoria',
        subtitle: controller.selectedPeriod.value.displayName,
        onTap: () => controller.showChartDetails('category'),
      );
    });
  }

  Widget _buildTrendChart() {
    return Obx(() {
      final chartData = controller.trendChartData;
      return InsightChart.line(
        data: chartData,
        title: 'Tendência de Gastos',
        subtitle: controller.selectedPeriod.value.displayName,
        onTap: () => controller.showChartDetails('trend'),
      );
    });
  }

  Widget _buildComparisonChart() {
    return Obx(() {
      final chartData = controller.comparisonChartData;
      return InsightChart.bar(
        data: chartData,
        title: 'Comparação Mensal',
        subtitle: 'Últimos 6 meses',
        onTap: () => controller.showChartDetails('comparison'),
      );
    });
  }

  Widget _buildInsightsSection() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Insights Financeiros',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                TextButton(
                  onPressed: controller.showAllInsights,
                  child: Text(
                    'Ver Todos',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Obx(() => _buildInsightsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsList() {
    final insights = controller.currentInsights;
    
    if (insights.isEmpty) {
      return _buildEmptyInsights();
    }

    return Column(
      children: insights.take(3).map((insight) {
        return InsightCard(
          insight: insight,
          onTap: () => controller.showInsightDetails(insight),
          onActionTap: () => controller.handleInsightAction(insight),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyInsights() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(
            Icons.insights,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nenhum insight disponível',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Adicione mais transações para gerar insights',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recomendações',
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Obx(() => _buildRecommendationsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsList() {
    final recommendations = controller.currentRecommendations;
    
    if (recommendations.isEmpty) {
      return _buildEmptyRecommendations();
    }

    return Column(
      children: recommendations.map((recommendation) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                recommendation.title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                recommendation.description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (recommendation.actionText != null) ...[
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton.small(
                    text: recommendation.actionText!,
                    onPressed: () => controller.handleRecommendationAction(recommendation),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyRecommendations() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nenhuma recomendação disponível',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
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
            'Gerando relatórios...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: controller.generateNewReport,
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add_chart, color: Colors.white),
      label: Text(
        'Novo Relatório',
        style: AppTextStyles.button.copyWith(color: Colors.white),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        controller.exportCurrentReport();
        break;
      case 'schedule':
        controller.scheduleReport();
        break;
      case 'settings':
        controller.showReportSettings();
        break;
    }
  }
}
