import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final ExpenseCategory? category;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.category,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Ícone da categoria
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: (category?.color ?? AppColors.textSecondary)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Icon(
                  category?.iconData ?? Icons.more_horiz,
                  color: category?.color ?? AppColors.textSecondary,
                  size: 24.sp,
                ),
              ),
              
              SizedBox(width: 12.w),
              
              // Informações da despesa
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Descrição
                    Text(
                      expense.description,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 4.h),
                    
                    // Categoria e data
                    Row(
                      children: [
                        Text(
                          category?.name ?? 'Outros',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: category?.color ?? AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          ' • ',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          DateFormatter.formatRelativeDate(expense.date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    
                    // Notas (se houver)
                    if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        expense.notes!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              SizedBox(width: 12.w),
              
              // Valor
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatCurrency(expense.amount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                  
                  SizedBox(height: 4.h),
                  
                  // Hora
                  Text(
                    DateFormatter.formatTime(expense.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
