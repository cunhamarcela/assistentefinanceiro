import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/expense.dart';
import '../controllers/expense_controller.dart';
import '../controllers/credit_card_controller.dart';
import '../bindings/credit_card_binding.dart';
import '../widgets/category_selector.dart';

class AddExpensePage extends GetView<ExpenseController> {
  const AddExpensePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Registra o binding de cartões se necessário
    if (!Get.isRegistered<CreditCardController>()) {
      CreditCardBinding().dependencies();
    }

    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final notesController = TextEditingController();
    final installmentsController = TextEditingController(text: '1');
    final interestRateController = TextEditingController(text: '0');
    final selectedDate = DateTime.now().obs;
    final selectedCategoryId = ''.obs;
    final selectedPaymentType = PaymentType.cash.obs;
    final selectedCreditCardId = ''.obs;
    final showInstallmentOptions = false.obs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Despesa'),
        centerTitle: true,
        actions: [
          // Botão de análise de texto via IA
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => _showAIAnalysisDialog(context),
            tooltip: 'Análise com IA',
          ),
        ],
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campo de valor
              _buildAmountField(amountController),
              
              SizedBox(height: 16.h),
              
              // Campo de descrição
              _buildDescriptionField(descriptionController, selectedCategoryId),
              
              SizedBox(height: 16.h),
              
              // Seletor de categoria
              _buildCategorySelector(selectedCategoryId),
              
              SizedBox(height: 16.h),
              
              // Seletor de data
              _buildDateSelector(selectedDate),
              
              SizedBox(height: 16.h),
              
              // Campo de notas (opcional)
              _buildNotesField(notesController),
              
              SizedBox(height: 16.h),

              // Seletor de tipo de pagamento
              _buildPaymentTypeSelector(selectedPaymentType, showInstallmentOptions),
              
              SizedBox(height: 16.h),

              // Seletor de cartão de crédito (só aparece se pagamento for crédito)
              Obx(() {
                if (selectedPaymentType.value == PaymentType.credit) {
                  return Column(
                    children: [
                      _buildCreditCardSelector(selectedCreditCardId),
                      SizedBox(height: 16.h),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),

              // Opções de parcelamento (só aparece se showInstallmentOptions for true)
              Obx(() {
                if (showInstallmentOptions.value) {
                  return Column(
                    children: [
                      _buildInstallmentFields(installmentsController, interestRateController),
                      SizedBox(height: 16.h),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
              
              SizedBox(height: 16.h),
              
              // Botão de salvar
              Obx(() => ElevatedButton(
                onPressed: controller.isAddingExpense.value
                    ? null
                    : () => _saveExpense(
                          formKey,
                          amountController,
                          descriptionController,
                          notesController,
                          selectedDate.value,
                          selectedCategoryId.value,
                          selectedPaymentType.value,
                          selectedCreditCardId.value,
                          installmentsController,
                          interestRateController,
                          showInstallmentOptions.value,
                        ),
                child: controller.isAddingExpense.value
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Salvar Despesa',
                        style: TextStyle(fontSize: 16.sp),
                      ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+[.,]?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: 'Valor *',
        hintText: '0,00',
        prefixText: 'R\$ ',
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, insira o valor';
        }
        
        final amount = double.tryParse(value.replaceAll(',', '.'));
        if (amount == null || amount <= 0) {
          return 'Por favor, insira um valor válido';
        }
        
        if (amount > 999999.99) {
          return 'Valor muito alto';
        }
        
        return null;
      },
      autofocus: true,
    );
  }

  Widget _buildDescriptionField(
    TextEditingController controller,
    RxString selectedCategoryId,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Descrição *',
        hintText: 'Ex: Almoço no restaurante',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor, insira uma descrição';
        }
        
        if (value.length > 100) {
          return 'Descrição muito longa (máximo 100 caracteres)';
        }
        
        return null;
      },
      onChanged: (value) async {
        // Sugestão automática de categoria
        if (value.length > 3 && selectedCategoryId.value.isEmpty) {
          final suggestedCategory = await this.controller.suggestCategory(value);
          selectedCategoryId.value = suggestedCategory;
        }
      },
    );
  }

  Widget _buildCategorySelector(RxString selectedCategoryId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoria',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Obx(() => CategorySelector(
          categories: controller.categories,
          selectedCategoryId: selectedCategoryId.value,
          onCategorySelected: (categoryId) {
            selectedCategoryId.value = categoryId;
          },
        )),
      ],
    );
  }

  Widget _buildDateSelector(Rx<DateTime> selectedDate) {
    return InkWell(
      onTap: () => _selectDate(selectedDate),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                Obx(() => Text(
                  DateFormatter.formatDate(selectedDate.value),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                )),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Notas (opcional)',
        hintText: 'Informações adicionais...',
        prefixIcon: const Icon(Icons.note),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
      validator: (value) {
        if (value != null && value.length > 200) {
          return 'Notas muito longas (máximo 200 caracteres)';
        }
        return null;
      },
    );
  }

  Future<void> _selectDate(Rx<DateTime> selectedDate) async {
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: selectedDate.value,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      selectedDate.value = picked;
    }
  }

  Widget _buildPaymentTypeSelector(
    Rx<PaymentType> selectedPaymentType,
    RxBool showInstallmentOptions,
  ) {
    final paymentTypes = {
      PaymentType.cash: {'label': 'Dinheiro', 'icon': Icons.money},
      PaymentType.debit: {'label': 'Débito', 'icon': Icons.credit_card},
      PaymentType.credit: {'label': 'Crédito', 'icon': Icons.credit_card},
      PaymentType.pix: {'label': 'PIX', 'icon': Icons.pix},
      PaymentType.other: {'label': 'Outro', 'icon': Icons.payment},
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forma de Pagamento',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Obx(() => Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: paymentTypes.entries.map((entry) {
            final isSelected = selectedPaymentType.value == entry.key;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    entry.value['icon'] as IconData,
                    size: 16.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(entry.value['label'] as String),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  selectedPaymentType.value = entry.key;
                  // Se mudou para crédito, pode mostrar opção de parcelamento
                  if (entry.key == PaymentType.credit) {
                    // Aqui você pode adicionar lógica adicional
                  } else {
                    showInstallmentOptions.value = false;
                  }
                }
              },
            );
          }).toList(),
        )),
        // Se for crédito, mostrar checkbox para parcelar
        Obx(() {
          if (selectedPaymentType.value == PaymentType.credit) {
            return Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Parcelar compra'),
                value: showInstallmentOptions.value,
                onChanged: (value) {
                  showInstallmentOptions.value = value ?? false;
                },
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildCreditCardSelector(RxString selectedCreditCardId) {
    // Tenta obter o controller, mas não falha se não existir
    CreditCardController? cardController;
    try {
      cardController = Get.find<CreditCardController>();
    } catch (e) {
      // Se não conseguir encontrar, registra o binding
      CreditCardBinding().dependencies();
      cardController = Get.find<CreditCardController>();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cartão de Crédito *',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton.icon(
              onPressed: () => Get.toNamed('/add-credit-card'),
              icon: const Icon(Icons.add),
              label: const Text('Novo'),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Obx(() {
          if (cardController?.isLoading.value ?? false) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cardController?.creditCards.isEmpty ?? true) {
            return Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                children: [
                  const Text('Nenhum cartão cadastrado'),
                  SizedBox(height: 8.h),
                  ElevatedButton(
                    onPressed: () => Get.toNamed('/add-credit-card'),
                    child: const Text('Adicionar Cartão'),
                  ),
                ],
              ),
            );
          }

          return DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: 'Selecione um cartão',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            value: selectedCreditCardId.value.isEmpty ? null : selectedCreditCardId.value,
            items: (cardController?.creditCards ?? []).map<DropdownMenuItem<String>>((card) {
              return DropdownMenuItem<String>(
                value: card.id,
                child: Text(card.displayName),
              );
            }).toList(),
            onChanged: (value) {
              selectedCreditCardId.value = value ?? '';
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, selecione um cartão';
              }
              return null;
            },
          );
        }),
      ],
    );
  }

  Widget _buildInstallmentFields(
    TextEditingController installmentsController,
    TextEditingController interestRateController,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(8.r),
        color: AppColors.primary.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parcelamento',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: installmentsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Número de Parcelas *',
                    hintText: '12',
                    prefixIcon: const Icon(Icons.credit_score),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Obrigatório';
                    }
                    final installments = int.tryParse(value);
                    if (installments == null || installments < 2 || installments > 48) {
                      return 'Entre 2 e 48';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: TextFormField(
                  controller: interestRateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+[.,]?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Juros (% ao mês)',
                    hintText: '0',
                    prefixIcon: const Icon(Icons.percent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _saveExpense(
    GlobalKey<FormState> formKey,
    TextEditingController amountController,
    TextEditingController descriptionController,
    TextEditingController notesController,
    DateTime selectedDate,
    String selectedCategoryId,
    PaymentType selectedPaymentType,
    String selectedCreditCardId,
    TextEditingController installmentsController,
    TextEditingController interestRateController,
    bool showInstallmentOptions,
  ) {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final amount = double.parse(amountController.text.replaceAll(',', '.'));
    final description = descriptionController.text.trim();
    final notes = notesController.text.trim();
    
    // Obter o ID correto da categoria 'outros' da lista de categorias carregadas
    // ou usar o selecionado pelo usuário
    String categoryId;
    if (selectedCategoryId.isEmpty) {
      // Buscar a categoria 'outros' na lista do controller
      try {
        final outrosCategory = controller.categories.firstWhere(
          (cat) => cat.id.startsWith('outros') || cat.name.toLowerCase() == 'outros'
        );
        categoryId = outrosCategory.id;
      } catch (_) {
        categoryId = 'outros';
      }
    } else {
      categoryId = selectedCategoryId;
    }

    // Validação de cartão de crédito
    if (selectedPaymentType == PaymentType.credit && 
        (selectedCreditCardId.isEmpty)) {
      Get.snackbar(
        'Erro',
        'Por favor, selecione um cartão de crédito',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    int? installments;
    double? interestRate;

    if (showInstallmentOptions) {
      installments = int.tryParse(installmentsController.text);
      interestRate = double.tryParse(interestRateController.text.replaceAll(',', '.'));

      if (installments == null || installments < 2) {
        Get.snackbar(
          'Erro',
          'Número de parcelas inválido',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return;
      }
    }

    controller.addExpense(
      amount: amount,
      description: description,
      categoryId: categoryId,
      date: selectedDate,
      notes: notes.isEmpty ? null : notes,
      paymentType: selectedPaymentType,
      creditCardId: selectedPaymentType == PaymentType.credit ? selectedCreditCardId : null,
      installments: installments,
      interestRate: interestRate,
    );
  }

  void _showAIAnalysisDialog(BuildContext context) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Análise com IA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Digite uma frase descrevendo seu gasto e a IA irá extrair as informações automaticamente.',
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Ex: Gastei 25 reais no almoço',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(context).pop();
                await _analyzeText(text);
              }
            },
            child: const Text('Analisar'),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeText(String text) async {
    try {
      final analysis = await controller.analyzeExpenseText(text);
      
      if (analysis.isValid) {
        Get.snackbar(
          'Análise Concluída',
          'Informações extraídas com sucesso!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        
        // TODO: Preencher campos com os dados analisados
        // Isso seria implementado passando os dados de volta para os controllers
      } else {
        Get.snackbar(
          'Análise Incompleta',
          'Não foi possível extrair todas as informações. Tente ser mais específico.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.warning,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao analisar texto: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }
}
