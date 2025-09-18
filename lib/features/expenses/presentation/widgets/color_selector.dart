import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ColorSelector extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorSelected;

  const ColorSelector({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  static const List<Color> availableColors = [
    // Cores primárias
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFFF59E0B), // Amber
    Color(0xFFEAB308), // Yellow
    Color(0xFF84CC16), // Lime
    Color(0xFF22C55E), // Green
    Color(0xFF10B981), // Emerald
    Color(0xFF14B8A6), // Teal
    Color(0xFF06B6D4), // Cyan
    Color(0xFF0EA5E9), // Sky
    Color(0xFF3B82F6), // Blue
    
    // Cores secundárias
    Color(0xFF7C3AED), // Purple
    Color(0xFFBE185D), // Rose
    Color(0xFFDC2626), // Red dark
    Color(0xFFEA580C), // Orange dark
    Color(0xFFD97706), // Amber dark
    Color(0xFFCA8A04), // Yellow dark
    Color(0xFF65A30D), // Lime dark
    Color(0xFF16A34A), // Green dark
    Color(0xFF059669), // Emerald dark
    Color(0xFF0D9488), // Teal dark
    Color(0xFF0891B2), // Cyan dark
    Color(0xFF0284C7), // Sky dark
    Color(0xFF2563EB), // Blue dark
    Color(0xFF4F46E5), // Indigo dark
    
    // Tons de cinza
    Color(0xFF374151), // Gray 700
    Color(0xFF4B5563), // Gray 600
    Color(0xFF6B7280), // Gray 500
    Color(0xFF9CA3AF), // Gray 400
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
          // Calcular quantas cores cabem por linha
          final itemWidth = 40.w;
          final spacing = 12.w;
          final itemsPerRow = ((constraints.maxWidth + spacing) / (itemWidth + spacing)).floor();
          final totalRows = (availableColors.length / itemsPerRow).ceil();
          
          return SizedBox(
            height: (totalRows * (40.w + 12.h) - 12.h).clamp(120.h, 200.h),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: spacing,
                runSpacing: 12.h,
                alignment: WrapAlignment.start,
                children: availableColors.map((color) {
                  final isSelected = selectedColor.value == color.value;
                  
                  return GestureDetector(
                    onTap: () {
                      onColorSelected(color);
                    },
                    child: Container(
                      width: itemWidth,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: isSelected ? 3 : 0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected 
                                ? color.withOpacity(0.4)
                                : Colors.black.withOpacity(0.1),
                            blurRadius: isSelected ? 6 : 2,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: _getContrastColor(color),
                              size: 18.w,
                            )
                          : null,
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

  /// Retorna cor de contraste (branco ou preto) baseada na luminância
  Color _getContrastColor(Color color) {
    // Calcular luminância
    final luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    
    // Se a cor é escura, usar branco; se clara, usar preto
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}


