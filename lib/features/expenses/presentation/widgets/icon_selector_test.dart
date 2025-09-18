import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';

class IconSelectorTest extends StatelessWidget {
  final String selectedIcon;
  final Function(String) onIconSelected;

  const IconSelectorTest({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
  });

  static const List<Map<String, dynamic>> availableIcons = [
    {'name': 'category', 'icon': Icons.category, 'label': 'Geral'},
    {'name': 'restaurant', 'icon': Icons.restaurant, 'label': 'Alimentação'},
    {'name': 'local_gas_station', 'icon': Icons.local_gas_station, 'label': 'Combustível'},
    {'name': 'shopping_cart', 'icon': Icons.shopping_cart, 'label': 'Compras'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120.h,
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: availableIcons.map((iconData) {
          final isSelected = selectedIcon == iconData['name'];
          
          return Expanded(
            child: GestureDetector(
              onTap: () {
                print('🎯 TESTE - Ícone clicado: ${iconData['name']}');
                onIconSelected(iconData['name']);
              },
              child: Container(
                margin: EdgeInsets.all(4.w),
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      iconData['icon'],
                      color: isSelected ? Colors.white : Colors.grey[700],
                      size: 24.w,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      iconData['label'],
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: isSelected ? Colors.white : Colors.grey[600],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
