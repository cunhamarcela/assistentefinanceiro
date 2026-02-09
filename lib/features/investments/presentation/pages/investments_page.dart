import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/cards/app_card.dart';
import '../../domain/entities/investment.dart';
import '../controllers/investment_controller.dart';

class InvestmentsPage extends GetView<InvestmentController> {
  const InvestmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackgroundPrimary,
      appBar: AppBar(
        title: const Text('Meus Investimentos'),
        backgroundColor: AppColors.colorBrandDark,
        foregroundColor: AppColors.colorTextOnDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.chart_pie),
            onPressed: () => _showDistributionDialog(context),
            tooltip: 'Distribuição',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.colorActionPrimary,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          color: AppColors.colorActionPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Resumo
                _buildSummaryCards(),
                const SizedBox(height: AppSpacing.lg),

                // Botão para adicionar
                _buildAddButton(context),
                const SizedBox(height: AppSpacing.lg),

                // Lista de investimentos
                _buildInvestmentsList(context),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        // Card principal - Total investido
        AppCard(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.colorBrandPrimary,
                  AppColors.colorBrandDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.chart_bar_fill,
                      color: AppColors.colorTextOnDark.withOpacity(0.8),
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Total Investido',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.colorTextOnDark.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Obx(() => Text(
                  'R\$ ${_formatCurrency(controller.totalInvested.value)}',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: AppColors.colorTextOnDark,
                    fontWeight: FontWeight.bold,
                  ),
                )),
                const SizedBox(height: AppSpacing.md),
                Obx(() => Text(
                  'Este mês: R\$ ${_formatCurrency(controller.totalInvestedThisMonth.value)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.colorTextOnDark.withOpacity(0.9),
                  ),
                )),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Cards de distribuição por tipo
        Obx(() {
          final distribution = controller.getDistributionByType();
          if (distribution.isEmpty) {
            return const SizedBox.shrink();
          }

          return SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: distribution.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final entry = distribution.entries.elementAt(index);
                final totals = controller.getTotalsByType();
                final total = totals[entry.key] ?? 0;
                
                return _buildTypeCard(entry.key, total, entry.value);
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTypeCard(InvestmentType type, double total, double percentage) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.colorSurfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.colorBorderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(type.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  type.displayName,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.colorTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'R\$ ${_formatCurrency(total)}',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.colorTextPrimary,
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.colorTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showAddInvestmentSheet(context),
        icon: const Icon(CupertinoIcons.add),
        label: const Text('Adicionar Investimento'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.colorActionPrimary,
          foregroundColor: AppColors.colorTextOnDark,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildInvestmentsList(BuildContext context) {
    return Obx(() {
      if (controller.investments.isEmpty) {
        return _buildEmptyState();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Histórico de Investimentos',
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.colorTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.investments.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final investment = controller.investments[index];
              return _buildInvestmentCard(context, investment);
            },
          ),
        ],
      );
    });
  }

  Widget _buildInvestmentCard(BuildContext context, Investment investment) {
    return Dismissible(
      key: Key(investment.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.colorError,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          CupertinoIcons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Excluir Investimento'),
            content: const Text('Tem certeza que deseja excluir este investimento?'),
            actions: [
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Excluir'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        controller.deleteInvestment(investment.id);
      },
      child: AppCard(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.colorBrandSoft.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                investment.type.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          title: Text(
            investment.description,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.colorTextPrimary,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                investment.type.displayName,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.colorTextMuted,
                ),
              ),
              if (investment.institution != null)
                Text(
                  investment.institution!,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.colorTextMuted,
                  ),
                ),
              Text(
                DateFormat('dd/MM/yyyy').format(investment.date),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.colorTextMuted,
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'R\$ ${_formatCurrency(investment.amount)}',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.colorSuccess,
                ),
              ),
              if (investment.expectedReturn != null)
                Text(
                  '${investment.expectedReturn!.toStringAsFixed(1)}% a.a.',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.colorTextMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.chart_bar_alt_fill,
            size: 80,
            color: AppColors.colorTextMuted.withOpacity(0.3),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nenhum investimento registrado',
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Comece a registrar seus investimentos\npara acompanhar seu patrimônio',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.colorTextMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddInvestmentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.colorSurfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddInvestmentSheet(controller: controller),
    );
  }

  void _showDistributionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.colorSurfaceCard,
        title: Text(
          'Distribuição de Investimentos',
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.colorTextPrimary,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(() {
            final distribution = controller.getDistributionByType();
            final totals = controller.getTotalsByType();
            
            if (distribution.isEmpty) {
              return Text(
                'Nenhum investimento registrado',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.colorTextMuted,
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: distribution.length,
              itemBuilder: (context, index) {
                final entry = distribution.entries.elementAt(index);
                final total = totals[entry.key] ?? 0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Text(entry.key.icon, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key.displayName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.colorTextPrimary,
                              ),
                            ),
                            LinearProgressIndicator(
                              value: entry.value / 100,
                              backgroundColor: AppColors.colorBorderSubtle,
                              valueColor: const AlwaysStoppedAnimation(AppColors.colorActionPrimary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${entry.value.toStringAsFixed(1)}%',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.colorTextPrimary,
                            ),
                          ),
                          Text(
                            'R\$ ${_formatCurrency(total)}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.colorTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fechar',
              style: TextStyle(color: AppColors.colorBrandPrimary),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2).format(value);
  }
}

class _AddInvestmentSheet extends StatelessWidget {
  final InvestmentController controller;

  const _AddInvestmentSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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
            const SizedBox(height: AppSpacing.md),

            // Título
            Text(
              'Novo Investimento',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.colorTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Tipo de investimento
            Text(
              'Tipo de Investimento',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.colorTextSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Obx(() => Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: InvestmentType.values.map((type) {
                final isSelected = controller.selectedType.value == type;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(type.icon),
                      const SizedBox(width: 4),
                      Text(type.displayName),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) controller.selectType(type);
                  },
                  selectedColor: AppColors.colorActionPrimary.withOpacity(0.2),
                  backgroundColor: AppColors.colorBackgroundSecondary,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.colorActionPrimary : AppColors.colorTextSecondary,
                  ),
                );
              }).toList(),
            )),
            const SizedBox(height: AppSpacing.lg),

            // Valor
            TextField(
              controller: controller.amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Valor',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.colorActionPrimary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Descrição
            TextField(
              controller: controller.descriptionController,
              decoration: InputDecoration(
                labelText: 'Descrição',
                hintText: 'Ex: Tesouro Selic 2029',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.colorActionPrimary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Instituição (opcional)
            TextField(
              controller: controller.institutionController,
              decoration: InputDecoration(
                labelText: 'Instituição (opcional)',
                hintText: 'Ex: Nubank, XP, BTG',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.colorActionPrimary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Retorno esperado (opcional)
            TextField(
              controller: controller.expectedReturnController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Retorno esperado % a.a. (opcional)',
                hintText: 'Ex: 12.5',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.colorActionPrimary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Botão salvar
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isSaving.value
                    ? null
                    : () async {
                        final success = await controller.addInvestment();
                        if (success && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.colorActionPrimary,
                  foregroundColor: AppColors.colorTextOnDark,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: controller.isSaving.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.colorTextOnDark,
                        ),
                      )
                    : const Text('Salvar Investimento'),
              ),
            )),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

