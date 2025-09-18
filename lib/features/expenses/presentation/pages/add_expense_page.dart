import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../controllers/expense_controller.dart';
import '../widgets/category_selector.dart';

class AddExpensePage extends GetView<ExpenseController> {
  const AddExpensePage({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final notesController = TextEditingController();
    final selectedDate = DateTime.now().obs;
    final selectedCategoryId = ''.obs;

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
              
              SizedBox(height: 32.h),
              
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
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
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

  void _saveExpense(
    GlobalKey<FormState> formKey,
    TextEditingController amountController,
    TextEditingController descriptionController,
    TextEditingController notesController,
    DateTime selectedDate,
    String selectedCategoryId,
  ) {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final amount = double.parse(amountController.text.replaceAll(',', '.'));
    final description = descriptionController.text.trim();
    final notes = notesController.text.trim();
    final categoryId = selectedCategoryId.isEmpty ? 'outros' : selectedCategoryId;

    controller.addExpense(
      amount: amount,
      description: description,
      categoryId: categoryId,
      date: selectedDate,
      notes: notes.isEmpty ? null : notes,
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
