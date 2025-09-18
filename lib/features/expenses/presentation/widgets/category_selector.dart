import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/category.dart';

class CategorySelector extends StatelessWidget {
  final List<ExpenseCategory> categories;
  final String selectedCategoryId;
  final Function(String) onCategorySelected;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category.id == selectedCategoryId;
          
          return Container(
            margin: EdgeInsets.only(right: 12.w),
            child: GestureDetector(
              onTap: () => onCategorySelected(category.id),
              child: Column(
                children: [
                  Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? category.color
                          : category.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30.r),
                      border: isSelected
                          ? Border.all(color: category.color, width: 2)
                          : null,
                    ),
                    child: Icon(
                      category.iconData,
                      color: isSelected ? Colors.white : category.color,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                    SizedBox(
                    width: 60.w,
                    child: Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? category.color : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
