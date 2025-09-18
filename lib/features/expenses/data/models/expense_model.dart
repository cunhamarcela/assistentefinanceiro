import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/expense.dart';

part 'expense_model.g.dart';

@JsonSerializable()
class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.amount,
    required super.description,
    required super.categoryId,
    required super.date,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Factory para criar ExpenseModel a partir de JSON
  factory ExpenseModel.fromJson(Map<String, dynamic> json) => 
      _$ExpenseModelFromJson(json);

  /// Converte ExpenseModel para JSON
  Map<String, dynamic> toJson() => _$ExpenseModelToJson(this);

  /// Factory para criar ExpenseModel a partir de Entity
  factory ExpenseModel.fromEntity(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      amount: expense.amount,
      description: expense.description,
      categoryId: expense.categoryId,
      date: expense.date,
      notes: expense.notes,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
    );
  }

  /// Converte ExpenseModel para Entity
  Expense toEntity() {
    return Expense(
      id: id,
      amount: amount,
      description: description,
      categoryId: categoryId,
      date: date,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Factory para criar nova despesa
  factory ExpenseModel.create({
    required double amount,
    required String description,
    required String categoryId,
    DateTime? date,
    String? notes,
  }) {
    final expense = Expense.create(
      amount: amount,
      description: description,
      categoryId: categoryId,
      date: date,
      notes: notes,
    );
    
    return ExpenseModel.fromEntity(expense);
  }

  /// Cria uma cópia com novos valores
  ExpenseModel copyWith({
    String? id,
    double? amount,
    String? description,
    String? categoryId,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
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

  /// Converte para Map para SQLite
  Map<String, dynamic> toSQLite() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'categoryId': categoryId,
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Factory para criar a partir de Map do SQLite
  factory ExpenseModel.fromSQLite(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as String,
      amount: map['amount'] as double,
      description: map['description'] as String,
      categoryId: map['categoryId'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  /// Converte para Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'categoryId': categoryId,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'searchTerms': _generateSearchTerms(),
    };
  }

  /// Factory para criar a partir de Map do Firestore
  factory ExpenseModel.fromFirestore(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      categoryId: map['categoryId'] as String,
      date: (map['date'] as Timestamp).toDate(),
      notes: map['notes'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Gerar termos de busca para Firestore
  List<String> _generateSearchTerms() {
    final terms = <String>[];
    
    // Adicionar palavras da descrição
    terms.addAll(description.toLowerCase().split(' '));
    
    // Adicionar palavras das notas se existirem
    if (notes != null && notes!.isNotEmpty) {
      terms.addAll(notes!.toLowerCase().split(' '));
    }
    
    // Remover termos vazios e duplicados
    return terms.where((term) => term.isNotEmpty).toSet().toList();
  }
}
