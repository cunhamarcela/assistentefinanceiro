import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/cards/app_card.dart';
import '../controllers/enhanced_reports_controller.dart';
import '../../domain/entities/financial_insight.dart';
import '../../domain/entities/financial_goal.dart';

class EnhancedReportsPage extends GetView<EnhancedReportsController> {
  const EnhancedReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grayVeryLight,
      appBar: AppBar(
        title: Text(
          'Relatórios',
          style: AppTextStyles.headingMedium.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.purple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Controles de período
                _buildPeriodControls(),
                const SizedBox(height: AppSpacing.lg),

                // Resumo financeiro
                _buildFinancialSummary(),
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
      margin: const EdgeInsets.all(16),
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
            color: isSelected ? Colors.white : AppColors.grayMedium,
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
          const SizedBox(height: AppSpacing.sm),
          ...insights.take(3).map((insight) => _buildInsightCard(insight)),
        ],
      );
    });
  }

  Widget _buildInsightCard(FinancialInsight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
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
                goal.categoryName,
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
                  IconData(
                    int.parse(category.icon.replaceAll('Icons.', '').split('.')[0], radix: 16),
                    fontFamily: 'MaterialIcons',
                  ),
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
      ),
    );
  }

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
}
