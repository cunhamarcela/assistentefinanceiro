import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/cards/app_card.dart';
import '../../domain/entities/category.dart';

class CategorySelectorWidget extends StatelessWidget {
  final List<ExpenseCategory> availableCategories;
  final List<ExpenseCategory> selectedCategories;
  final Function(String categoryId) onCategoryToggle;
  final VoidCallback? onAddCategory;
  final VoidCallback? onInitializeDefaults;

  const CategorySelectorWidget({
    super.key,
    required this.availableCategories,
    required this.selectedCategories,
    required this.onCategoryToggle,
    this.onAddCategory,
    this.onInitializeDefaults,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selecionar Categorias',
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textDark,
              ),
            ),
            if (onAddCategory != null)
              TextButton.icon(
                onPressed: onAddCategory,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nova'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        
        Text(
          'Escolha as categorias que deseja incluir no seu orçamento',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Categorias Selecionadas
        if (selectedCategories.isNotEmpty) ...[
          Text(
            'Categorias Selecionadas (${selectedCategories.length})',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: selectedCategories.map((category) => 
              _buildSelectedCategoryChip(category)
            ).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Categorias Disponíveis
        if (availableCategories.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  'Categorias Disponíveis',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (availableCategories.length < 5 && onInitializeDefaults != null)
                TextButton.icon(
                  onPressed: onInitializeDefaults,
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text(
                    'Padrões',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildAvailableCategoriesGrid(),
        ] else if (selectedCategories.isEmpty) ...[
          AppCard(
            child: Column(
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 48,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Nenhuma categoria disponível',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Crie uma nova categoria para começar',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectedCategoryChip(ExpenseCategory category) {
    return Container(
      decoration: BoxDecoration(
        color: category.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: category.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onCategoryToggle(category.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  category.iconData,
                  size: 16,
                  color: category.color,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  category.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: category.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.close,
                  size: 14,
                  color: category.color.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableCategoriesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: availableCategories.length,
      itemBuilder: (context, index) {
        final category = availableCategories[index];
        return _buildAvailableCategoryCard(category);
      },
    );
  }

  Widget _buildAvailableCategoryCard(ExpenseCategory category) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onCategoryToggle(category.id),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  category.iconData,
                  color: category.color,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  category.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.add_circle_outline,
                color: AppColors.primary.withOpacity(0.7),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
