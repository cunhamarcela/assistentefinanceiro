import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ColorSelectorTest extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorSelected;

  const ColorSelectorTest({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  static const List<Color> availableColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFFF59E0B), // Amber
    Color(0xFFEAB308), // Yellow
    Color(0xFF84CC16), // Lime
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: availableColors.map((color) {
          final isSelected = selectedColor.value == color.value;
          
          return Expanded(
            child: GestureDetector(
              onTap: () {
                print('🎨 TESTE - Cor clicada: $color');
                onColorSelected(color);
              },
              child: Container(
                margin: EdgeInsets.all(4.w),
                height: 50.w,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey.shade300,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20.w,
                      )
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
