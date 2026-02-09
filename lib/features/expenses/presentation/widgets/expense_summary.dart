import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';

class ExpenseSummary extends StatelessWidget {
  final double totalMonth;
  final double totalWeek;
  final double totalToday;
  final int expenseCount;
  final double averagePerDay;

  const ExpenseSummary({
    super.key,
    required this.totalMonth,
    required this.totalWeek,
    required this.totalToday,
    required this.expenseCount,
    required this.averagePerDay,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.colorBrandPrimary,
              AppColors.colorBrandDark,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.colorTextOnDark,
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Resumo Financeiro',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.colorTextOnDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            
            // Total do mês (destaque limpo)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total do Mês',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.colorTextOnDark.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  CurrencyFormatter.formatCurrency(totalMonth),
                  style: AppTextStyles.currencyLarge.copyWith(
                    color: AppColors.colorTextOnDark,
                    fontSize: 36.sp,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24.h),
            
            // Estatísticas em grid
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Hoje',
                    CurrencyFormatter.formatCurrency(totalToday),
                    Icons.today,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildStatItem(
                    'Esta Semana',
                    CurrencyFormatter.formatCurrency(totalWeek),
                    Icons.date_range,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Despesas',
                    '$expenseCount',
                    Icons.receipt,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildStatItem(
                    'Média/Dia',
                    CurrencyFormatter.formatCurrency(averagePerDay),
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.colorTextOnDark.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.colorTextOnDark.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.colorTextOnDark.withOpacity(0.7),
                size: 16.sp,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.colorTextOnDark.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.colorTextOnDark,
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }
}
