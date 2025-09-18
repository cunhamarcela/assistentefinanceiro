import 'package:flutter/material.dart';

/// Paleta de cores do aplicativo Assistente Financeiro
class AppColors {
  // Cores principais
  static const Color primary = Color(0xFF6A4DFF);     // Roxo principal
  static const Color secondary = Color(0xFF1C1C1E);   // Fundo escuro
  static const Color accent = Color(0xFFFFC542);      // Amarelo de destaque
  static const Color blue = Color(0xFF0052CC);        // Azul Monarch
  
  // Paleta Roxo/Lilás/Cinza
  static const Color purple = Color(0xFF6A4DFF);      // Roxo principal
  static const Color purpleLight = Color(0xFF8B5FFF); // Roxo claro
  static const Color purpleDark = Color(0xFF5A3DFF);  // Roxo escuro
  static const Color lilac = Color(0xFFB794F6);       // Lilás
  static const Color lilacLight = Color(0xFFD6BCFA);  // Lilás claro
  static const Color grayDark = Color(0xFF2D3748);    // Cinza escuro
  static const Color grayMedium = Color(0xFF4A5568);  // Cinza médio
  static const Color grayLight = Color(0xFF718096);   // Cinza claro
  static const Color grayVeryLight = Color(0xFFF7FAFC); // Cinza muito claro
  
  // Superfícies
  static const Color surface = Color(0xFFF5F5F7);     // Superfície clara
  static const Color background = Color(0xFFFFFFFF);   // Fundo branco
  static const Color card = Color(0xFFF5F5F7);        // Cor dos cards
  
  // Texto
  static const Color textPrimary = Colors.white;      // Texto principal
  static const Color textSecondary = Color(0xFF8E8E93); // Texto secundário
  static const Color textDark = Color(0xFF1C1C1E);    // Texto escuro
  
  // Estados
  static const Color success = Color(0xFF34C759);     // Verde sucesso
  static const Color warning = Color(0xFFFF9500);     // Laranja aviso
  static const Color error = Color(0xFFFF3B30);       // Vermelho erro
  static const Color info = Color(0xFF007AFF);        // Azul informação
  
  // Transparências
  static const Color overlay = Color(0x80000000);     // Overlay escuro
  static const Color divider = Color(0xFFE5E5EA);     // Divisor
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6A4DFF), Color(0xFF8B5FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFFC542), Color(0xFFFFD700)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
