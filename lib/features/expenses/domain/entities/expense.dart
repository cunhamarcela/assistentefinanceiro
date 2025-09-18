import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  final String id;
  final double amount;
  final String description;
  final String categoryId;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Expense({
    required this.id,
    required this.amount,
    required this.description,
    required this.categoryId,
    required this.date,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory para criar uma nova despesa
  factory Expense.create({
    required double amount,
    required String description,
    required String categoryId,
    DateTime? date,
    String? notes,
  }) {
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}_${amount.hashCode}';
    
    return Expense(
      id: id,
      amount: amount,
      description: description,
      categoryId: categoryId,
      date: date ?? now,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Cria uma cópia da despesa com novos valores
  Expense copyWith({
    String? id,
    double? amount,
    String? description,
    String? categoryId,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Verifica se a despesa é de hoje
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// Verifica se a despesa é deste mês
  bool get isThisMonth {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Verifica se a despesa é desta semana
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Retorna o mês da despesa no formato MM/yyyy
  String get monthYear {
    return '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        description,
        categoryId,
        date,
        notes,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'Expense(id: $id, amount: $amount, description: $description, categoryId: $categoryId, date: $date)';
  }
}
