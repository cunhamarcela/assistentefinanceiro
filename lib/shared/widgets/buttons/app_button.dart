import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';

/// Botão principal do aplicativo com variações de estilo
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool filled;
  final bool loading;
  final IconData? icon;
  final AppButtonSize size;
  final Color? color;
  final Color? textColor;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.filled = true,
    this.loading = false,
    this.icon,
    this.size = AppButtonSize.medium,
    this.color,
    this.textColor,
    this.width,
  });

  /// Botão preenchido (padrão)
  const AppButton.filled({
    super.key,
    required this.text,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.size = AppButtonSize.medium,
    this.color,
    this.textColor,
    this.width,
  }) : filled = true;

  /// Botão com borda
  const AppButton.outlined({
    super.key,
    required this.text,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.size = AppButtonSize.medium,
    this.color,
    this.textColor,
    this.width,
  }) : filled = false;

  /// Botão pequeno
  const AppButton.small({
    super.key,
    required this.text,
    this.onPressed,
    this.filled = true,
    this.loading = false,
    this.icon,
    this.color,
    this.textColor,
    this.width,
  }) : size = AppButtonSize.small;

  /// Botão grande
  const AppButton.large({
    super.key,
    required this.text,
    this.onPressed,
    this.filled = true,
    this.loading = false,
    this.icon,
    this.color,
    this.textColor,
    this.width,
  }) : size = AppButtonSize.large;

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primary;
    final isEnabled = onPressed != null && !loading;

    return SizedBox(
      width: width ?? double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? buttonColor : Colors.transparent,
          foregroundColor: _getTextColor(buttonColor),
          elevation: filled ? AppElevation.button : 0,
          padding: _getPadding(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            side: filled
                ? BorderSide.none
                : BorderSide(
                    color: isEnabled ? buttonColor : AppColors.textSecondary,
                    width: 2,
                  ),
          ),
          disabledBackgroundColor: filled
              ? AppColors.textSecondary.withOpacity(0.3)
              : Colors.transparent,
          disabledForegroundColor: AppColors.textSecondary,
        ),
        child: loading
            ? SizedBox(
                height: _getIconSize(),
                width: _getIconSize(),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    filled ? Colors.white : buttonColor,
                  ),
                ),
              )
            : _buildButtonContent(),
      ),
    );
  }

  Widget _buildButtonContent() {
    final buttonColor = color ?? AppColors.primary;
    final effectiveTextColor = _getTextColor(buttonColor);
    final effectiveStyle = _getTextStyle().copyWith(color: effectiveTextColor);
    
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize(), color: effectiveTextColor),
          const SizedBox(width: AppSpacing.sm),
          Text(text, style: effectiveStyle),
        ],
      );
    }
    return Text(text, style: effectiveStyle);
  }

  Color _getTextColor(Color buttonColor) {
    if (textColor != null) return textColor!;
    return filled ? AppColors.colorTextOnDark : buttonColor;
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTextStyles.buttonSmall;
      case AppButtonSize.medium:
        return AppTextStyles.button;
      case AppButtonSize.large:
        return AppTextStyles.button.copyWith(fontSize: 18);
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        );
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        );
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        );
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 20;
      case AppButtonSize.large:
        return 24;
    }
  }
}

/// Tamanhos disponíveis para o botão
enum AppButtonSize {
  small,
  medium,
  large,
}
