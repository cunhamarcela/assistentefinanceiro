import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/financial_goal.dart';

/// Widget que exibe o resumo das metas financeiras
class GoalsSummaryWidget extends StatelessWidget {
  final List<FinancialGoal> goals;
  final VoidCallback? onTap;

  const GoalsSummaryWidget({
    super.key,
    required this.goals,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final summary = _calculateSummary();
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.secondary.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resumo das Metas',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(summary['progressPercentage']),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${summary['goalsCount']} metas',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progresso Geral',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${(summary['progressPercentage'] * 100).toStringAsFixed(1)}%',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 8.h),
                
                Container(
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (summary['progressPercentage'] as double).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getProgressColor(summary['progressPercentage']),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            // Financial Summary
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Orçamento Total',
                    CurrencyFormatter.formatCurrency(summary['totalBudget']),
                    AppColors.primary,
                    Icons.account_balance_wallet,
                  ),
                ),
                
                SizedBox(width: 16.w),
                
                Expanded(
                  child: _buildSummaryItem(
                    'Total Gasto',
                    CurrencyFormatter.formatCurrency(summary['totalSpent']),
                    AppColors.error,
                    Icons.money_off,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Restante',
                    CurrencyFormatter.formatCurrency(summary['totalRemaining']),
                    AppColors.success,
                    Icons.savings,
                  ),
                ),
                
                SizedBox(width: 16.w),
                
                Expanded(
                  child: _buildSummaryItem(
                    'Metas Excedidas',
                    '${summary['exceededGoals']}',
                    AppColors.warning,
                    Icons.warning,
                  ),
                ),
              ],
            ),
            
            // Status Message
            if (summary['exceededGoals'] > 0) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: AppColors.warning,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Você excedeu ${summary['exceededGoals']} meta(s) este mês. Revise seus gastos!',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16.sp,
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateSummary() {
    if (goals.isEmpty) {
      return {
        'totalBudget': 0.0,
        'totalSpent': 0.0,
        'totalRemaining': 0.0,
        'progressPercentage': 0.0,
        'goalsCount': 0,
        'exceededGoals': 0,
      };
    }

    final totalBudget = goals.fold<double>(0.0, (sum, goal) => sum + goal.monthlyLimit);
    final totalSpent = goals.fold<double>(0.0, (sum, goal) => sum + goal.currentSpent);
    final totalRemaining = totalBudget - totalSpent;
    final progressPercentage = totalBudget > 0 ? totalSpent / totalBudget : 0.0;
    final exceededGoals = goals.where((goal) => goal.isExceeded).length;

    return {
      'totalBudget': totalBudget,
      'totalSpent': totalSpent,
      'totalRemaining': totalRemaining,
      'progressPercentage': progressPercentage,
      'goalsCount': goals.length,
      'exceededGoals': exceededGoals,
    };
  }

  Color _getStatusColor(double progressPercentage) {
    if (progressPercentage >= 1.0) return AppColors.error;
    if (progressPercentage >= 0.8) return AppColors.warning;
    if (progressPercentage >= 0.5) return AppColors.primary;
    return AppColors.success;
  }

  Color _getProgressColor(double progressPercentage) {
    if (progressPercentage >= 1.0) return AppColors.error;
    if (progressPercentage >= 0.8) return AppColors.warning;
    return AppColors.primary;
  }
}
