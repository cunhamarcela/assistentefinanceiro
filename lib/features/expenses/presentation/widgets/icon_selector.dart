import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';

class IconSelector extends StatelessWidget {
  final String selectedIcon;
  final Function(String) onIconSelected;

  const IconSelector({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
  });

  static const List<Map<String, dynamic>> availableIcons = [
    {'name': 'category', 'icon': Icons.category, 'label': 'Geral'},
    {'name': 'restaurant', 'icon': Icons.restaurant, 'label': 'Alimentação'},
    {'name': 'local_gas_station', 'icon': Icons.local_gas_station, 'label': 'Combustível'},
    {'name': 'shopping_cart', 'icon': Icons.shopping_cart, 'label': 'Compras'},
    {'name': 'home', 'icon': Icons.home, 'label': 'Casa'},
    {'name': 'health_and_safety', 'icon': Icons.health_and_safety, 'label': 'Saúde'},
    {'name': 'school', 'icon': Icons.school, 'label': 'Educação'},
    {'name': 'sports_esports', 'icon': Icons.sports_esports, 'label': 'Lazer'},
    {'name': 'work', 'icon': Icons.work, 'label': 'Trabalho'},
    {'name': 'flight', 'icon': Icons.flight, 'label': 'Viagem'},
    {'name': 'movie', 'icon': Icons.movie, 'label': 'Cinema'},
    {'name': 'fitness_center', 'icon': Icons.fitness_center, 'label': 'Academia'},
    {'name': 'pets', 'icon': Icons.pets, 'label': 'Pets'},
    {'name': 'child_care', 'icon': Icons.child_care, 'label': 'Crianças'},
    {'name': 'phone', 'icon': Icons.phone, 'label': 'Telefone'},
    {'name': 'wifi', 'icon': Icons.wifi, 'label': 'Internet'},
    {'name': 'electric_bolt', 'icon': Icons.electric_bolt, 'label': 'Energia'},
    {'name': 'water_drop', 'icon': Icons.water_drop, 'label': 'Água'},
    {'name': 'local_laundry_service', 'icon': Icons.local_laundry_service, 'label': 'Lavanderia'},
    {'name': 'cut', 'icon': Icons.cut, 'label': 'Beleza'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calcular quantos ícones cabem por linha
          final itemWidth = 65.w;
          final spacing = 12.w;
          final itemsPerRow = ((constraints.maxWidth + spacing) / (itemWidth + spacing)).floor();
          final totalRows = (availableIcons.length / itemsPerRow).ceil();
          
          return SizedBox(
            height: (totalRows * (65.w + 12.h) - 12.h).clamp(200.h, 300.h),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: spacing,
                runSpacing: 12.h,
                children: availableIcons.map((iconData) {
                  final isSelected = selectedIcon == iconData['name'];

                  return GestureDetector(
                    onTap: () {
                      onIconSelected(iconData['name']);
                    },
                    child: Container(
                      width: itemWidth,
                      height: 65.w,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            iconData['icon'],
                            color: isSelected ? Colors.white : AppColors.primary,
                            size: 24.w,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            iconData['label'],
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}


