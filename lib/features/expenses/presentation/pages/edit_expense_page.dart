import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/expense.dart';
import '../controllers/expense_controller.dart';
import '../widgets/category_selector.dart';

class EditExpensePage extends StatefulWidget {
  const EditExpensePage({super.key});

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage> {
  late final ExpenseController controller;
  late final Expense expense;
  late final GlobalKey<FormState> formKey;
  late final TextEditingController amountController;
  late final TextEditingController descriptionController;
  late final TextEditingController notesController;
  late final Rx<DateTime> selectedDate;
  late final RxString selectedCategoryId;

  @override
  void initState() {
    super.initState();
    
    // Inicializar controller e despesa
    controller = Get.find<ExpenseController>();
    expense = Get.arguments as Expense;
    
    // Inicializar form e controllers
    formKey = GlobalKey<FormState>();
    amountController = TextEditingController(text: expense.amount.toString());
    descriptionController = TextEditingController(text: expense.description);
    notesController = TextEditingController(text: expense.notes ?? '');
    selectedDate = expense.date.obs;
    selectedCategoryId = expense.categoryId.obs;
  }

  @override
  void dispose() {
    // Limpar controllers para evitar memory leaks
    amountController.dispose();
    descriptionController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Despesa'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => controller.confirmDeleteExpense(expense),
            tooltip: 'Excluir despesa',
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
              // Info da despesa original
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Despesa Original',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Criada em: ${DateFormatter.formatDate(expense.createdAt)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (expense.updatedAt != expense.createdAt)
                      Text(
                        'Última edição: ${DateFormatter.formatDate(expense.updatedAt)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              
              SizedBox(height: 24.h),
              
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
              
              // Botões de ação
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    flex: 2,
                    child: Obx(() => ElevatedButton(
                      onPressed: controller.isAddingExpense.value
                          ? null
                          : () => _updateExpense(
                                formKey,
                                expense,
                                amountController,
                                descriptionController,
                                notesController,
                                selectedDate.value,
                                selectedCategoryId.value,
                              ),
                      child: controller.isAddingExpense.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Salvar Alterações'),
                    )),
                  ),
                ],
              ),
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
    TextEditingController textController,
    RxString selectedCategoryId,
  ) {
    return TextFormField(
      controller: textController,
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
        // Sugestão automática de categoria apenas se não há categoria selecionada
        if (value.length > 3 && selectedCategoryId.value.isEmpty) {
          final suggestedCategory = await controller.suggestCategory(value);
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
    return Obx(() => TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Data',
        hintText: 'Selecione a data',
        prefixIcon: const Icon(Icons.calendar_today),
        suffixIcon: const Icon(Icons.arrow_drop_down),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
      controller: TextEditingController(
        text: DateFormatter.formatDate(selectedDate.value),
      ),
      onTap: () => _selectDate(selectedDate),
      validator: (value) {
        if (selectedDate.value.isAfter(DateTime.now())) {
          return 'A data não pode ser no futuro';
        }
        return null;
      },
    ));
  }

  Widget _buildNotesField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Notas (opcional)',
        hintText: 'Informações adicionais sobre a despesa',
        prefixIcon: const Icon(Icons.notes),
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

  void _updateExpense(
    GlobalKey<FormState> formKey,
    Expense originalExpense,
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

    controller.updateExpense(
      id: originalExpense.id,
      amount: amount,
      description: description,
      categoryId: categoryId,
      date: selectedDate,
      notes: notes.isEmpty ? null : notes,
    );
  }
}
