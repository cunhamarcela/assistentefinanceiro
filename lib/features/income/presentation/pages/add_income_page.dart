import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/income.dart';
import '../controllers/income_controller.dart';

/// Página para adicionar nova receita
/// Tokens utilizados:
/// - Background: colorBackgroundPrimary
/// - AppBar: colorBrandDark, colorTextOnDark
/// - Card: colorSurfaceCard
/// - Input: colorBorderSubtle
/// - Botão: colorActionPrimary
class AddIncomePage extends GetView<IncomeController> {
  const AddIncomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final notesController = TextEditingController();
    
    final selectedType = IncomeType.other.obs;
    final selectedDate = DateTime.now().obs;
    final isRecurring = false.obs;
    final selectedFrequency = RecurrenceFrequency.monthly.obs;
    final isSubmitting = false.obs;

    return Scaffold(
      backgroundColor: AppColors.colorBackgroundPrimary,
      appBar: AppBar(
        title: Text(
          'Nova Receita',
          style: AppTextStyles.headline3.copyWith(
            color: AppColors.colorTextOnDark,
          ),
        ),
        backgroundColor: AppColors.colorBrandDark,
        iconTheme: IconThemeData(color: AppColors.colorTextOnDark),
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Valor
              _buildSectionTitle('Valor'),
              const SizedBox(height: 8),
              _buildAmountField(amountController),
              const SizedBox(height: 24),

              // Descrição
              _buildSectionTitle('Descrição'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: descriptionController,
                hint: 'Ex: Salário mensal',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe uma descrição';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Tipo de receita
              _buildSectionTitle('Tipo de Receita'),
              const SizedBox(height: 8),
              Obx(() => _buildTypeSelector(selectedType)),
              const SizedBox(height: 24),

              // Data
              _buildSectionTitle('Data'),
              const SizedBox(height: 8),
              Obx(() => _buildDateSelector(context, selectedDate)),
              const SizedBox(height: 24),

              // Receita recorrente
              Obx(() => _buildRecurringSwitch(isRecurring)),
              
              // Frequência (se recorrente)
              Obx(() {
                if (!isRecurring.value) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildSectionTitle('Frequência'),
                    const SizedBox(height: 8),
                    _buildFrequencySelector(selectedFrequency),
                  ],
                );
              }),
              const SizedBox(height: 24),

              // Notas
              _buildSectionTitle('Notas (opcional)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: notesController,
                hint: 'Adicione observações...',
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Botão salvar
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting.value
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            isSubmitting.value = true;
                            
                            final amount = double.tryParse(
                              amountController.text
                                  .replaceAll('R\$', '')
                                  .replaceAll('.', '')
                                  .replaceAll(',', '.')
                                  .trim(),
                            );

                            if (amount == null || amount <= 0) {
                              Get.snackbar(
                                'Erro',
                                'Informe um valor válido',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: AppColors.colorError,
                                colorText: AppColors.colorTextOnDark,
                              );
                              isSubmitting.value = false;
                              return;
                            }

                            RecurrenceInfo? recurrenceInfo;
                            if (isRecurring.value) {
                              recurrenceInfo = RecurrenceInfo(
                                frequency: selectedFrequency.value,
                                startDate: selectedDate.value,
                              );
                            }

                            print('📝 [AddIncomePage] Chamando controller.createIncome()...');
                            final success = await controller.createIncome(
                              amount: amount,
                              description: descriptionController.text.trim(),
                              type: selectedType.value,
                              date: selectedDate.value,
                              notes: notesController.text.trim().isEmpty 
                                  ? null 
                                  : notesController.text.trim(),
                              isRecurring: isRecurring.value,
                              recurrenceInfo: recurrenceInfo,
                            );

                            print('📝 [AddIncomePage] createIncome() retornou: $success');

                            if (success) {
                              // NÃO resetar isSubmitting para evitar múltiplos cliques
                              // enquanto a navegação acontece
                              print('📝 [AddIncomePage] Chamando Get.back()...');
                              print('📝 [AddIncomePage] Rota atual: ${Get.currentRoute}');
                              print('📝 [AddIncomePage] Rotas na stack: ${Get.routing.route}');
                              print('📝 [AddIncomePage] canPop: ${Navigator.of(context).canPop()}');
                              
                              // Usar Navigator.pop() diretamente como alternativa
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                                print('📝 [AddIncomePage] Navigator.pop() executado!');
                              } else {
                                Get.offAllNamed('/incomes');
                                print('📝 [AddIncomePage] Não foi possível pop, redirecionando para /incomes');
                              }
                            } else {
                              // Só reativar o botão se falhou
                              isSubmitting.value = false;
                              print('📝 [AddIncomePage] success=false, NÃO chamando Get.back()');
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.colorActionPrimary,
                    foregroundColor: AppColors.colorTextOnDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting.value
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Salvar Receita',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.colorTextSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildAmountField(TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.colorSurfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.colorBorderSubtle),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: AppTextStyles.headline2.copyWith(
          color: AppColors.colorSuccess,
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: 'R\$ 0,00',
          hintStyle: AppTextStyles.headline2.copyWith(
            color: AppColors.colorTextMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Icon(
              Icons.attach_money_rounded,
              color: AppColors.colorSuccess,
              size: 28,
            ),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Informe o valor';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.colorSurfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.colorBorderSubtle),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.colorTextPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.colorTextMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildTypeSelector(Rx<IncomeType> selectedType) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: IncomeType.values.map((type) {
        final isSelected = selectedType.value == type;
        return GestureDetector(
          onTap: () => selectedType.value = type,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Color(type.colorValue).withOpacity(0.1)
                  : AppColors.colorSurfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected 
                    ? Color(type.colorValue) 
                    : AppColors.colorBorderSubtle,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(type.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  type.displayName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected 
                        ? Color(type.colorValue) 
                        : AppColors.colorTextSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateSelector(BuildContext context, Rx<DateTime> selectedDate) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');
    
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate.value,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('pt', 'BR'),
        );
        if (picked != null) {
          selectedDate.value = picked;
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.colorSurfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.colorBorderSubtle),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: AppColors.colorBrandSoft,
            ),
            const SizedBox(width: 12),
            Text(
              dateFormat.format(selectedDate.value),
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.colorTextPrimary,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.colorTextMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringSwitch(RxBool isRecurring) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.colorSurfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.colorBorderSubtle),
      ),
      child: Row(
        children: [
          Icon(
            Icons.repeat_rounded,
            color: isRecurring.value 
                ? AppColors.colorSuccess 
                : AppColors.colorTextMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Receita Recorrente',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.colorTextPrimary,
                  ),
                ),
                Text(
                  'Repete automaticamente no período selecionado',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.colorTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isRecurring.value,
            onChanged: (value) => isRecurring.value = value,
            activeColor: AppColors.colorSuccess,
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencySelector(Rx<RecurrenceFrequency> selectedFrequency) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RecurrenceFrequency.values.map((freq) {
        final isSelected = selectedFrequency.value == freq;
        return GestureDetector(
          onTap: () => selectedFrequency.value = freq,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.colorSuccess.withOpacity(0.1)
                  : AppColors.colorSurfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected 
                    ? AppColors.colorSuccess 
                    : AppColors.colorBorderSubtle,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              freq.displayName,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected 
                    ? AppColors.colorSuccess 
                    : AppColors.colorTextSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

