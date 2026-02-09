import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/income.dart';
import '../controllers/income_controller.dart';

/// Página de listagem de receitas
/// Tokens utilizados:
/// - Background: colorBackgroundPrimary
/// - AppBar: colorBrandDark, colorTextOnDark
/// - Card: colorSurfaceCard
/// - Texto: colorTextPrimary, colorTextSecondary, colorTextMuted
/// - Valores: colorSuccess
/// - FAB: colorActionPrimary
class IncomeListPage extends GetView<IncomeController> {
  const IncomeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackgroundPrimary,
      appBar: AppBar(
        title: Text(
          'Receitas',
          style: AppTextStyles.headline3.copyWith(
            color: AppColors.colorTextOnDark,
          ),
        ),
        backgroundColor: AppColors.colorBrandDark,
        iconTheme: IconThemeData(color: AppColors.colorTextOnDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.incomes.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.incomes.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.loadIncomes,
          child: CustomScrollView(
            slivers: [
              // Header com resumo
              SliverToBoxAdapter(
                child: _buildSummaryHeader(),
              ),

              // Lista de receitas
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final income = controller.incomes[index];
                      return _buildIncomeCard(income);
                    },
                    childCount: controller.incomes.length,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/income/add'),
        backgroundColor: AppColors.colorActionPrimary,
        foregroundColor: AppColors.colorTextOnDark,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova Receita'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: AppColors.colorTextMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma receita registrada',
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.colorTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione suas receitas para ter um controle completo das suas finanças.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.colorTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/income/add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.colorActionPrimary,
                foregroundColor: AppColors.colorTextOnDark,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar Receita'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.colorSuccess,
            AppColors.colorSuccess.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.colorSuccess.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: AppColors.colorTextOnDark,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Receitas do Mês',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.colorTextOnDark.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() => Text(
            _formatCurrency(controller.currentMonthTotal.value),
            style: AppTextStyles.headline1.copyWith(
              color: AppColors.colorTextOnDark,
              fontWeight: FontWeight.bold,
            ),
          )),
          const SizedBox(height: 8),
          Obx(() => Text(
            '${controller.currentMonthIncomes.length} receita(s) este mês',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.colorTextOnDark.withOpacity(0.8),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildIncomeCard(Income income) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.colorSurfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.colorBorderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed('/income/edit/${income.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícone do tipo
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(income.type.colorValue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      income.type.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Informações
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        income.description,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.colorTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            income.type.displayName,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.colorTextSecondary,
                            ),
                          ),
                          if (income.isRecurring) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.repeat_rounded,
                              size: 14,
                              color: AppColors.colorBrandSoft,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Recorrente',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.colorBrandSoft,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(income.date),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.colorTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Valor
                Text(
                  _formatCurrency(income.amount),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.colorSuccess,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    final format = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return format.format(value);
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtrar Receitas',
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.colorTextPrimary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Filtro por tipo
            Text(
              'Por Tipo',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.colorTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IncomeType.values.map((type) {
                return FilterChip(
                  label: Text('${type.icon} ${type.displayName}'),
                  selected: controller.typeFilter.value == type,
                  onSelected: (selected) {
                    if (selected) {
                      controller.filterByType(type);
                    } else {
                      controller.clearFilters();
                    }
                    Get.back();
                  },
                  selectedColor: AppColors.colorSuccess.withOpacity(0.2),
                  checkmarkColor: AppColors.colorSuccess,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Botão limpar filtros
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  controller.clearFilters();
                  controller.loadIncomes();
                  Get.back();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Limpar Filtros'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

