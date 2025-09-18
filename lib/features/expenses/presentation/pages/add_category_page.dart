import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/category.dart';
import '../controllers/category_controller.dart';
import '../widgets/icon_selector.dart';
import '../widgets/color_selector.dart';

class AddCategoryPage extends GetView<CategoryController> {
  const AddCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Verificar se é edição
    final ExpenseCategory? categoryToEdit = Get.arguments as ExpenseCategory?;
    final isEditing = categoryToEdit != null;

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: categoryToEdit?.name ?? '');
    final keywordsController = TextEditingController(
      text: categoryToEdit?.keywords.join(', ') ?? '',
    );
    
    final selectedIcon = (categoryToEdit?.icon ?? 'category').obs;
    final selectedColor = (categoryToEdit?.color ?? AppColors.primary).obs;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Categoria' : 'Nova Categoria',
          style: AppTextStyles.headline3.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          if (isEditing && categoryToEdit != null && !categoryToEdit.isDefault)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => controller.confirmDeleteCategory(categoryToEdit),
              tooltip: 'Excluir categoria',
            ),
        ],
      ),
      body: Form(
        key: formKey,
        child: Column(
          children: [
            // Conteúdo principal
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview simples da categoria
                    _buildSimplePreview(selectedIcon, selectedColor, nameController),
                    
                    SizedBox(height: 24.h),
                    
                    // Campo nome
                    _buildNameField(nameController),
                    
                    SizedBox(height: 24.h),
                    
                    // Seletor de ícone
                    _buildIconSelector(selectedIcon),
                    
                    SizedBox(height: 24.h),
                    
                    // Seletor de cor
                    _buildColorSelector(selectedColor),
                    
                    SizedBox(height: 24.h),
                    
                    // Campo palavras-chave
                    _buildKeywordsField(keywordsController),
                    
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
            
            // Botão fixo na parte inferior
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: _buildSaveButton(
                  formKey,
                  isEditing,
                  categoryToEdit,
                  nameController,
                  keywordsController,
                  selectedIcon,
                  selectedColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplePreview(
    RxString selectedIcon,
    Rx<Color> selectedColor,
    TextEditingController nameController,
  ) {
    return Obx(() => Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: selectedColor.value,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              _getIconData(selectedIcon.value),
              color: Colors.white,
              size: 24.w,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nameController.text.isEmpty ? 'Nome da categoria' : nameController.text,
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  'Preview da categoria',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildNameField(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nome da Categoria',
          style: AppTextStyles.subtitle2.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Ex: Transporte, Lazer, Educação',
            prefixIcon: Icon(Icons.label_outline, color: AppColors.primary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor, insira o nome da categoria';
            }
            
            if (value.length > 30) {
              return 'Nome deve ter no máximo 30 caracteres';
            }
            
            return null;
          },
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
      ],
    );
  }

  Widget _buildIconSelector(RxString selectedIcon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Escolha um Ícone',
          style: AppTextStyles.subtitle2.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 12.h),
        Obx(() => IconSelector(
          selectedIcon: selectedIcon.value,
          onIconSelected: (icon) {
            selectedIcon.value = icon;
          },
        )),
      ],
    );
  }

  Widget _buildColorSelector(Rx<Color> selectedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Escolha uma Cor',
          style: AppTextStyles.subtitle2.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 12.h),
        Obx(() => ColorSelector(
          selectedColor: selectedColor.value,
          onColorSelected: (color) {
            selectedColor.value = color;
          },
        )),
      ],
    );
  }

  Widget _buildKeywordsField(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Palavras-chave',
          style: AppTextStyles.subtitle2.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Ex: uber, taxi, ônibus, gasolina (separadas por vírgula)',
            prefixIcon: Icon(Icons.tag_outlined, color: AppColors.primary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor, insira pelo menos uma palavra-chave';
            }
            
            final keywords = value.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
            if (keywords.isEmpty) {
              return 'Por favor, insira pelo menos uma palavra-chave válida';
            }
            
            return null;
          },
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16.w, color: AppColors.primary),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Use palavras que aparecem nas descrições das despesas para categorização automática',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    final iconMap = {
      'category': Icons.category,
      'restaurant': Icons.restaurant,
      'local_gas_station': Icons.local_gas_station,
      'shopping_cart': Icons.shopping_cart,
      'home': Icons.home,
      'health_and_safety': Icons.health_and_safety,
      'school': Icons.school,
      'sports_esports': Icons.sports_esports,
      'work': Icons.work,
      'flight': Icons.flight,
      'movie': Icons.movie,
      'fitness_center': Icons.fitness_center,
      'pets': Icons.pets,
      'child_care': Icons.child_care,
      'phone': Icons.phone,
      'wifi': Icons.wifi,
      'electric_bolt': Icons.electric_bolt,
      'water_drop': Icons.water_drop,
      'local_laundry_service': Icons.local_laundry_service,
      'cut': Icons.cut,
    };
    
    return iconMap[iconName] ?? Icons.category;
  }

  Widget _buildSaveButton(
    GlobalKey<FormState> formKey,
    bool isEditing,
    ExpenseCategory? categoryToEdit,
    TextEditingController nameController,
    TextEditingController keywordsController,
    RxString selectedIcon,
    Rx<Color> selectedColor,
  ) {
    return Obx(() => SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: controller.isSaving.value
            ? null
            : () => _saveCategory(
                  formKey,
                  isEditing,
                  categoryToEdit,
                  nameController,
                  keywordsController,
                  selectedIcon.value,
                  selectedColor.value,
                ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child: controller.isSaving.value
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Salvando...',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEditing ? Icons.save_outlined : Icons.add,
                    color: Colors.white,
                    size: 20.w,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    isEditing ? 'Salvar Alterações' : 'Criar Categoria',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    ));
  }

  void _saveCategory(
    GlobalKey<FormState> formKey,
    bool isEditing,
    ExpenseCategory? categoryToEdit,
    TextEditingController nameController,
    TextEditingController keywordsController,
    String selectedIcon,
    Color selectedColor,
  ) {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final name = nameController.text.trim();
    final keywordsText = keywordsController.text.trim();
    final keywords = keywordsText
        .split(',')
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList();

    if (isEditing && categoryToEdit != null) {
      controller.updateCategory(
        id: categoryToEdit.id,
        name: name,
        icon: selectedIcon,
        color: selectedColor,
        keywords: keywords,
      );
    } else {
      controller.addCategory(
        name: name,
        icon: selectedIcon,
        color: selectedColor,
        keywords: keywords,
      );
    }
  }
}
