import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/usage_limit.dart';

/// Model para serialização do UsageLimit
class UsageLimitModel extends UsageLimit {
  const UsageLimitModel({
    required super.id,
    required super.userId,
    required super.featureType,
    required super.dailyLimit,
    required super.usedToday,
    required super.lastReset,
    required super.updatedAt,
  });

  /// Factory para criar UsageLimitModel a partir de Entity
  factory UsageLimitModel.fromEntity(UsageLimit entity) {
    return UsageLimitModel(
      id: entity.id,
      userId: entity.userId,
      featureType: entity.featureType,
      dailyLimit: entity.dailyLimit,
      usedToday: entity.usedToday,
      lastReset: entity.lastReset,
      updatedAt: entity.updatedAt,
    );
  }

  /// Converte para Entity
  UsageLimit toEntity() {
    return UsageLimit(
      id: id,
      userId: userId,
      featureType: featureType,
      dailyLimit: dailyLimit,
      usedToday: usedToday,
      lastReset: lastReset,
      updatedAt: updatedAt,
    );
  }

  /// Factory para criar a partir de JSON
  factory UsageLimitModel.fromJson(Map<String, dynamic> json) {
    return UsageLimitModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      featureType: FeatureType.values.firstWhere(
        (e) => e.name == json['featureType'],
        orElse: () => FeatureType.aiChat,
      ),
      dailyLimit: json['dailyLimit'] as int,
      usedToday: json['usedToday'] as int,
      lastReset: DateTime.parse(json['lastReset'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'featureType': featureType.name,
      'dailyLimit': dailyLimit,
      'usedToday': usedToday,
      'lastReset': lastReset.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Factory para criar a partir de Firestore
  factory UsageLimitModel.fromFirestore(Map<String, dynamic> map) {
    return UsageLimitModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      featureType: FeatureType.values.firstWhere(
        (e) => e.name == map['featureType'],
        orElse: () => FeatureType.aiChat,
      ),
      dailyLimit: map['dailyLimit'] as int,
      usedToday: map['usedToday'] as int,
      lastReset: (map['lastReset'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Converte para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'featureType': featureType.name,
      'dailyLimit': dailyLimit,
      'usedToday': usedToday,
      'lastReset': Timestamp.fromDate(lastReset),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Factory para criar a partir de SQLite
  factory UsageLimitModel.fromSQLite(Map<String, dynamic> map) {
    return UsageLimitModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      featureType: FeatureType.values.firstWhere(
        (e) => e.name == map['featureType'],
        orElse: () => FeatureType.aiChat,
      ),
      dailyLimit: map['dailyLimit'] as int,
      usedToday: map['usedToday'] as int,
      lastReset: DateTime.fromMillisecondsSinceEpoch(map['lastReset'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  /// Converte para SQLite
  Map<String, dynamic> toSQLite() {
    return {
      'id': id,
      'userId': userId,
      'featureType': featureType.name,
      'dailyLimit': dailyLimit,
      'usedToday': usedToday,
      'lastReset': lastReset.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Cria uma cópia com novos valores
  @override
  UsageLimitModel copyWith({
    String? id,
    String? userId,
    FeatureType? featureType,
    int? dailyLimit,
    int? usedToday,
    DateTime? lastReset,
    DateTime? updatedAt,
  }) {
    return UsageLimitModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      featureType: featureType ?? this.featureType,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      usedToday: usedToday ?? this.usedToday,
      lastReset: lastReset ?? this.lastReset,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
