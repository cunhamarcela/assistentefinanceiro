import 'package:flutter/material.dart';

/// Paleta de cores do aplicativo Assistente Financeiro
/// Atualizada com Design Tokens Semânticos
class AppColors {
  // ---------------------------------------------------------------------------
  // DESIGN TOKENS (Nova Paleta)
  // ---------------------------------------------------------------------------

  // Brand
  static const Color colorBrandPrimary = Color(0xFF1A3D63); // Navy
  static const Color colorBrandDark = Color(0xFF0A1931);    // Navy Dark
  static const Color colorBrandSoft = Color(0xFF4A7FA7);    // Blue Medium

  // Backgrounds
  static const Color colorBackgroundPrimary = Color(0xFFF6FAFD);
  static const Color colorBackgroundSecondary = Color(0xFFB3CFE5);

  // Surfaces
  static const Color colorSurfaceCard = Color(0xFFFFFFFF);
  static const Color colorSurfaceElevated = Color(0xFFFFFFFF);

  // Text
  static const Color colorTextPrimary = Color(0xFF0A1931); // Navy Dark
  static const Color colorTextSecondary = Color(0xFF1A3D63); // Navy
  static const Color colorTextMuted = Color(0xFF4A7FA7); // Blue Medium
  static const Color colorTextOnDark = Color(0xFFF6FAFD); // Light

  // Actions
  static const Color colorActionPrimary = Color(0xFF3CB371); // Green Success (CTA)
  static const Color colorActionSecondary = Color(0xFF4A7FA7);
  static const Color colorActionDisabled = Color(0xFFB3CFE5);

  // States
  static const Color colorSuccess = Color(0xFF3CB371);
  static const Color colorWarning = Color(0xFFE9C46A);
  static const Color colorError = Color(0xFFE76F51);
  static const Color colorInfo = Color(0xFF4A7FA7);

  // Borders
  static const Color colorBorderSubtle = Color(0xFFB3CFE5);
  static const Color colorBorderStrong = Color(0xFF4A7FA7);

  // ---------------------------------------------------------------------------
  // COMPATIBILIDADE (Mapeamento para uso legado)
  // ---------------------------------------------------------------------------

  // Cores principais
  static const Color primary = colorBrandPrimary;
  static const Color secondary = colorBrandDark;
  static const Color accent = colorActionPrimary; // CTA principal
  static const Color blue = colorBrandSoft;
  
  // Paleta Antiga (Mapeada)
  static const Color purple = colorBrandPrimary;
  static const Color purpleLight = colorBrandSoft;
  static const Color purpleDark = colorBrandDark;
  static const Color lilac = colorBrandSoft;
  static const Color lilacLight = colorBackgroundSecondary;
  static const Color grayDark = colorTextSecondary; 
  static const Color grayMedium = colorTextMuted;
  static const Color grayLight = colorBorderSubtle;
  static const Color grayVeryLight = colorBackgroundSecondary;
  
  // Superfícies
  static const Color surface = colorSurfaceCard; 
  static const Color background = colorBackgroundPrimary; 
  static const Color card = colorSurfaceCard;
  
  // Texto (Mapeamento para manter compatibilidade com nomes antigos)
  // textPrimary antigo era Branco. Novo textOnDark é o equivalente.
  static const Color textPrimary = colorTextOnDark; 
  // textDark antigo era Preto. Novo textPrimary é o equivalente.
  static const Color textDark = colorTextPrimary;
  // textSecondary antigo era Cinza. Novo textMuted é o equivalente.
  static const Color textSecondary = colorTextMuted;
  
  // Estados
  static const Color success = colorSuccess;
  static const Color warning = colorWarning;
  static const Color error = colorError;
  static const Color info = colorInfo;
  
  // Transparências
  static const Color overlay = Color(0x800A1931);
  static const Color divider = colorBorderSubtle;
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [colorBrandDark, colorBrandPrimary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [colorActionPrimary, colorBrandSoft],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
