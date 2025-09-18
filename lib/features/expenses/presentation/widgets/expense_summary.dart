import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
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
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.secondary,
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
                  color: Colors.white,
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Resumo Financeiro',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            
            // Total do mês (destaque)
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total do Mês',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    CurrencyFormatter.formatCurrency(totalMonth),
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16.h),
            
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
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white.withOpacity(0.8),
                size: 16.sp,
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
