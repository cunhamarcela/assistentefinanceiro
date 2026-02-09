import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../controllers/enhanced_reports_controller.dart';
import '../widgets/excess_alert_card.dart';
import '../widgets/ai_analysis_section.dart';
import '../../data/services/quick_analysis_service.dart';

/// Logger helper para QuickFinancialSummaryPage
void _logSummaryPage(String message, {String level = 'INFO'}) {
  final prefix = switch (level) {
    'ERROR' => '❌ [QuickSummaryPage]',
    'WARNING' => '⚠️ [QuickSummaryPage]',
    'SUCCESS' => '✅ [QuickSummaryPage]',
    'RENDER' => '🎨 [QuickSummaryPage]',
    'DATA' => '📊 [QuickSummaryPage]',
    _ => '📋 [QuickSummaryPage]',
  };
  debugPrint('$prefix $message');
}

/// Tokens utilizados:
/// - Background: colorBackgroundPrimary
/// - Card: colorSurfaceCard
/// - Header gradient: colorBrandPrimary -> colorBrandDark
/// - Texto: colorTextPrimary, colorTextSecondary, colorTextOnDark
/// - Cores de estado: colorSuccess, colorWarning, colorError

/// Página de Resumo Financeiro em 1 Tela
class QuickFinancialSummaryPage extends GetView<EnhancedReportsController> {
  const QuickFinancialSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    _logSummaryPage('═══════════════════════════════════════════════════════════════');
    _logSummaryPage('BUILD - QuickFinancialSummaryPage', level: 'RENDER');
    _logSummaryPage('═══════════════════════════════════════════════════════════════');
    
    return Scaffold(
      backgroundColor: AppColors.colorBackgroundPrimary,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Obx(() {
              _logSummaryPage('Obx rebuild - isLoading: ${controller.isLoading.value}', level: 'RENDER');
              if (controller.isLoading.value) {
                _logSummaryPage('   → Exibindo estado de loading', level: 'RENDER');
                return _buildLoadingState();
              }
              _logSummaryPage('   → Exibindo conteúdo principal', level: 'RENDER');
              return _buildContent();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.colorBrandDark,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.colorTextOnDark),
        onPressed: () => Get.back(),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.share, color: AppColors.colorTextOnDark),
          onPressed: _shareReport,
        ),
        IconButton(
          icon: Icon(Icons.refresh, color: AppColors.colorTextOnDark),
          onPressed: () => controller.refreshReports(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.colorBrandPrimary, AppColors.colorBrandDark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo Financeiro',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.colorTextOnDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                    controller.periodTitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.colorTextOnDark.withOpacity(0.8),
                    ),
                  )),
                  const SizedBox(height: AppSpacing.md),
                  _buildHeaderStats(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStats() {
    return Obx(() {
      final totalSpent = controller.totalSpent.value;
      final budget = controller.totalBudget;
      final remaining = budget - totalSpent;
      final percentageUsed = controller.budgetPercentageUsed;

      return Row(
        children: [
          Expanded(
            child: _buildHeaderStatItem(
              'Total Gasto',
              'R\$ ${totalSpent.toStringAsFixed(2)}',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.colorTextOnDark.withOpacity(0.3),
          ),
          Expanded(
            child: _buildHeaderStatItem(
              'Orçamento',
              'R\$ ${budget.toStringAsFixed(2)}',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.colorTextOnDark.withOpacity(0.3),
          ),
          Expanded(
            child: _buildHeaderStatItem(
              remaining >= 0 ? 'Disponível' : 'Excesso',
              'R\$ ${remaining.abs().toStringAsFixed(2)}',
              color: remaining >= 0 
                  ? AppColors.colorSuccess.withOpacity(0.9)
                  : AppColors.colorError.withOpacity(0.9),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildHeaderStatItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.colorTextOnDark.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: color ?? AppColors.colorTextOnDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.colorBrandSoft,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Gerando resumo...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.colorTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    _logSummaryPage('───────────────────────────────────────────────────────────────');
    _logSummaryPage('_buildContent() - Montando seções', level: 'RENDER');
    _logSummaryPage('───────────────────────────────────────────────────────────────');
    
    _logSummaryPage('📊 Dados do controller:', level: 'DATA');
    _logSummaryPage('   - Total gasto: R\$ ${controller.totalSpent.value.toStringAsFixed(2)}', level: 'DATA');
    _logSummaryPage('   - Orçamento: R\$ ${controller.totalBudget.toStringAsFixed(2)}', level: 'DATA');
    _logSummaryPage('   - % usado: ${controller.budgetPercentageUsed.toStringAsFixed(1)}%', level: 'DATA');
    _logSummaryPage('   - Categorias dominantes: ${controller.dominantCategories.length}', level: 'DATA');
    _logSummaryPage('   - Alertas: ${controller.allAlertCategories.length}', level: 'DATA');
    _logSummaryPage('   - Texto IA: ${controller.aiAnalysisText.value.length} chars', level: 'DATA');
    
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progresso Visual do Orçamento
          _buildBudgetProgressCard(),
          const SizedBox(height: AppSpacing.lg),

          // Categorias Dominantes
          _buildDominantCategoriesSection(),
          const SizedBox(height: AppSpacing.lg),

          // Alertas de Excesso
          _buildExcessAlertsSection(),

          // Análise da IA
          _buildAIAnalysisSection(),
          const SizedBox(height: AppSpacing.lg),

          // Ações Rápidas
          _buildQuickActions(),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildBudgetProgressCard() {
    return Obx(() {
      final percentageUsed = controller.budgetPercentageUsed;
      final progressColor = percentageUsed > 100
          ? AppColors.colorError
          : percentageUsed > 80
              ? AppColors.colorWarning
              : AppColors.colorSuccess;

      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.colorSurfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.colorBorderSubtle),
          boxShadow: [
            BoxShadow(
              color: AppColors.colorBrandPrimary.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Uso do Orçamento',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.colorTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${percentageUsed.round()}%',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: progressColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (percentageUsed / 100).clamp(0.0, 1.0),
                backgroundColor: AppColors.colorBorderSubtle,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _getBudgetStatusMessage(percentageUsed),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.colorTextMuted,
              ),
            ),
          ],
        ),
      );
    });
  }

  String _getBudgetStatusMessage(double percentageUsed) {
    if (percentageUsed > 100) {
      return '⚠️ Você ultrapassou o orçamento! Tente reduzir os gastos.';
    } else if (percentageUsed > 80) {
      return '⚡ Atenção! Você está próximo do limite do orçamento.';
    } else if (percentageUsed > 50) {
      return '📊 Você está na metade do orçamento. Continue monitorando.';
    } else {
      return '✅ Excelente! Você está controlando bem seus gastos.';
    }
  }

  Widget _buildDominantCategoriesSection() {
    return Obx(() {
      final categories = controller.dominantCategories;

      if (categories.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart,
                color: AppColors.colorBrandSoft,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Categorias Dominantes',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.colorTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...categories.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            return _buildDominantCategoryItem(category, index);
          }),
        ],
      );
    });
  }

  Widget _buildDominantCategoryItem(DominantCategoryData category, int index) {
    final colors = [
      AppColors.colorBrandPrimary,
      AppColors.colorBrandSoft,
      AppColors.colorBackgroundSecondary,
    ];
    final color = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.colorSurfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.colorBorderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.categoryName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.colorTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${category.transactionCount} transações',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.colorTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'R\$ ${category.amount.toStringAsFixed(2)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.colorTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${category.percentage.round()}%',
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExcessAlertsSection() {
    return Obx(() {
      final alerts = controller.allAlertCategories;

      if (alerts.isEmpty) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.colorSuccess.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.colorSuccess.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppColors.colorSuccess,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tudo sob controle! ✨',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.colorTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Você está dentro do orçamento em todas as categorias.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.colorTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcessAlertsList(
            alerts: alerts,
            showTitle: true,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      );
    });
  }

  Widget _buildAIAnalysisSection() {
    return Obx(() {
      final analysisText = controller.aiAnalysisText.value;

      if (analysisText.isEmpty) {
        return const SizedBox.shrink();
      }

      return AIAnalysisSection(
        title: 'Análise Inteligente',
        analysisText: analysisText,
        suggestions: controller.aiSuggestions,
        isLoading: controller.isLoadingAnalysis.value,
        onRefresh: () => controller.refreshAIAnalysis(),
      );
    });
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.colorTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.add_circle_outline,
                label: 'Adicionar Gasto',
                color: AppColors.colorActionPrimary,
                onTap: () => Get.toNamed('/add-expense'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildActionButton(
                icon: Icons.flag_outlined,
                label: 'Definir Metas',
                color: AppColors.colorBrandSoft,
                onTap: () => Get.toNamed('/financial-goals'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.chat_outlined,
                label: 'Falar com IA',
                color: AppColors.colorBrandPrimary,
                onTap: () => Get.toNamed('/chat'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildActionButton(
                icon: Icons.bar_chart,
                label: 'Ver Relatórios',
                color: AppColors.colorInfo,
                onTap: () => Get.back(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareReport() {
    // TODO: Implementar compartilhamento de relatório
    Get.snackbar(
      'Em breve',
      'Compartilhamento de relatórios será implementado em breve!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.colorInfo.withOpacity(0.9),
      colorText: AppColors.colorTextOnDark,
    );
  }
}

