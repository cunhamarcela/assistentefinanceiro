import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/cards/app_card.dart';
import '../controllers/expense_controller.dart';
import '../widgets/expense_card.dart';
import '../widgets/expense_summary.dart';

class HomePage extends GetView<ExpenseController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Assistente Financeiro', style: AppTextStyles.headline2.copyWith(color: AppColors.colorTextOnDark)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: AppColors.textPrimary),
            onPressed: () => Get.toNamed(AppRoutes.profile),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          child: CustomScrollView(
            slivers: [
              // Resumo financeiro
              SliverToBoxAdapter(
                child: _buildFinancialSummary(),
              ),
              
              // Ações rápidas
              SliverToBoxAdapter(
                child: _buildQuickActions(),
              ),
              
              // Despesas recentes
              SliverToBoxAdapter(
                child: _buildRecentExpenses(),
              ),
              
              // Padding bottom para FAB
              SliverToBoxAdapter(
                child: SizedBox(height: 100.h),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.addExpense),
        icon: const Icon(Icons.add),
        label: const Text('Nova Despesa'),
        backgroundColor: AppColors.primary,
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildFinancialSummary() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Obx(() {
        final stats = controller.stats.value;
        if (stats == null) {
          return const SizedBox.shrink();
        }

        return ExpenseSummary(
          totalMonth: stats.totalMonth,
          totalWeek: stats.totalWeek,
          totalToday: stats.totalToday,
          expenseCount: stats.expenseCount,
          averagePerDay: stats.averagePerDay,
        );
      }),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ações Rápidas',
            style: AppTextStyles.headline3Dark,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Linha 1: Adicionar Gasto e Ver Todas
          Row(
            children: [
              Expanded(
                child: HomeCard(
                  icon: Icons.add_circle,
                  title: 'Adicionar Gasto',
                  iconColor: AppColors.accent,
                  onTap: () => Get.toNamed(AppRoutes.addExpense),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: HomeCard(
                  icon: Icons.list,
                  title: 'Ver Todas',
                  iconColor: AppColors.primary,
                  onTap: () => Get.toNamed(AppRoutes.expenses),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Linha 2: Receitas e Chat IA (NOVAS)
          Row(
            children: [
              Expanded(
                child: HomeCard(
                  icon: Icons.account_balance_wallet,
                  title: 'Receitas',
                  iconColor: AppColors.colorSuccess,
                  onTap: () => Get.toNamed(AppRoutes.incomes),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: HomeCard(
                  icon: Icons.smart_toy,
                  title: 'Chat IA',
                  iconColor: AppColors.colorBrandSoft,
                  onTap: () => Get.toNamed(AppRoutes.chat),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Linha 3: Cartões de Crédito e Categorias
          Row(
            children: [
              Expanded(
                child: HomeCard(
                  icon: Icons.credit_card,
                  title: 'Cartões',
                  iconColor: AppColors.colorBrandPrimary,
                  onTap: () => Get.toNamed(AppRoutes.creditCards),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: HomeCard(
                  icon: Icons.category,
                  title: 'Categorias',
                  iconColor: AppColors.accent,
                  onTap: () => Get.toNamed(AppRoutes.categories),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Linha 4: Relatórios e Metas
          Row(
            children: [
              Expanded(
                child: HomeCard(
                  icon: Icons.analytics,
                  title: 'Relatórios',
                  iconColor: AppColors.blue,
                  onTap: () => Get.toNamed(AppRoutes.analytics),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: HomeCard(
                  icon: Icons.track_changes,
                  title: 'Metas',
                  iconColor: AppColors.success,
                  onTap: () => Get.toNamed(AppRoutes.financialGoals),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Linha 5: Investimentos e Comparações
          Row(
            children: [
              Expanded(
                child: HomeCard(
                  icon: Icons.show_chart,
                  title: 'Investimentos',
                  iconColor: AppColors.colorSuccess,
                  onTap: () => Get.toNamed(AppRoutes.investments),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: HomeCard(
                  icon: Icons.compare_arrows,
                  title: 'Comparações',
                  iconColor: AppColors.purple,
                  onTap: () => Get.toNamed(AppRoutes.multiPeriodComparison),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentExpenses() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Despesas Recentes',
                style: AppTextStyles.headline3Dark,
              ),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.expenses),
                child: Text(
                  'Ver todas',
                  style: AppTextStyles.body1.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Obx(() {
            final recentExpenses = controller.expenses.take(5).toList();
            
            if (recentExpenses.isEmpty) {
              return AppCard.padded(
                child: Column(
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Nenhuma despesa encontrada',
                      style: AppTextStyles.subtitle1Dark.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Adicione sua primeira despesa para começar',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: recentExpenses.map((expense) {
                final category = controller.getCategoryById(expense.categoryId);
                return ExpenseCard(
                  expense: expense,
                  category: category,
                  onTap: () {
                    // TODO: Navegar para detalhes da despesa
                  },
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      currentIndex: 0,
      onTap: (index) {
        switch (index) {
          case 0:
            // Já está na home
            break;
          case 1:
            Get.toNamed(AppRoutes.expenses);
            break;
          case 2:
            Get.toNamed(AppRoutes.incomes);
            break;
          case 3:
            Get.toNamed(AppRoutes.chat);
            break;
          case 4:
            Get.toNamed(AppRoutes.analytics);
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.arrow_downward),
          label: 'Despesas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.arrow_upward),
          label: 'Receitas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.smart_toy),
          label: 'Chat IA',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Relatórios',
        ),
      ],
    );
  }
}
