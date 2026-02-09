import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/credit_card.dart';

part 'credit_card_model.g.dart';

@JsonSerializable()
class CreditCardModel extends CreditCard {
  const CreditCardModel({
    required super.id,
    required super.name,
    required super.lastFourDigits,
    required super.closingDay,
    required super.dueDay,
    super.limit,
    super.flag,
    super.color,
    super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Factory para criar CreditCardModel a partir de JSON
  factory CreditCardModel.fromJson(Map<String, dynamic> json) =>
      _$CreditCardModelFromJson(json);

  /// Converte CreditCardModel para JSON
  Map<String, dynamic> toJson() => _$CreditCardModelToJson(this);

  /// Factory para criar CreditCardModel a partir de Entity
  factory CreditCardModel.fromEntity(CreditCard card) {
    return CreditCardModel(
      id: card.id,
      name: card.name,
      lastFourDigits: card.lastFourDigits,
      closingDay: card.closingDay,
      dueDay: card.dueDay,
      limit: card.limit,
      flag: card.flag,
      color: card.color,
      isActive: card.isActive,
      createdAt: card.createdAt,
      updatedAt: card.updatedAt,
    );
  }

  /// Converte CreditCardModel para Entity
  CreditCard toEntity() {
    return CreditCard(
      id: id,
      name: name,
      lastFourDigits: lastFourDigits,
      closingDay: closingDay,
      dueDay: dueDay,
      limit: limit,
      flag: flag,
      color: color,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Factory para criar novo cartão
  factory CreditCardModel.create({
    required String name,
    required String lastFourDigits,
    required int closingDay,
    required int dueDay,
    double? limit,
    String? flag,
    String? color,
  }) {
    final card = CreditCard.create(
      name: name,
      lastFourDigits: lastFourDigits,
      closingDay: closingDay,
      dueDay: dueDay,
      limit: limit,
      flag: flag,
      color: color,
    );

    return CreditCardModel.fromEntity(card);
  }

  /// Cria uma cópia com novos valores
  CreditCardModel copyWith({
    String? id,
    String? name,
    String? lastFourDigits,
    int? closingDay,
    int? dueDay,
    double? limit,
    String? flag,
    String? color,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreditCardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      closingDay: closingDay ?? this.closingDay,
      dueDay: dueDay ?? this.dueDay,
      limit: limit ?? this.limit,
      flag: flag ?? this.flag,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Converte para Map para SQLite
  Map<String, dynamic> toSQLite() {
    return {
      'id': id,
      'name': name,
      'lastFourDigits': lastFourDigits,
      'closingDay': closingDay,
      'dueDay': dueDay,
      'cardLimit': limit,
      'flag': flag,
      'color': color,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Factory para criar a partir de Map do SQLite
  factory CreditCardModel.fromSQLite(Map<String, dynamic> map) {
    return CreditCardModel(
      id: map['id'] as String,
      name: map['name'] as String,
      lastFourDigits: map['lastFourDigits'] as String,
      closingDay: map['closingDay'] as int,
      dueDay: map['dueDay'] as int,
      limit: map['cardLimit'] as double?,
      flag: map['flag'] as String?,
      color: map['color'] as String?,
      isActive: (map['isActive'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  /// Converte para Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'lastFourDigits': lastFourDigits,
      'closingDay': closingDay,
      'dueDay': dueDay,
      'limit': limit,
      'flag': flag,
      'color': color,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Factory para criar a partir de Map do Firestore
  factory CreditCardModel.fromFirestore(Map<String, dynamic> map) {
    return CreditCardModel(
      id: map['id'] as String,
      name: map['name'] as String,
      lastFourDigits: map['lastFourDigits'] as String,
      closingDay: map['closingDay'] as int,
      dueDay: map['dueDay'] as int,
      limit: map['limit'] != null ? (map['limit'] as num).toDouble() : null,
      flag: map['flag'] as String?,
      color: map['color'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
}

