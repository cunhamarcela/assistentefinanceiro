import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final void Function()? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final Color? borderColor;
  final double? borderRadius;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.inputFormatters,
    this.contentPadding,
    this.fillColor,
    this.borderColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFillColor = fillColor ?? AppColors.surface;
    final effectiveBorderColor = borderColor ?? AppColors.divider;
    final effectiveBorderRadius = borderRadius ?? AppRadius.input;
    final effectiveContentPadding = contentPadding ?? const EdgeInsets.all(AppSpacing.md);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.label,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        
        // Text Field
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          enabled: enabled,
          readOnly: readOnly,
          autofocus: autofocus,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          onTap: onTap,
          inputFormatters: inputFormatters,
          style: AppTextStyles.body1Dark.copyWith(
            color: enabled ? AppColors.textDark : AppColors.textSecondary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            errorText: errorText,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: AppColors.textSecondary,
                  )
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: effectiveFillColor,
            contentPadding: effectiveContentPadding,
            
            // Border styles
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(effectiveBorderRadius),
              borderSide: BorderSide(color: effectiveBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(effectiveBorderRadius),
              borderSide: BorderSide(color: effectiveBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(effectiveBorderRadius),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(effectiveBorderRadius),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(effectiveBorderRadius),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(effectiveBorderRadius),
              borderSide: BorderSide(color: effectiveBorderColor.withOpacity(0.5)),
            ),
            
            // Text styles
            hintStyle: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
            helperStyle: AppTextStyles.caption,
            errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
            
            // Counter
            counterStyle: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }
}

// Variações específicas do campo de texto
class EmailTextField extends CustomTextField {
  const EmailTextField({
    super.key,
    super.controller,
    super.label = 'Email',
    super.hint = 'Digite seu email',
    super.validator,
    super.onChanged,
    super.onFieldSubmitted,
  }) : super(
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          textInputAction: TextInputAction.next,
        );
}

class PasswordTextField extends CustomTextField {
  final bool isVisible;
  final VoidCallback? onToggleVisibility;

  const PasswordTextField({
    super.key,
    super.controller,
    super.label = 'Senha',
    super.hint = 'Digite sua senha',
    super.validator,
    super.onChanged,
    super.onFieldSubmitted,
    this.isVisible = false,
    this.onToggleVisibility,
  }) : super(
          obscureText: !isVisible,
          prefixIcon: Icons.lock_outlined,
          textInputAction: TextInputAction.done,
        );

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      obscureText: !isVisible,
      prefixIcon: Icons.lock_outlined,
      textInputAction: textInputAction,
      suffixIcon: onToggleVisibility != null
          ? IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20.sp,
              ),
            )
          : null,
    );
  }
}

class SearchTextField extends CustomTextField {
  const SearchTextField({
    super.key,
    super.controller,
    super.hint = 'Pesquisar...',
    super.onChanged,
    super.onFieldSubmitted,
  }) : super(
          prefixIcon: Icons.search,
          textInputAction: TextInputAction.search,
        );
}

class CurrencyTextField extends CustomTextField {
  const CurrencyTextField({
    super.key,
    super.controller,
    super.label = 'Valor',
    super.hint = 'R\$ 0,00',
    super.validator,
    super.onChanged,
    super.onFieldSubmitted,
  }) : super(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: Icons.attach_money,
          textInputAction: TextInputAction.done,
        );
}
