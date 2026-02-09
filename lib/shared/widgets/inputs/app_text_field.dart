import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';

/// Campo de texto principal do aplicativo com variações de estilo
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final void Function()? onEditingComplete;
  final void Function()? onTap;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final AppTextFieldType type;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onEditingComplete,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.type = AppTextFieldType.text,
    this.focusNode,
  });

  /// Campo de email
  const AppTextField.email({
    super.key,
    this.controller,
    this.label = 'Email',
    this.hint = 'Digite seu email',
    this.errorText,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onEditingComplete,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    this.focusNode,
  }) : obscureText = false,
       keyboardType = TextInputType.emailAddress,
       textInputAction = TextInputAction.next,
       prefixIcon = Icons.email_outlined,
       suffixIcon = null,
       maxLines = 1,
       maxLength = null,
       inputFormatters = null,
       type = AppTextFieldType.email;

  /// Campo de senha
  const AppTextField.password({
    super.key,
    this.controller,
    this.label = 'Senha',
    this.hint = 'Digite sua senha',
    this.errorText,
    this.obscureText = true,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onEditingComplete,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    this.suffixIcon,
    this.focusNode,
  }) : keyboardType = TextInputType.visiblePassword,
       textInputAction = TextInputAction.done,
       prefixIcon = Icons.lock_outlined,
       maxLines = 1,
       maxLength = null,
       inputFormatters = null,
       type = AppTextFieldType.password;

  /// Campo de moeda
  const AppTextField.currency({
    super.key,
    this.controller,
    this.label = 'Valor',
    this.hint = 'R\$ 0,00',
    this.errorText,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onEditingComplete,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    this.focusNode,
  }) : obscureText = false,
       keyboardType = const TextInputType.numberWithOptions(decimal: true),
       textInputAction = TextInputAction.next,
       prefixIcon = Icons.attach_money,
       suffixIcon = null,
       maxLines = 1,
       maxLength = null,
       inputFormatters = null,
       type = AppTextFieldType.currency;

  /// Campo de busca
  const AppTextField.search({
    super.key,
    this.controller,
    this.label,
    this.hint = 'Buscar...',
    this.errorText,
    this.onChanged,
    this.onFieldSubmitted,
    this.onEditingComplete,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    this.suffixIcon,
    this.focusNode,
  }) : obscureText = false,
       keyboardType = TextInputType.text,
       textInputAction = TextInputAction.search,
       prefixIcon = Icons.search,
       validator = null,
       maxLines = 1,
       maxLength = null,
       inputFormatters = null,
       type = AppTextFieldType.search;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.label,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          onEditingComplete: onEditingComplete,
          onTap: onTap,
          readOnly: readOnly,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: _getInputFormatters(),
          style: AppTextStyles.body1Dark,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon != null 
                ? Icon(
                    prefixIcon,
                    color: enabled ? AppColors.textSecondary : AppColors.textSecondary.withOpacity(0.5),
                  )
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? AppColors.surface : AppColors.surface.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider.withOpacity(0.5)),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            hintStyle: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
            errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  List<TextInputFormatter>? _getInputFormatters() {
    if (inputFormatters != null) return inputFormatters;
    
    switch (type) {
      case AppTextFieldType.currency:
        return [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ];
      case AppTextFieldType.email:
        return [
          FilteringTextInputFormatter.deny(RegExp(r'\s')), // Remove espaços
        ];
      default:
        return null;
    }
  }
}

/// Tipos de campo de texto disponíveis
enum AppTextFieldType {
  text,
  email,
  password,
  currency,
  search,
}