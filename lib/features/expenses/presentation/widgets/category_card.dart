import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/category.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';

class CategoryCard extends StatelessWidget {
  final ExpenseCategory category;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho com ícone e ações
              Row(
                children: [
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      color: category.color,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      category.iconData,
                      color: Colors.white,
                      size: 16.w,
                    ),
                  ),
                  const Spacer(),
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 16.w,
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit?.call();
                            break;
                          case 'delete':
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit, size: 14),
                                const SizedBox(width: 6),
                                Text('Editar', style: AppTextStyles.caption.copyWith(fontSize: 11.sp)),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.delete, size: 14, color: Colors.red),
                                const SizedBox(width: 6),
                                Text('Excluir', style: AppTextStyles.caption.copyWith(fontSize: 11.sp, color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                      child: Icon(
                        Icons.more_vert,
                        size: 16.w,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              
              SizedBox(height: 8.h),
              
              // Nome da categoria
              Expanded(
                flex: 2,
                child: Text(
                  category.name,
                  style: AppTextStyles.subtitle2.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Tipo da categoria
              Text(
                category.isDefault ? 'Padrão' : 'Personalizada',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              
              SizedBox(height: 4.h),
              
              // Palavras-chave (primeiras 2)
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (category.keywords.isNotEmpty) ...[
                      Flexible(
                        child: Wrap(
                          spacing: 3.w,
                          runSpacing: 2.h,
                          children: category.keywords
                              .take(2)
                              .map((keyword) => Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4.w,
                                      vertical: 1.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: category.color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(3.r),
                                    ),
                                    child: Text(
                                      keyword,
                                      style: TextStyle(
                                        fontSize: 9.sp,
                                        color: _getKeywordTextColor(category.color),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      if (category.keywords.length > 2)
                        Padding(
                          padding: EdgeInsets.only(top: 2.h),
                          child: Text(
                            '+${category.keywords.length - 2} mais',
                            style: TextStyle(
                              fontSize: 8.sp,
                              color: AppColors.textSecondary.withOpacity(0.7),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Retorna cor de texto legível baseada na luminância da cor de fundo
  Color _getKeywordTextColor(Color backgroundColor) {
    // Calcular luminância da cor de fundo
    final luminance = backgroundColor.computeLuminance();
    
    // Se a cor é muito clara, usar texto escuro; se escura, usar a própria cor
    if (luminance > 0.7) {
      return Colors.black87;
    } else if (luminance > 0.4) {
      return backgroundColor.withOpacity(0.8);
    } else {
      return backgroundColor;
    }
  }
}