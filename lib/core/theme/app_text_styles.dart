import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Estilos de texto padronizados para o aplicativo
class AppTextStyles {
  // Headlines - Usam colorTextPrimary (Navy Dark) por padrão conforme solicitado
  static const TextStyle headline1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.colorTextPrimary,
    height: 1.2,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.colorTextPrimary,
    height: 1.3,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.colorTextPrimary,
    height: 1.3,
  );

  // Subtítulos - Usam colorTextSecondary (Navy)
  static const TextStyle subtitle1 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.colorTextSecondary,
    height: 1.4,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.colorTextSecondary,
    height: 1.4,
  );

  // Corpo do texto - Usam colorTextMuted (Blue Medium) ou Secondary
  // O user pediu "Textos auxiliares -> colorTextMuted".
  // Corpo normal geralmente é mais legível que Muted. Vou usar colorTextSecondary para body.
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.colorTextSecondary,
    height: 1.5,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.colorTextSecondary,
    height: 1.5,
  );

  // Texto pequeno - Muted
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.colorTextMuted,
    height: 1.4,
  );

  // Botões
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.colorTextOnDark,
    height: 1.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.colorTextOnDark,
    height: 1.2,
  );

  // Variações de cor
  // Mantendo compatibilidade mas apontando para as novas cores
  static TextStyle headline1Dark = headline1.copyWith(color: AppColors.colorTextPrimary);
  static TextStyle headline2Dark = headline2.copyWith(color: AppColors.colorTextPrimary);
  static TextStyle headline3Dark = headline3.copyWith(color: AppColors.colorTextPrimary);
  static TextStyle subtitle1Dark = subtitle1.copyWith(color: AppColors.colorTextPrimary);
  static TextStyle subtitle2Dark = subtitle2.copyWith(color: AppColors.colorTextPrimary);
  static TextStyle body1Dark = body1.copyWith(color: AppColors.colorTextPrimary);
  static TextStyle body2Dark = body2.copyWith(color: AppColors.colorTextPrimary);
  static TextStyle captionDark = caption.copyWith(color: AppColors.colorTextPrimary);
  
  // Variações Light (Texto sobre fundo escuro)
  static TextStyle headline1Light = headline1.copyWith(color: AppColors.colorTextOnDark);
  static TextStyle headline2Light = headline2.copyWith(color: AppColors.colorTextOnDark);
  static TextStyle headline3Light = headline3.copyWith(color: AppColors.colorTextOnDark);
  static TextStyle body1Light = body1.copyWith(color: AppColors.colorTextOnDark);

  // Estilos especiais
  static const TextStyle currency = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.colorBrandPrimary,
    height: 1.2,
  );

  static const TextStyle currencyLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.colorBrandPrimary,
    height: 1.1,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.colorTextMuted,
    height: 1.3,
    letterSpacing: 0.5,
  );

  // Novos estilos para compatibilidade
  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.colorTextPrimary,
    height: 1.3,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.colorTextPrimary,
    height: 1.3,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.colorTextSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.colorTextMuted,
    height: 1.5,
  );

  // Alias para compatibilidade
  static const TextStyle bodyLarge = body1;
  static const TextStyle labelSmall = caption;
  static const TextStyle labelMedium = label;
  static const TextStyle displaySmall = headline3;
}
