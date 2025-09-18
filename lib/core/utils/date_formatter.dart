import 'package:intl/intl.dart';

class DateFormatter {
  static DateFormat? _dateFormat;
  static DateFormat? _dateTimeFormat;
  static DateFormat? _monthYearFormat;
  static DateFormat? _monthNameFormat;
  static DateFormat? _dayMonthFormat;
  static DateFormat? _timeFormat;
  
  static DateFormat get dateFormat {
    _dateFormat ??= DateFormat('dd/MM/yyyy', 'pt_BR');
    return _dateFormat!;
  }
  
  static DateFormat get dateTimeFormat {
    _dateTimeFormat ??= DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
    return _dateTimeFormat!;
  }
  
  static DateFormat get monthYearFormat {
    _monthYearFormat ??= DateFormat('MM/yyyy', 'pt_BR');
    return _monthYearFormat!;
  }
  
  static DateFormat get monthNameFormat {
    _monthNameFormat ??= DateFormat('MMMM yyyy', 'pt_BR');
    return _monthNameFormat!;
  }
  
  static DateFormat get dayMonthFormat {
    _dayMonthFormat ??= DateFormat('dd/MM', 'pt_BR');
    return _dayMonthFormat!;
  }
  
  static DateFormat get timeFormat {
    _timeFormat ??= DateFormat('HH:mm', 'pt_BR');
    return _timeFormat!;
  }
  
  /// Formata data para string no formato dd/MM/yyyy
  static String formatDate(DateTime date) {
    return dateFormat.format(date);
  }
  
  /// Formata data e hora para string no formato dd/MM/yyyy HH:mm
  static String formatDateTime(DateTime dateTime) {
    return dateTimeFormat.format(dateTime);
  }
  
  /// Formata mês e ano para string no formato MM/yyyy
  static String formatMonthYear(DateTime date) {
    return monthYearFormat.format(date);
  }
  
  /// Formata mês e ano com nome do mês (Janeiro 2024)
  static String formatMonthName(DateTime date) {
    return monthNameFormat.format(date);
  }
  
  /// Formata apenas dia e mês (dd/MM)
  static String formatDayMonth(DateTime date) {
    return dayMonthFormat.format(date);
  }
  
  /// Formata apenas hora (HH:mm)
  static String formatTime(DateTime dateTime) {
    return timeFormat.format(dateTime);
  }
  
  /// Converte string de data para DateTime
  static DateTime? parseDate(String dateString) {
    try {
      return dateFormat.parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  /// Converte string de data e hora para DateTime
  static DateTime? parseDateTime(String dateTimeString) {
    try {
      return dateTimeFormat.parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }
  
  /// Retorna data relativa (hoje, ontem, etc.)
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Hoje';
    } else if (dateOnly == yesterday) {
      return 'Ontem';
    } else if (dateOnly.isAfter(today.subtract(const Duration(days: 7)))) {
      return _getDayOfWeek(date.weekday);
    } else {
      return formatDate(date);
    }
  }
  
  /// Retorna nome do dia da semana
  static String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return 'Segunda-feira';
      case 2:
        return 'Terça-feira';
      case 3:
        return 'Quarta-feira';
      case 4:
        return 'Quinta-feira';
      case 5:
        return 'Sexta-feira';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return '';
    }
  }
  
  /// Retorna diferença em dias entre duas datas
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }
  
  /// Verifica se a data é hoje
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
  
  /// Verifica se a data é este mês
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }
  
  /// Retorna primeiro dia do mês
  static DateTime firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  /// Retorna último dia do mês
  static DateTime lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }
  
  /// Retorna primeiro dia da semana (segunda-feira)
  static DateTime firstDayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }
  
  /// Retorna último dia da semana (domingo)
  static DateTime lastDayOfWeek(DateTime date) {
    return date.add(Duration(days: 7 - date.weekday));
  }
}
