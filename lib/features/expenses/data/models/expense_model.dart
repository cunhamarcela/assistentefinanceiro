import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/installment_info.dart';
import 'installment_info_model.dart';

part 'expense_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ExpenseModel extends Expense {
  @JsonKey(
    name: 'installmentInfo',
    fromJson: _installmentInfoFromJson,
    toJson: _installmentInfoToJson,
  )
  @override
  final InstallmentInfo? installmentInfo;

  const ExpenseModel({
    required super.id,
    required super.amount,
    required super.description,
    required super.categoryId,
    required super.date,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
    super.paymentType,
    super.creditCardId,
    this.installmentInfo,
    super.source,
    super.aiParsedData,
    super.aiConfidence,
  }) : super(installmentInfo: installmentInfo);

  static InstallmentInfo? _installmentInfoFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return InstallmentInfoModel.fromJson(json).toEntity();
  }

  static Map<String, dynamic>? _installmentInfoToJson(InstallmentInfo? info) {
    if (info == null) return null;
    return InstallmentInfoModel.fromEntity(info).toJson();
  }

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
      paymentType: expense.paymentType,
      creditCardId: expense.creditCardId,
      installmentInfo: expense.installmentInfo,
      source: expense.source,
      aiParsedData: expense.aiParsedData,
      aiConfidence: expense.aiConfidence,
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
      paymentType: paymentType,
      creditCardId: creditCardId,
      installmentInfo: installmentInfo,
      source: source,
      aiParsedData: aiParsedData,
      aiConfidence: aiConfidence,
    );
  }

  /// Factory para criar nova despesa
  factory ExpenseModel.create({
    required double amount,
    required String description,
    required String categoryId,
    DateTime? date,
    String? notes,
    PaymentType paymentType = PaymentType.cash,
    String? creditCardId,
    InstallmentInfo? installmentInfo,
    ExpenseSource source = ExpenseSource.manual,
    String? aiParsedData,
    double? aiConfidence,
  }) {
    final expense = Expense.create(
      amount: amount,
      description: description,
      categoryId: categoryId,
      date: date,
      notes: notes,
      paymentType: paymentType,
      creditCardId: creditCardId,
      installmentInfo: installmentInfo,
      source: source,
      aiParsedData: aiParsedData,
      aiConfidence: aiConfidence,
    );
    
    return ExpenseModel.fromEntity(expense);
  }

  /// Cria uma cópia com novos valores
  @override
  ExpenseModel copyWith({
    String? id,
    double? amount,
    String? description,
    String? categoryId,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    PaymentType? paymentType,
    String? creditCardId,
    InstallmentInfo? installmentInfo,
    ExpenseSource? source,
    String? aiParsedData,
    double? aiConfidence,
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
      paymentType: paymentType ?? this.paymentType,
      creditCardId: creditCardId ?? this.creditCardId,
      installmentInfo: installmentInfo ?? this.installmentInfo,
      source: source ?? this.source,
      aiParsedData: aiParsedData ?? this.aiParsedData,
      aiConfidence: aiConfidence ?? this.aiConfidence,
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
      'paymentType': paymentType.name,
      'creditCardId': creditCardId,
      'installmentInfo': installmentInfo != null 
          ? InstallmentInfoModel.fromEntity(installmentInfo!).toJson() 
          : null,
      'source': source.name,
      'aiParsedData': aiParsedData,
      'aiConfidence': aiConfidence,
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
      paymentType: PaymentType.values.firstWhere(
        (e) => e.name == map['paymentType'],
        orElse: () => PaymentType.cash,
      ),
      creditCardId: map['creditCardId'] as String?,
      installmentInfo: map['installmentInfo'] != null
          ? InstallmentInfoModel.fromJson(map['installmentInfo'] as Map<String, dynamic>).toEntity()
          : null,
      source: map['source'] != null
          ? ExpenseSource.values.firstWhere(
              (e) => e.name == map['source'],
              orElse: () => ExpenseSource.manual,
            )
          : ExpenseSource.manual,
      aiParsedData: map['aiParsedData'] as String?,
      aiConfidence: map['aiConfidence'] as double?,
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
      'paymentType': paymentType.name,
      'creditCardId': creditCardId,
      'installmentInfo': installmentInfo != null
          ? InstallmentInfoModel.fromEntity(installmentInfo!).toJson()
          : null,
      'searchTerms': _generateSearchTerms(),
      'source': source.name,
      'aiParsedData': aiParsedData,
      'aiConfidence': aiConfidence,
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
      paymentType: map['paymentType'] != null
          ? PaymentType.values.firstWhere(
              (e) => e.name == map['paymentType'],
              orElse: () => PaymentType.cash,
            )
          : PaymentType.cash,
      creditCardId: map['creditCardId'] as String?,
      installmentInfo: map['installmentInfo'] != null
          ? InstallmentInfoModel.fromJson(map['installmentInfo'] as Map<String, dynamic>).toEntity()
          : null,
      source: map['source'] != null
          ? ExpenseSource.values.firstWhere(
              (e) => e.name == map['source'],
              orElse: () => ExpenseSource.manual,
            )
          : ExpenseSource.manual,
      aiParsedData: map['aiParsedData'] as String?,
      aiConfidence: map['aiConfidence'] != null 
          ? (map['aiConfidence'] as num).toDouble() 
          : null,
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
