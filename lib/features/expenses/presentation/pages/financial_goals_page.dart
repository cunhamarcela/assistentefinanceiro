import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/cards/app_card.dart';
import '../controllers/financial_goals_controller.dart';
import '../../domain/entities/category.dart';

class FinancialGoalsPage extends GetView<FinancialGoalsController> {
  const FinancialGoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Metas Financeiras',
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seção de Renda Mensal
              _buildIncomeSection(),
              const SizedBox(height: AppSpacing.lg),

              // Seção de Orçamento Total
              _buildTotalBudgetSection(),
              const SizedBox(height: AppSpacing.lg),

              // Seção de Orçamento por Categoria
              _buildCategoryBudgetsSection(),
              const SizedBox(height: AppSpacing.lg),

              // Resumo do Orçamento
              _buildBudgetSummary(),
              const SizedBox(height: AppSpacing.xl),

              // Botão Salvar
              _buildSaveButton(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildIncomeSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Renda Mensal',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: controller.incomeController,
            label: 'Quanto você ganha por mês?',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.attach_money,
            onChanged: (value) => controller.updateIncome(value),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Informe sua renda líquida mensal para calcularmos seus insights',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBudgetSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Orçamento Total',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: controller.totalBudgetController,
            label: 'Quanto você planeja gastar por mês?',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.calculate,
            onChanged: (value) => controller.updateTotalBudget(value),
          ),
          const SizedBox(height: AppSpacing.xs),
          Obx(() {
            final income = controller.monthlyIncome.value;
            final budget = controller.totalBudget.value;
            if (income > 0 && budget > 0) {
              final percentage = (budget / income * 100).round();
              final remaining = income - budget;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$percentage% da sua renda',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: percentage > 80 ? AppColors.error : AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Sobrarão R\$ ${remaining.toStringAsFixed(2)} para poupança/investimentos',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryBudgetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.category,
                color: AppColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Orçamento por Categoria',
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Defina quanto você planeja gastar em cada categoria',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Obx(() {
          final categories = controller.categories;
          if (categories.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return Column(
            children: categories.map((category) => _buildCategoryBudgetItem(category)).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildCategoryBudgetItem(ExpenseCategory category) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Obx(() {
                        final budget = controller.categoryBudgets[category.id] ?? 0.0;
                        final totalBudget = controller.totalBudget.value;
                        if (totalBudget > 0 && budget > 0) {
                          final percentage = (budget / totalBudget * 100).round();
                          return Text(
                            '$percentage% do orçamento total',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: controller.getCategoryController(category.id),
              label: 'Orçamento mensal',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.attach_money,
              onChanged: (value) => controller.updateCategoryBudget(category.id, value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSummary() {
    return Obx(() {
      final totalBudget = controller.totalBudget.value;
      final allocatedBudget = controller.categoryBudgets.values.fold(0.0, (sum, value) => sum + value);
      final unallocated = totalBudget - allocatedBudget;
      final isBalanced = unallocated.abs() < 0.01;

      if (totalBudget <= 0) return const SizedBox.shrink();

      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isBalanced ? Icons.check_circle : Icons.warning,
                  color: isBalanced ? AppColors.success : AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Resumo do Orçamento',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSummaryRow('Orçamento Total', totalBudget, AppColors.textDark),
            _buildSummaryRow('Alocado em Categorias', allocatedBudget, AppColors.textSecondary),
            const Divider(color: AppColors.divider),
            _buildSummaryRow(
              unallocated >= 0 ? 'Não Alocado' : 'Excesso',
              unallocated.abs(),
              unallocated >= 0 ? AppColors.success : AppColors.error,
            ),
            if (!isBalanced) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: (unallocated >= 0 ? AppColors.success : AppColors.error).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  unallocated >= 0
                      ? 'Você ainda tem R\$ ${unallocated.toStringAsFixed(2)} para alocar'
                      : 'Você alocou R\$ ${unallocated.abs().toStringAsFixed(2)} a mais que o orçamento total',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: unallocated >= 0 ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildSummaryRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'R\$ ${value.toStringAsFixed(2)}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Obx(() {
      final hasChanges = controller.hasUnsavedChanges.value;
      final isValid = controller.isProfileValid;

      return AppButton(
        text: 'Salvar Configurações',
        onPressed: hasChanges && isValid ? controller.saveProfile : null,
        loading: controller.isSaving.value,
        icon: Icons.save,
      );
    });
  }
}
