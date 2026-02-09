import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/credit_card.dart';

/// Widget para exibir um cartão de crédito
class CreditCardWidget extends StatelessWidget {
  final CreditCard card;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CreditCardWidget({
    super.key,
    required this.card,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getCardColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color,
              color.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Nome e ações
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (card.flag != null)
                    Text(
                      card.flag!,
                      style: TextStyle(
                        color: AppColors.colorTextOnDark,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  Row(
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.colorTextOnDark),
                          onPressed: onEdit,
                          iconSize: 20.sp,
                        ),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.colorTextOnDark),
                          onPressed: onDelete,
                          iconSize: 20.sp,
                        ),
                    ],
                  ),
                ],
              ),

              const Spacer(),

              // Número do cartão (últimos 4 dígitos)
              Text(
                '•••• •••• •••• ${card.lastFourDigits}',
                style: TextStyle(
                  color: AppColors.colorTextOnDark,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),

              SizedBox(height: 16.h),

              // Nome e informações
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        style: TextStyle(
                          color: AppColors.colorTextOnDark,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      if (card.limit != null)
                        Text(
                          'Limite: R\$ ${card.limit!.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppColors.colorTextOnDark.withOpacity(0.8),
                            fontSize: 12.sp,
                          ),
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Fecha dia ${card.closingDay}',
                        style: TextStyle(
                          color: AppColors.colorTextOnDark.withOpacity(0.8),
                          fontSize: 11.sp,
                        ),
                      ),
                      Text(
                        'Vence dia ${card.dueDay}',
                        style: TextStyle(
                          color: AppColors.colorTextOnDark.withOpacity(0.8),
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCardColor() {
    if (card.color != null) {
      try {
        return Color(int.parse(card.color!, radix: 16));
      } catch (e) {
        // Fallback para cor padrão
      }
    }
    
    // Cor padrão baseada na bandeira
    switch (card.flag?.toLowerCase()) {
      case 'visa':
        return const Color(0xFF1976D2); // Blue 700
      case 'mastercard':
        return const Color(0xFFF57C00); // Orange 700
      case 'elo':
        return const Color(0xFFFBC02D); // Yellow 700
      case 'amex':
        return const Color(0xFF388E3C); // Green 700
      case 'hipercard':
        return const Color(0xFFD32F2F); // Red 700
      default:
        return const Color(0xFF7B1FA2); // Purple 700
    }
  }
}

