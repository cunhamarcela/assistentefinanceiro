import 'package:intl/intl.dart';

class CurrencyFormatter {
  static NumberFormat? _currencyFormat;
  static NumberFormat? _numberFormat;
  
  static NumberFormat get currencyFormat {
    _currencyFormat ??= NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    return _currencyFormat!;
  }
  
  static NumberFormat get numberFormat {
    _numberFormat ??= NumberFormat('#,##0.00', 'pt_BR');
    return _numberFormat!;
  }
  
  /// Formata um valor double para string de moeda brasileira
  /// Exemplo: 1234.56 -> "R\$ 1.234,56"
  static String formatCurrency(double value) {
    return currencyFormat.format(value);
  }
  
  /// Formata um valor double para string numérica
  /// Exemplo: 1234.56 -> "1.234,56"
  static String formatNumber(double value) {
    return numberFormat.format(value);
  }
  
  /// Converte string de moeda para double
  /// Exemplo: "R\$ 1.234,56" -> 1234.56
  static double? parseCurrency(String value) {
    try {
      // Remove símbolos de moeda e espaços
      String cleanValue = value
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .trim();
      
      // Substitui vírgula por ponto para parsing
      cleanValue = cleanValue.replaceAll('.', '').replaceAll(',', '.');
      
      return double.parse(cleanValue);
    } catch (e) {
      return null;
    }
  }
  
  /// Formata valor para exibição compacta
  /// Exemplo: 1234.56 -> "R\$ 1,2K"
  static String formatCompact(double value) {
    if (value >= 1000000) {
      return 'R\$ ${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return formatCurrency(value);
    }
  }
  
  /// Formata valor sem símbolo de moeda
  /// Exemplo: 1234.56 -> "1.234,56"
  static String formatValue(double value) {
    return numberFormat.format(value);
  }
  
  /// Valida se uma string é um valor monetário válido
  static bool isValidCurrency(String value) {
    return parseCurrency(value) != null;
  }
  
  /// Formata porcentagem
  /// Exemplo: 0.1234 -> "12,34%"
  static String formatPercentage(double value) {
    final NumberFormat percentFormat = NumberFormat.percentPattern('pt_BR');
    return percentFormat.format(value);
  }
}
