import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';

/// Configuração do tema principal do aplicativo
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    // Cores principais
    primaryColor: AppColors.colorBrandPrimary,
    scaffoldBackgroundColor: AppColors.colorBackgroundPrimary,
    colorScheme: const ColorScheme.light(
      primary: AppColors.colorBrandPrimary,
      secondary: AppColors.colorActionPrimary,
      surface: AppColors.colorSurfaceCard,
      background: AppColors.colorBackgroundPrimary,
      error: AppColors.colorError,
      onPrimary: AppColors.colorTextOnDark,
      onSecondary: AppColors.colorTextOnDark,
      onSurface: AppColors.colorTextPrimary,
      onBackground: AppColors.colorTextPrimary,
      onError: AppColors.colorTextOnDark,
    ),

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.colorBrandDark,
      foregroundColor: AppColors.colorTextOnDark,
      elevation: AppElevation.appBar,
      centerTitle: true,
      titleTextStyle: AppTextStyles.headline2.copyWith(color: AppColors.colorTextOnDark),
      iconTheme: const IconThemeData(color: AppColors.colorTextOnDark),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),

    // Botões elevados (Botão Primário)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.colorActionPrimary,
        foregroundColor: AppColors.colorTextOnDark,
        elevation: AppElevation.button,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: AppTextStyles.button,
      ),
    ),

    // Botões de texto
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.colorBrandSoft,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: AppTextStyles.button.copyWith(color: AppColors.colorBrandSoft),
      ),
    ),

    // Botões outlined
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.colorBrandPrimary,
        side: const BorderSide(color: AppColors.colorBrandPrimary, width: 2),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: AppTextStyles.button.copyWith(color: AppColors.colorBrandPrimary),
      ),
    ),

    // Cards
    cardTheme: CardTheme(
      color: AppColors.colorSurfaceCard,
      elevation: AppElevation.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.colorBorderSubtle, width: 1),
      ),
      margin: const EdgeInsets.all(AppSpacing.sm),
    ),

    // Campos de texto
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.colorSurfaceCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.colorBorderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.colorBorderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.colorBrandPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.colorError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.colorError, width: 2),
      ),
      contentPadding: const EdgeInsets.all(AppSpacing.md),
      labelStyle: AppTextStyles.body1,
      hintStyle: AppTextStyles.body1.copyWith(color: AppColors.colorTextMuted),
    ),

    // Lista
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      titleTextStyle: AppTextStyles.body1.copyWith(color: AppColors.colorTextPrimary),
      subtitleTextStyle: AppTextStyles.body2.copyWith(color: AppColors.colorTextSecondary),
    ),

    // Bottom Navigation Bar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.colorSurfaceCard,
      selectedItemColor: AppColors.colorBrandPrimary,
      unselectedItemColor: AppColors.colorTextMuted,
      elevation: 8,
      selectedLabelStyle: AppTextStyles.caption,
      unselectedLabelStyle: AppTextStyles.caption,
    ),

    // Floating Action Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.colorActionPrimary,
      foregroundColor: AppColors.colorTextOnDark,
      elevation: AppElevation.button,
    ),

    // Dialog
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.colorSurfaceCard,
      elevation: AppElevation.dialog,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
      titleTextStyle: AppTextStyles.headline3.copyWith(color: AppColors.colorTextPrimary),
      contentTextStyle: AppTextStyles.body1.copyWith(color: AppColors.colorTextPrimary),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.colorBorderSubtle,
      thickness: 1,
      space: 1,
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.colorBackgroundSecondary,
      selectedColor: AppColors.colorBrandSoft,
      labelStyle: AppTextStyles.body2.copyWith(color: AppColors.colorTextPrimary),
      secondaryLabelStyle: AppTextStyles.body2.copyWith(color: AppColors.colorTextOnDark),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.colorActionPrimary;
        }
        return AppColors.colorTextMuted;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.colorActionPrimary.withOpacity(0.3);
        }
        return AppColors.colorBorderSubtle;
      }),
    ),

    // Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.colorActionPrimary;
        }
        return Colors.transparent;
      }),
      checkColor: MaterialStateProperty.all(AppColors.colorTextOnDark),
      side: const BorderSide(color: AppColors.colorBorderSubtle, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
    ),

    // Radio
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.colorActionPrimary;
        }
        return AppColors.colorTextMuted;
      }),
    ),

    // Slider
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.colorActionPrimary,
      inactiveTrackColor: AppColors.colorBorderSubtle,
      thumbColor: AppColors.colorActionPrimary,
      overlayColor: Color(0x1A3CB371),
    ),

    // Progress Indicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.colorBrandSoft,
      linearTrackColor: AppColors.colorBorderSubtle,
      circularTrackColor: AppColors.colorBorderSubtle,
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.colorBrandDark,
      contentTextStyle: AppTextStyles.body1.copyWith(color: AppColors.colorTextOnDark),
      actionTextColor: AppColors.colorActionPrimary,
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
      ),
    ),
  );

  // Tema escuro (para implementação futura)
  static ThemeData get darkTheme => lightTheme.copyWith(
    // Implementar tema escuro se necessário
  );
}
