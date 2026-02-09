import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/feature_unlock.dart';
import '../../domain/entities/usage_limit.dart';

/// Model para serialização do FeatureUnlock
class FeatureUnlockModel extends FeatureUnlock {
  const FeatureUnlockModel({
    required super.id,
    required super.userId,
    required super.featureType,
    required super.unlockType,
    required super.source,
    required super.unlockedAt,
    required super.expiresAt,
    super.extraQuotaAmount,
    super.adUnitId,
    super.transactionId,
    super.metadata,
  });

  /// Factory para criar FeatureUnlockModel a partir de Entity
  factory FeatureUnlockModel.fromEntity(FeatureUnlock entity) {
    return FeatureUnlockModel(
      id: entity.id,
      userId: entity.userId,
      featureType: entity.featureType,
      unlockType: entity.unlockType,
      source: entity.source,
      unlockedAt: entity.unlockedAt,
      expiresAt: entity.expiresAt,
      extraQuotaAmount: entity.extraQuotaAmount,
      adUnitId: entity.adUnitId,
      transactionId: entity.transactionId,
      metadata: entity.metadata,
    );
  }

  /// Converte para Entity
  FeatureUnlock toEntity() {
    return FeatureUnlock(
      id: id,
      userId: userId,
      featureType: featureType,
      unlockType: unlockType,
      source: source,
      unlockedAt: unlockedAt,
      expiresAt: expiresAt,
      extraQuotaAmount: extraQuotaAmount,
      adUnitId: adUnitId,
      transactionId: transactionId,
      metadata: metadata,
    );
  }

  /// Factory para criar a partir de JSON
  factory FeatureUnlockModel.fromJson(Map<String, dynamic> json) {
    return FeatureUnlockModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      featureType: FeatureType.values.firstWhere(
        (e) => e.name == json['featureType'],
        orElse: () => FeatureType.aiChat,
      ),
      unlockType: UnlockType.values.firstWhere(
        (e) => e.name == json['unlockType'],
        orElse: () => UnlockType.unlimited,
      ),
      source: UnlockSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => UnlockSource.rewardedAd,
      ),
      unlockedAt: DateTime.parse(json['unlockedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      extraQuotaAmount: json['extraQuotaAmount'] as int?,
      adUnitId: json['adUnitId'] as String?,
      transactionId: json['transactionId'] as String?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'featureType': featureType.name,
      'unlockType': unlockType.name,
      'source': source.name,
      'unlockedAt': unlockedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'extraQuotaAmount': extraQuotaAmount,
      'adUnitId': adUnitId,
      'transactionId': transactionId,
      'metadata': metadata,
    };
  }

  /// Factory para criar a partir de Firestore
  factory FeatureUnlockModel.fromFirestore(Map<String, dynamic> map) {
    return FeatureUnlockModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      featureType: FeatureType.values.firstWhere(
        (e) => e.name == map['featureType'],
        orElse: () => FeatureType.aiChat,
      ),
      unlockType: UnlockType.values.firstWhere(
        (e) => e.name == map['unlockType'],
        orElse: () => UnlockType.unlimited,
      ),
      source: UnlockSource.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => UnlockSource.rewardedAd,
      ),
      unlockedAt: (map['unlockedAt'] as Timestamp).toDate(),
      expiresAt: (map['expiresAt'] as Timestamp).toDate(),
      extraQuotaAmount: map['extraQuotaAmount'] as int?,
      adUnitId: map['adUnitId'] as String?,
      transactionId: map['transactionId'] as String?,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  /// Converte para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'featureType': featureType.name,
      'unlockType': unlockType.name,
      'source': source.name,
      'unlockedAt': Timestamp.fromDate(unlockedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'extraQuotaAmount': extraQuotaAmount,
      'adUnitId': adUnitId,
      'transactionId': transactionId,
      'metadata': metadata,
    };
  }

  /// Factory para criar a partir de SQLite
  factory FeatureUnlockModel.fromSQLite(Map<String, dynamic> map) {
    return FeatureUnlockModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      featureType: FeatureType.values.firstWhere(
        (e) => e.name == map['featureType'],
        orElse: () => FeatureType.aiChat,
      ),
      unlockType: UnlockType.values.firstWhere(
        (e) => e.name == map['unlockType'],
        orElse: () => UnlockType.unlimited,
      ),
      source: UnlockSource.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => UnlockSource.rewardedAd,
      ),
      unlockedAt: DateTime.fromMillisecondsSinceEpoch(map['unlockedAt'] as int),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] as int),
      extraQuotaAmount: map['extraQuotaAmount'] as int?,
      adUnitId: map['adUnitId'] as String?,
      transactionId: map['transactionId'] as String?,
      metadata: map['metadata'] != null
          ? jsonDecode(map['metadata'] as String) as Map<String, dynamic>
          : null,
    );
  }

  /// Converte para SQLite
  Map<String, dynamic> toSQLite() {
    return {
      'id': id,
      'userId': userId,
      'featureType': featureType.name,
      'unlockType': unlockType.name,
      'source': source.name,
      'unlockedAt': unlockedAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'extraQuotaAmount': extraQuotaAmount,
      'adUnitId': adUnitId,
      'transactionId': transactionId,
      'metadata': metadata != null ? jsonEncode(metadata) : null,
    };
  }

  /// Cria uma cópia com novos valores
  @override
  FeatureUnlockModel copyWith({
    String? id,
    String? userId,
    FeatureType? featureType,
    UnlockType? unlockType,
    UnlockSource? source,
    DateTime? unlockedAt,
    DateTime? expiresAt,
    int? extraQuotaAmount,
    String? adUnitId,
    String? transactionId,
    Map<String, dynamic>? metadata,
  }) {
    return FeatureUnlockModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      featureType: featureType ?? this.featureType,
      unlockType: unlockType ?? this.unlockType,
      source: source ?? this.source,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      extraQuotaAmount: extraQuotaAmount ?? this.extraQuotaAmount,
      adUnitId: adUnitId ?? this.adUnitId,
      transactionId: transactionId ?? this.transactionId,
      metadata: metadata ?? this.metadata,
    );
  }
}
