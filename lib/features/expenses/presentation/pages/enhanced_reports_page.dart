import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/cards/app_card.dart';
import '../controllers/enhanced_reports_controller.dart';
import '../../domain/entities/financial_insight.dart';
import '../../domain/entities/financial_goal.dart';
import '../widgets/quick_analysis_card.dart';
import '../widgets/excess_alert_card.dart';
import '../widgets/ai_analysis_section.dart';
import '../../../monetization/domain/entities/usage_limit.dart';
import '../../../monetization/presentation/widgets/usage_limit_widget.dart';

/// Logger helper para EnhancedReportsPage
void _logReportsPage(String message, {String level = 'INFO'}) {
  final prefix = switch (level) {
    'ERROR' => '❌ [ReportsPage]',
    'WARNING' => '⚠️ [ReportsPage]',
    'SUCCESS' => '✅ [ReportsPage]',
    'RENDER' => '🎨 [ReportsPage]',
    'TAP' => '👆 [ReportsPage]',
    'DATA' => '📊 [ReportsPage]',
    _ => '📋 [ReportsPage]',
  };
  debugPrint('$prefix $message');
}

class EnhancedReportsPage extends GetView<EnhancedReportsController> {
  const EnhancedReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    _logReportsPage('═══════════════════════════════════════════════════════════════');
    _logReportsPage('BUILD - EnhancedReportsPage', level: 'RENDER');
    _logReportsPage('═══════════════════════════════════════════════════════════════');
    
    // Listener para mostrar dialog de limite atingido
    ever(controller.showInsightsLimitDialog, (show) {
      if (show) {
        _showInsightsLimitReachedDialog(context);
        controller.dismissInsightsLimitDialog();
      }
    });
    
    return Scaffold(
      backgroundColor: AppColors.grayVeryLight,
      appBar: AppBar(
        title: Text(
          'Relatórios',
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.colorTextOnDark,
          ),
        ),
        backgroundColor: AppColors.purple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.colorTextOnDark),
          onPressed: () => Get.back(),
        ),
        actions: [
          // Indicador de uso de Insights IA
          _buildInsightsUsageIndicator(),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.colorTextOnDark),
            onPressed: () => Get.toNamed(AppRoutes.financialGoals),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.purple),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshReports,
          color: AppColors.purple,
          backgroundColor: AppColors.colorSurfaceCard,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner de limite de Insights (quando próximo/atingido)
                _buildInsightsLimitBanner(),
                
                // Quick Analysis Cards - Análise Rápida
                _buildQuickAnalysisSection(),
                const SizedBox(height: AppSpacing.lg),

                // Controles de período
                _buildPeriodControls(),
                const SizedBox(height: AppSpacing.lg),

                // Resumo financeiro
                _buildFinancialSummary(),
                const SizedBox(height: AppSpacing.lg),

                // Alertas de Excesso
                _buildExcessAlertsSection(),

                // Análise da IA
                _buildAIAnalysisSection(),
                const SizedBox(height: AppSpacing.lg),

                // Insights financeiros
                _buildInsightsSection(),
                const SizedBox(height: AppSpacing.lg),

                // Progresso das metas
                _buildGoalsProgress(),
                const SizedBox(height: AppSpacing.lg),

                // Gastos por categoria
                _buildCategoryBreakdown(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPeriodControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.colorSurfaceCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: AppColors.grayDark, size: 28),
                  onPressed: controller.previousPeriod,
                ),
                Expanded(
                  child: Text(
                    controller.periodTitle,
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.grayDark,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: AppColors.grayDark, size: 28),
                  onPressed: controller.nextPeriod,
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.grayVeryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildPeriodButton('Semana', 'week'),
                ),
                Expanded(
                  child: _buildPeriodButton('Mês', 'month'),
                ),
                Expanded(
                  child: _buildPeriodButton('Ano', 'year'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
    final isSelected = controller.selectedPeriod.value == period;
    return GestureDetector(
      onTap: () => controller.changePeriod(period),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.purple : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.purple.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? AppColors.colorTextOnDark : AppColors.grayMedium,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Obx(() {
      final totalSpent = controller.totalSpent.value;
      final budgetRemaining = controller.budgetRemaining.value;
      final progress = controller.getBudgetProgress();
      final progressColor = controller.getBudgetProgressColor();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lilac.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Resumo Financeiro',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.grayDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Total gasto
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Gasto',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'R\$ ${totalSpent.toStringAsFixed(2)}',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            if (controller.hasFinancialProfile) ...[
              const SizedBox(height: AppSpacing.sm),
              
              // Orçamento restante
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    budgetRemaining >= 0 ? 'Orçamento Restante' : 'Excesso no Orçamento',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'R\$ ${budgetRemaining.abs().toStringAsFixed(2)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: budgetRemaining >= 0 ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Barra de progresso do orçamento
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progresso do Orçamento',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: progressColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildInsightsSection() {
    return Obx(() {
      final insights = controller.insights;
      
      if (insights.isEmpty) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 48,
                color: AppColors.lilac,
              ),
              const SizedBox(height: 16),
              Text(
                'Insights Financeiros',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.grayDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                controller.noDataMessage,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grayLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: AppColors.accent,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Insights Personalizados com IA 🤖',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Baseado nas suas respostas do onboarding, nossa IA já está preparando dicas exclusivas para você!',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (!controller.hasFinancialProfile) ...[
                const SizedBox(height: AppSpacing.md),
                AppButton.outlined(
                  text: 'Configurar Perfil',
                  onPressed: () => Get.toNamed(AppRoutes.financialGoals),
                ),
              ],
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Insights Financeiros',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Mostrar todos os insights
                  },
                  child: Text(
                    'Ver Todos',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.purple,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...insights.take(3).map((insight) => _buildInsightCard(insight)),
        ],
      );
    });
  }

  Widget _buildInsightCard(FinancialInsight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm, left: 16, right: 16),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  insight.type.icon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    insight.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(insight.priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    insight.priority.displayName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _getPriorityColor(insight.priority),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              insight.description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsProgress() {
    return Obx(() {
      final goals = controller.financialGoals;
      
      if (goals.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Progresso das Metas',
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.grayDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...goals.take(5).map((goal) => _buildGoalProgressCard(goal)),
        ],
      );
    });
  }

  Widget _buildGoalProgressCard(FinancialGoal goal) {
    final progress = goal.progressPercentage.clamp(0.0, 1.0);
    final progressColor = _getGoalStatusColor(goal.status);
    
    // Obter o nome real da categoria, mesmo se o goal.categoryName estiver genérico
    final category = controller.getCategoryById(goal.categoryId);
    final displayName = category?.name ?? _getCategoryNameFromId(goal.categoryId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 3),
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
                displayName,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grayDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'R\$ ${goal.currentSpent.toStringAsFixed(2)} / R\$ ${goal.monthlyLimit.toStringAsFixed(2)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grayLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${(progress * 100).round()}%',
                style: AppTextStyles.bodySmall.copyWith(
                  color: progressColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    return Obx(() {
      final categorySpending = controller.categorySpending;
      
      if (categorySpending.isEmpty) {
        return const SizedBox.shrink();
      }

      // Ordenar por valor gasto
      final sortedEntries = categorySpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Gastos por Categoria',
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.grayDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...sortedEntries.take(5).map((entry) => _buildCategoryItem(entry)),
        ],
      );
    });
  }

  Widget _buildCategoryItem(MapEntry<String, double> entry) {
    final category = controller.getCategoryById(entry.key);
    final categoryName = category?.name ?? 'Categoria';
    final amount = entry.value;
    final percentage = controller.totalSpent.value > 0 
        ? (amount / controller.totalSpent.value * 100).round()
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (category != null) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category.iconData,
                color: category.color,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$percentage% do total',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'R\$ ${amount.toStringAsFixed(2)}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // NOVAS SEÇÕES - Quick Analysis, Excess Alerts, AI Analysis
  // ============================================================================

  /// Seção de Análise Rápida com cards de ação
  Widget _buildQuickAnalysisSection() {
    _logReportsPage('_buildQuickAnalysisSection()', level: 'RENDER');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: AppColors.colorBrandSoft,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Análise Rápida',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.colorTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                SizedBox(
                  width: 280,
                  child: QuickAnalysisCard(
                    icon: Icons.analytics,
                    title: 'Analisar gastos do mês',
                    subtitle: 'Ver resumo detalhado',
                    iconColor: AppColors.colorBrandSoft,
                    onTap: () {
                      _logReportsPage('AÇÃO: Analisar gastos do mês', level: 'TAP');
                      _showMonthAnalysisBottomSheet();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 280,
                  child: QuickAnalysisCard(
                    icon: Icons.warning_amber,
                    title: 'Onde estou gastando demais?',
                    subtitle: 'Identificar excessos',
                    iconColor: AppColors.colorWarning,
                    onTap: () {
                      _logReportsPage('AÇÃO: Onde estou gastando demais?', level: 'TAP');
                      _showExcessAnalysisBottomSheet();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 280,
                  child: QuickAnalysisCard(
                    icon: Icons.dashboard,
                    title: 'Resumo em 1 tela',
                    subtitle: 'Visão geral completa',
                    iconColor: AppColors.colorActionPrimary,
                    isHighlighted: true,
                    onTap: () {
                      _logReportsPage('AÇÃO: Navegando para Resumo em 1 tela', level: 'TAP');
                      Get.toNamed(AppRoutes.quickSummary);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Seção de Alertas de Excesso
  Widget _buildExcessAlertsSection() {
    return Obx(() {
      final alerts = controller.allAlertCategories;
      
      if (alerts.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcessAlertsList(
              alerts: alerts,
              showTitle: true,
              onAlertTap: (alert) => _showCategoryDetailBottomSheet(alert),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      );
    });
  }

  /// Seção de Análise da IA
  Widget _buildAIAnalysisSection() {
    return Obx(() {
      final analysisText = controller.aiAnalysisText.value;
      
      if (analysisText.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AIAnalysisSection(
          title: 'Análise da IA',
          analysisText: analysisText,
          suggestions: controller.aiSuggestions,
          isLoading: controller.isLoadingAnalysis.value,
          onRefresh: () => controller.refreshAIAnalysis(),
        ),
      );
    });
  }

  /// Bottom sheet com análise detalhada do mês
  void _showMonthAnalysisBottomSheet() {
    _logReportsPage('═══════════════════════════════════════════════════════════════');
    _logReportsPage('ABRINDO BOTTOM SHEET: Análise do Mês', level: 'RENDER');
    _logReportsPage('═══════════════════════════════════════════════════════════════');
    _logReportsPage('   Total Gasto: R\$ ${controller.totalSpent.value.toStringAsFixed(2)}', level: 'DATA');
    _logReportsPage('   Orçamento: R\$ ${controller.totalBudget.toStringAsFixed(2)}', level: 'DATA');
    _logReportsPage('   % Usado: ${controller.budgetPercentageUsed.toStringAsFixed(1)}%', level: 'DATA');
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.colorSurfaceCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.colorBorderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: AppColors.colorBrandSoft,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Análise do Mês',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.colorTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Obx(() => _buildSummaryStats()),
            const SizedBox(height: AppSpacing.lg),
            Obx(() {
              final text = controller.getQuickSummaryText();
              return AIAnalysisCompact(
                text: text,
                onTap: () {
                  Get.back();
                  Get.toNamed(AppRoutes.quickSummary);
                },
              );
            }),
            const SizedBox(height: AppSpacing.lg),
            AppButton.filled(
              text: 'Ver Resumo Completo',
              onPressed: () {
                Get.back();
                Get.toNamed(AppRoutes.quickSummary);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// Widget de estatísticas resumidas
  Widget _buildSummaryStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Gasto',
            'R\$ ${controller.totalSpent.value.toStringAsFixed(2)}',
            AppColors.colorBrandPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatCard(
            'Orçamento',
            'R\$ ${controller.totalBudget.toStringAsFixed(2)}',
            AppColors.colorBrandSoft,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatCard(
            'Usado',
            '${controller.budgetPercentageUsed.round()}%',
            controller.budgetPercentageUsed > 100 
                ? AppColors.colorError 
                : controller.budgetPercentageUsed > 80 
                    ? AppColors.colorWarning 
                    : AppColors.colorSuccess,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.colorTextMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Bottom sheet com análise de excesso
  void _showExcessAnalysisBottomSheet() {
    _logReportsPage('═══════════════════════════════════════════════════════════════');
    _logReportsPage('ABRINDO BOTTOM SHEET: Onde Estou Gastando Demais?', level: 'RENDER');
    _logReportsPage('═══════════════════════════════════════════════════════════════');
    _logReportsPage('   Alertas totais: ${controller.allAlertCategories.length}', level: 'DATA');
    _logReportsPage('   Categorias excedidas: ${controller.exceededCategories.length}', level: 'DATA');
    _logReportsPage('   Categorias em alerta: ${controller.warningCategories.length}', level: 'DATA');
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(Get.context!).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: AppColors.colorSurfaceCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.colorBorderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: AppColors.colorWarning,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Onde Estou Gastando Demais?',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.colorTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: SingleChildScrollView(
                child: Obx(() {
                  final alerts = controller.allAlertCategories;
                  
                  if (alerts.isEmpty) {
                    return _buildNoExcessMessage();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcessAlertsList(
                        alerts: alerts,
                        showTitle: false,
                        onAlertTap: (alert) {
                          Get.back();
                          _showCategoryDetailBottomSheet(alert);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AIAnalysisSection(
                        title: 'Análise Detalhada',
                        analysisText: controller.getExcessAnalysisText(),
                        isLoading: false,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildNoExcessMessage() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: AppColors.colorSuccess,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Parabéns! 🎉',
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.colorTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Você está dentro do orçamento em todas as categorias. Continue assim!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.colorTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Bottom sheet com detalhes de uma categoria
  void _showCategoryDetailBottomSheet(ExcessCategoryData alert) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.colorSurfaceCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.colorBorderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: alert.categoryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    alert.categoryIcon,
                    color: alert.categoryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.categoryName,
                        style: AppTextStyles.headingMedium.copyWith(
                          color: AppColors.colorTextPrimary,
                        ),
                      ),
                      Text(
                        alert.isExceeded ? 'Orçamento excedido' : 'Atenção necessária',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: alert.isExceeded 
                              ? AppColors.colorError 
                              : AppColors.colorWarning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildCategoryStats(alert),
            const SizedBox(height: AppSpacing.lg),
            if (alert.isExceeded)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.colorError.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.colorError,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tente reduzir os gastos nesta categoria nos próximos dias.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.colorTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.outlined(
              text: 'Ver Gastos desta Categoria',
              onPressed: () {
                Get.back();
                // TODO: Navegar para lista de gastos filtrada por categoria
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildCategoryStats(ExcessCategoryData alert) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Gasto',
                'R\$ ${alert.currentSpent.toStringAsFixed(2)}',
                alert.isExceeded ? AppColors.colorError : AppColors.colorWarning,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                'Limite',
                'R\$ ${alert.budgetLimit.toStringAsFixed(2)}',
                AppColors.colorBrandSoft,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                'Usado',
                '${alert.percentageUsed.round()}%',
                alert.isExceeded ? AppColors.colorError : AppColors.colorWarning,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (alert.percentageUsed / 100).clamp(0.0, 1.0),
            backgroundColor: AppColors.colorBorderSubtle,
            valueColor: AlwaysStoppedAnimation<Color>(
              alert.isExceeded ? AppColors.colorError : AppColors.colorWarning,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // MONETIZAÇÃO - UI de Limite de Insights IA
  // ============================================================================
  
  /// Indicador de uso de Insights IA no AppBar
  Widget _buildInsightsUsageIndicator() {
    return Obx(() {
      final hasUnlimited = controller.hasUnlimitedInsights.value;
      final limit = controller.insightsUsageLimit.value;
      
      // Se não tem dados de limite, não mostra
      if (limit == null && !hasUnlimited) {
        return const SizedBox.shrink();
      }
      
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: GestureDetector(
          onTap: () {
            if (!hasUnlimited && (limit?.isNearLimit ?? false)) {
              _showInsightsUnlockPrompt();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getInsightsIndicatorColor(hasUnlimited, limit).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                  Icon(
                  _getInsightsIndicatorIcon(hasUnlimited, limit),
                  size: 14,
                  color: AppColors.colorTextOnDark,
                ),
                const SizedBox(width: 4),
                Text(
                  controller.insightsUsageDisplayText,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.colorTextOnDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
  
  Color _getInsightsIndicatorColor(bool hasUnlimited, UsageLimit? limit) {
    if (hasUnlimited) return AppColors.colorSuccess;
    if (limit?.isLimitReached ?? false) return AppColors.colorError;
    if (limit?.isNearLimit ?? false) return AppColors.colorWarning;
    return AppColors.colorTextOnDark;
  }
  
  IconData _getInsightsIndicatorIcon(bool hasUnlimited, UsageLimit? limit) {
    if (hasUnlimited) return Icons.star_rounded;
    if (limit?.isLimitReached ?? false) return Icons.lock_rounded;
    if (limit?.isNearLimit ?? false) return Icons.warning_amber_rounded;
    return Icons.lightbulb_outline_rounded;
  }
  
  /// Banner de limite de insights (quando próximo/atingido)
  Widget _buildInsightsLimitBanner() {
    return Obx(() {
      if (!controller.shouldShowInsightsLimitWarning) {
        return const SizedBox.shrink();
      }
      
      final limit = controller.insightsUsageLimit.value;
      final isLastUse = limit?.isLastUse ?? false;
      
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.colorBrandPrimary,
              AppColors.colorBrandDark,
            ],
          ),
        ),
        child: Row(
          children: [
            Icon(
              isLastUse ? Icons.warning_amber_rounded : Icons.lightbulb_outline,
              color: AppColors.colorTextOnDark,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isLastUse 
                    ? '⚠️ Último insight gratuito! Desbloqueie 24h de análises ilimitadas.'
                    : '${limit?.remainingToday ?? 0} insights restantes hoje',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.colorTextOnDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () => controller.showAdToUnlockInsights(),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.colorActionPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
              ),
              child: Text(
                '🎬 Desbloquear',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.colorTextOnDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
  
  /// Dialog quando limite de insights é atingido
  void _showInsightsLimitReachedDialog(BuildContext context) {
    // Rastreia exibição do prompt de anúncio
    AnalyticsService.instance.trackAdPromptShown(featureType: 'aiInsights');
    
    LimitReachedDialog.show(
      context,
      featureType: FeatureType.aiInsights,
      onWatchAd: () {
        controller.showAdToUnlockInsights();
      },
    );
  }
  
  /// Prompt para desbloquear insights
  void _showInsightsUnlockPrompt() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.colorSurfaceCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.colorBorderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.auto_awesome,
              size: 48,
              color: AppColors.colorBrandPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              'Desbloqueie Insights IA',
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.colorTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Assista um anúncio curto e ganhe 24 horas de análises financeiras ilimitadas com IA!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.colorTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.back();
                  controller.showAdToUnlockInsights();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.colorActionPrimary,
                  foregroundColor: AppColors.colorTextOnDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.play_circle_filled_rounded),
                label: const Text(
                  'Assistir Anúncio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'Agora não',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.colorTextMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // MÉTODOS AUXILIARES
  // ============================================================================

  Color _getPriorityColor(FinancialInsightPriority priority) {
    switch (priority) {
      case FinancialInsightPriority.urgent:
        return AppColors.error;
      case FinancialInsightPriority.high:
        return AppColors.warning;
      case FinancialInsightPriority.medium:
        return AppColors.accent;
      case FinancialInsightPriority.low:
        return AppColors.purple;
    }
  }

  Color _getGoalStatusColor(FinancialGoalStatus status) {
    switch (status) {
      case FinancialGoalStatus.good:
        return AppColors.success;
      case FinancialGoalStatus.onTrack:
        return AppColors.purple;
      case FinancialGoalStatus.warning:
        return AppColors.warning;
      case FinancialGoalStatus.exceeded:
        return AppColors.error;
      case FinancialGoalStatus.inactive:
        return AppColors.textSecondary;
    }
  }
  
  /// Obtém o nome da categoria a partir do ID base (fallback)
  String _getCategoryNameFromId(String categoryId) {
    final defaultIds = [
      'alimentacao', 'transporte', 'saude', 'contas', 'lazer',
      'casa', 'educacao', 'roupas', 'tecnologia', 'pets', 'outros', 'investimentos'
    ];
    
    String baseId = categoryId;
    for (final id in defaultIds) {
      if (categoryId == id || categoryId.startsWith('${id}_')) {
        baseId = id;
        break;
      }
    }
    
    final categoryNames = {
      'alimentacao': 'Alimentação',
      'transporte': 'Transporte',
      'saude': 'Saúde',
      'contas': 'Contas',
      'lazer': 'Lazer',
      'casa': 'Casa',
      'educacao': 'Educação',
      'roupas': 'Roupas e Beleza',
      'tecnologia': 'Tecnologia',
      'pets': 'Pets',
      'outros': 'Outros',
      'investimentos': 'Investimentos',
    };
    
    return categoryNames[baseId] ?? 'Categoria';
  }
}
