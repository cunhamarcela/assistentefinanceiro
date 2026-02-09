import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/credit_card_controller.dart';

/// Página para adicionar um novo cartão de crédito
class AddCreditCardPage extends GetView<CreditCardController> {
  const AddCreditCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final lastFourDigitsController = TextEditingController();
    final closingDayController = TextEditingController();
    final dueDayController = TextEditingController();
    final limitController = TextEditingController();
    final selectedFlag = ''.obs;
    final selectedColor = AppColors.primary.value.toRadixString(16).obs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Cartão'),
        centerTitle: true,
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nome do cartão
              _buildTextField(
                controller: nameController,
                label: 'Nome do Cartão *',
                hint: 'Ex: Nubank, Itaú, etc.',
                icon: Icons.credit_card,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira o nome do cartão';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16.h),

              // Últimos 4 dígitos
              _buildTextField(
                controller: lastFourDigitsController,
                label: 'Últimos 4 Dígitos *',
                hint: '1234',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira os últimos 4 dígitos';
                  }
                  if (value.length != 4) {
                    return 'Deve conter exatamente 4 dígitos';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16.h),

              // Bandeira
              _buildFlagSelector(selectedFlag),

              SizedBox(height: 16.h),

              // Dias de fechamento e vencimento
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: closingDayController,
                      label: 'Dia de Fechamento *',
                      hint: '10',
                      icon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Obrigatório';
                        }
                        final day = int.tryParse(value);
                        if (day == null || day < 1 || day > 31) {
                          return 'Entre 1 e 31';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildTextField(
                      controller: dueDayController,
                      label: 'Dia de Vencimento *',
                      hint: '15',
                      icon: Icons.event,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Obrigatório';
                        }
                        final day = int.tryParse(value);
                        if (day == null || day < 1 || day > 31) {
                          return 'Entre 1 e 31';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Limite (opcional)
              _buildTextField(
                controller: limitController,
                label: 'Limite (opcional)',
                hint: '5000.00',
                icon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),

              SizedBox(height: 16.h),

              // Seletor de cor
              _buildColorSelector(selectedColor),

              SizedBox(height: 32.h),

              // Botão de salvar
              Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () => _saveCard(
                          formKey,
                          nameController,
                          lastFourDigitsController,
                          closingDayController,
                          dueDayController,
                          limitController,
                          selectedFlag.value,
                          selectedColor.value,
                        ),
                child: controller.isLoading.value
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Salvar Cartão',
                        style: TextStyle(fontSize: 16.sp),
                      ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        counterText: '',
      ),
      validator: validator,
    );
  }

  Widget _buildFlagSelector(RxString selectedFlag) {
    final flags = ['Visa', 'Mastercard', 'Elo', 'Amex', 'Hipercard', 'Outro'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bandeira',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Obx(() => Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: flags.map((flag) {
            final isSelected = selectedFlag.value == flag;
            return ChoiceChip(
              label: Text(flag),
              selected: isSelected,
              onSelected: (selected) {
                selectedFlag.value = selected ? flag : '';
              },
            );
          }).toList(),
        )),
      ],
    );
  }

  Widget _buildColorSelector(RxString selectedColor) {
    final colors = [
      AppColors.primary,
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cor do Cartão',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Obx(() => Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: colors.map((color) {
            final colorHex = color.value.toRadixString(16);
            final isSelected = selectedColor.value == colorHex;
            
            return GestureDetector(
              onTap: () => selectedColor.value = colorHex,
              child: Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        )),
      ],
    );
  }

  void _saveCard(
    GlobalKey<FormState> formKey,
    TextEditingController nameController,
    TextEditingController lastFourDigitsController,
    TextEditingController closingDayController,
    TextEditingController dueDayController,
    TextEditingController limitController,
    String selectedFlag,
    String selectedColor,
  ) {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final name = nameController.text.trim();
    final lastFourDigits = lastFourDigitsController.text.trim();
    final closingDay = int.parse(closingDayController.text);
    final dueDay = int.parse(dueDayController.text);
    final limitText = limitController.text.trim();
    final limit = limitText.isEmpty ? null : double.tryParse(limitText.replaceAll(',', '.'));

    controller.addCreditCard(
      name: name,
      lastFourDigits: lastFourDigits,
      closingDay: closingDay,
      dueDay: dueDay,
      limit: limit,
      flag: selectedFlag.isEmpty ? null : selectedFlag,
      color: selectedColor,
    );
  }
}

