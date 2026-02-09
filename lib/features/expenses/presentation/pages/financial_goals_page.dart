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
import '../widgets/category_selector_widget.dart';
import '../widgets/goals_summary_widget.dart';

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
              // Resumo das Metas Existentes
              _buildGoalsSummarySection(),
              const SizedBox(height: AppSpacing.lg),

              // Seção de Renda Mensal
              _buildIncomeSection(),
              const SizedBox(height: AppSpacing.lg),

              // Seção de Meta de Investimento (NOVA)
              _buildInvestmentGoalSection(context),
              const SizedBox(height: AppSpacing.lg),

              // Resumo Renda vs Investimento vs Despesas
              _buildFinancialDistributionSummary(),
              const SizedBox(height: AppSpacing.lg),

              // Seção de Orçamento Total para Despesas
              _buildTotalBudgetSection(),
              const SizedBox(height: AppSpacing.lg),

              // Seção de Seleção de Categorias
              _buildCategorySelectorSection(),
              const SizedBox(height: AppSpacing.lg),

              // Seção de Orçamento por Categoria
              if (controller.selectedCategories.isNotEmpty)
                _buildCategoryBudgetsSection(),
              if (controller.selectedCategories.isNotEmpty)
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

  /// Seção de Meta de Investimento Mensal
  Widget _buildInvestmentGoalSection(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Meta de Investimento',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: controller.investmentGoalController,
                  label: 'Quanto você quer investir por mês?',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.savings,
                  textInputAction: TextInputAction.done,
                  onChanged: (value) => controller.updateInvestmentGoal(value),
                  onEditingComplete: () => FocusScope.of(context).unfocus(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Botão OK para confirmar
              Material(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    FocusScope.of(context).unfocus();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Obx(() {
            final income = controller.monthlyIncome.value;
            final investmentGoal = controller.monthlyInvestmentGoal.value;
            if (income > 0 && investmentGoal > 0) {
              final percentage = controller.investmentPercentage.round();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$percentage% da sua renda para investimentos',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Este valor será reservado antes do cálculo do orçamento de despesas',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            }
            return Text(
              'Defina uma meta de investimento para construir seu patrimônio',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Resumo visual da distribuição financeira
  Widget _buildFinancialDistributionSummary() {
    return Obx(() {
      final income = controller.monthlyIncome.value;
      final investmentGoal = controller.monthlyInvestmentGoal.value;
      final availableForExpenses = controller.availableBudgetForExpenses;

      if (income <= 0) return const SizedBox.shrink();

      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Distribuição da Renda',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Linha 1: Renda Total
            _buildDistributionRow(
              label: 'Renda Mensal',
              value: income,
              color: AppColors.primary,
              icon: Icons.attach_money,
            ),
            
            if (investmentGoal > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.remove, size: 16, color: AppColors.textSecondary.withOpacity(0.5)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),
              
              // Linha 2: Meta de Investimento
              _buildDistributionRow(
                label: 'Meta de Investimento',
                value: investmentGoal,
                color: AppColors.success,
                icon: Icons.trending_up,
                percentage: controller.investmentPercentage,
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.arrow_downward, size: 16, color: AppColors.textSecondary.withOpacity(0.5)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),
            ],
            
            // Linha 3: Disponível para Despesas
            _buildDistributionRow(
              label: 'Disponível para Despesas',
              value: availableForExpenses,
              color: investmentGoal > 0 ? AppColors.secondary : AppColors.primary,
              icon: Icons.shopping_cart,
              percentage: investmentGoal > 0 ? controller.expensesPercentage : null,
              isHighlighted: true,
            ),
            
            if (investmentGoal > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.success, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Seu orçamento de despesas não pode ultrapassar R\$ ${availableForExpenses.toStringAsFixed(2)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildDistributionRow({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
    double? percentage,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isHighlighted ? AppSpacing.sm : AppSpacing.xs),
      decoration: isHighlighted
          ? BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (percentage != null)
                  Text(
                    '${percentage.round()}% da renda',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            'R\$ ${value.toStringAsFixed(2)}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
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
            final availableForExpenses = controller.availableBudgetForExpenses;
            final budget = controller.totalBudget.value;
            final investmentGoal = controller.monthlyInvestmentGoal.value;
            
            if (availableForExpenses <= 0) {
              return Text(
                'Defina sua renda e meta de investimento primeiro',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              );
            }
            
            final isOverLimit = controller.isBudgetOverLimit;
            final margin = controller.remainingMargin;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Limite disponível
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isOverLimit 
                        ? AppColors.error.withOpacity(0.1) 
                        : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isOverLimit 
                          ? AppColors.error.withOpacity(0.3) 
                          : AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isOverLimit ? Icons.warning : Icons.check_circle,
                        color: isOverLimit ? AppColors.error : AppColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOverLimit
                                  ? 'Orçamento acima do limite!'
                                  : 'Orçamento dentro do limite',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isOverLimit ? AppColors.error : AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              isOverLimit
                                  ? 'Excedente: R\$ ${(-margin).toStringAsFixed(2)}'
                                  : 'Margem disponível: R\$ ${margin.toStringAsFixed(2)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isOverLimit ? AppColors.error : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (investmentGoal > 0 && budget > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Limite: R\$ ${availableForExpenses.toStringAsFixed(2)} (renda - investimento)',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategorySelectorSection() {
    return AppCard(
      child: Obx(() => CategorySelectorWidget(
        availableCategories: controller.availableCategories,
        selectedCategories: controller.selectedCategoriesList,
        onCategoryToggle: controller.toggleCategorySelection,
        onAddCategory: () {
          _navigateToAddCategory();
        },
        onInitializeDefaults: controller.forceInitializeDefaultCategories,
      )),
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
                Icons.calculate,
                color: AppColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Definir Orçamentos',
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Defina quanto você planeja gastar em cada categoria selecionada',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Obx(() {
          final selectedCategories = controller.selectedCategoriesList;
          if (selectedCategories.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            children: selectedCategories.map((category) => _buildCategoryBudgetItem(category)).toList(),
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
                    category.iconData,
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

  Widget _buildGoalsSummarySection() {
    return Obx(() {
      final goals = controller.currentMonthGoals;
      
      if (goals.isEmpty) {
        return AppCard(
          child: Column(
            children: [
              Icon(
                Icons.track_changes,
                size: 48,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Nenhuma meta configurada',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Configure sua renda e orçamento para criar suas metas financeiras',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return GoalsSummaryWidget(
        goals: goals,
        onTap: () {
          // Opcional: navegar para uma tela detalhada das metas
          Get.snackbar(
            'Metas Financeiras',
            'Suas metas estão sendo exibidas abaixo',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.primary,
            colorText: Colors.white,
          );
        },
      );
    });
  }

  void _navigateToAddCategory() async {
    try {
      // Navegar para a página de adicionar categoria
      final result = await Get.toNamed('/add-category');
      
      // Se uma categoria foi adicionada, recarregar a lista
      if (result == true) {
        await controller.loadCategories();
        Get.snackbar(
          'Sucesso',
          'Categoria adicionada com sucesso!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // Se a rota não existir, mostrar mensagem alternativa
      Get.snackbar(
        'Adicionar Categoria',
        'Acesse o menu Categorias para adicionar uma nova categoria',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
