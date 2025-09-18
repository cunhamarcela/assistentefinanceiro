import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool isOutlined;
  final Color? borderColor;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.isOutlined = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? AppColors.primary;
    final effectiveTextColor = textColor ?? AppColors.textPrimary;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(AppRadius.button);
    final effectivePadding = padding ?? const EdgeInsets.symmetric(vertical: AppSpacing.md);

    if (isOutlined) {
      return SizedBox(
        width: width,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: effectivePadding,
            shape: RoundedRectangleBorder(
              borderRadius: effectiveBorderRadius,
            ),
            side: BorderSide(
              color: borderColor ?? AppColors.primary,
              width: 2,
            ),
          ),
          child: _buildButtonContent(AppColors.primary),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          foregroundColor: effectiveTextColor,
          padding: effectivePadding,
          shape: RoundedRectangleBorder(
            borderRadius: effectiveBorderRadius,
          ),
          elevation: 2,
          shadowColor: effectiveBackgroundColor.withOpacity(0.3),
        ),
        child: _buildButtonContent(effectiveTextColor),
      ),
    );
  }

  Widget _buildButtonContent(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 20.w,
        height: 20.w,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20.sp,
            color: color,
          ),
          SizedBox(width: 8.w),
          Text(
            text,
            style: AppTextStyles.button.copyWith(color: color),
          ),
        ],
      );
    }

    return Text(
      text,
      style: AppTextStyles.button.copyWith(color: color),
    );
  }
}

// Variações específicas do botão
class PrimaryButton extends CustomButton {
  const PrimaryButton({
    super.key,
    required super.text,
    super.onPressed,
    super.isLoading = false,
    super.icon,
    super.width,
    super.height,
  });
}

class SecondaryButton extends CustomButton {
  const SecondaryButton({
    super.key,
    required super.text,
    super.onPressed,
    super.isLoading = false,
    super.icon,
    super.width,
    super.height,
  }) : super(
          isOutlined: true,
        );
}

class DangerButton extends CustomButton {
  const DangerButton({
    super.key,
    required super.text,
    super.onPressed,
    super.isLoading = false,
    super.icon,
    super.width,
    super.height,
  }) : super(
          backgroundColor: AppColors.error,
        );
}

class SuccessButton extends CustomButton {
  const SuccessButton({
    super.key,
    required super.text,
    super.onPressed,
    super.isLoading = false,
    super.icon,
    super.width,
    super.height,
  }) : super(
          backgroundColor: AppColors.success,
        );
}
