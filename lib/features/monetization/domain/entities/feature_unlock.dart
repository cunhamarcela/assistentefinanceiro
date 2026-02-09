import 'package:equatable/equatable.dart';
import 'usage_limit.dart';

/// Fonte/origem do desbloqueio
enum UnlockSource {
  rewardedAd,   // Desbloqueio por assistir anúncio
  purchase,     // Compra/assinatura
  trial,        // Período de teste
  promotion,    // Promoção/código promocional
  referral,     // Indicação de amigo
}

extension UnlockSourceExtension on UnlockSource {
  String get displayName {
    switch (this) {
      case UnlockSource.rewardedAd:
        return 'Anúncio Assistido';
      case UnlockSource.purchase:
        return 'Compra';
      case UnlockSource.trial:
        return 'Período de Teste';
      case UnlockSource.promotion:
        return 'Promoção';
      case UnlockSource.referral:
        return 'Indicação';
    }
  }

  String get icon {
    switch (this) {
      case UnlockSource.rewardedAd:
        return '🎬';
      case UnlockSource.purchase:
        return '💳';
      case UnlockSource.trial:
        return '🎁';
      case UnlockSource.promotion:
        return '🎉';
      case UnlockSource.referral:
        return '👥';
    }
  }

  /// Duração padrão do desbloqueio em horas
  int get defaultDurationHours {
    switch (this) {
      case UnlockSource.rewardedAd:
        return 24; // 24 horas (1 dia)
      case UnlockSource.purchase:
        return 720; // 30 dias (compra mensal)
      case UnlockSource.trial:
        return 168; // 7 dias
      case UnlockSource.promotion:
        return 72; // 3 dias
      case UnlockSource.referral:
        return 168; // 7 dias
    }
  }
}

/// Tipo de acesso desbloqueado
enum UnlockType {
  unlimited,        // Uso ilimitado da feature
  extraQuota,       // Quota adicional
  premiumAccess,    // Acesso premium completo
  singleFeature,    // Apenas uma feature específica
}

extension UnlockTypeExtension on UnlockType {
  String get displayName {
    switch (this) {
      case UnlockType.unlimited:
        return 'Uso Ilimitado';
      case UnlockType.extraQuota:
        return 'Quota Extra';
      case UnlockType.premiumAccess:
        return 'Acesso Premium';
      case UnlockType.singleFeature:
        return 'Feature Única';
    }
  }
}

/// Entidade que representa um desbloqueio de feature
class FeatureUnlock extends Equatable {
  final String id;
  final String userId;
  final FeatureType featureType;
  final UnlockType unlockType;
  final UnlockSource source;
  final DateTime unlockedAt;
  final DateTime expiresAt;
  final int? extraQuotaAmount; // Quantidade extra de quota (se unlockType == extraQuota)
  final String? adUnitId; // ID do anúncio assistido (se source == rewardedAd)
  final String? transactionId; // ID da transação (se source == purchase)
  final Map<String, dynamic>? metadata; // Dados adicionais

  const FeatureUnlock({
    required this.id,
    required this.userId,
    required this.featureType,
    required this.unlockType,
    required this.source,
    required this.unlockedAt,
    required this.expiresAt,
    this.extraQuotaAmount,
    this.adUnitId,
    this.transactionId,
    this.metadata,
  });

  /// Verifica se o desbloqueio ainda está ativo
  bool get isActive {
    final now = DateTime.now();
    return now.isBefore(expiresAt);
  }

  /// Verifica se o desbloqueio expirou
  bool get isExpired => !isActive;

  /// Tempo restante até expirar
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return Duration.zero;
    return expiresAt.difference(now);
  }

  /// Tempo restante formatado (ex: "23h 45m")
  String get timeRemainingFormatted {
    final remaining = timeRemaining;
    if (remaining == Duration.zero) return 'Expirado';
    
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    
    if (hours > 24) {
      final days = hours ~/ 24;
      return '$days dia${days > 1 ? 's' : ''}';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Percentual de tempo restante (0.0 a 1.0)
  double get timeRemainingPercentage {
    final totalDuration = expiresAt.difference(unlockedAt);
    final remaining = timeRemaining;
    if (totalDuration.inSeconds == 0) return 0.0;
    return (remaining.inSeconds / totalDuration.inSeconds).clamp(0.0, 1.0);
  }

  /// Verifica se está próximo de expirar (menos de 1 hora)
  bool get isNearExpiration => timeRemaining.inHours < 1 && isActive;

  /// Verifica se foi desbloqueado por anúncio
  bool get isFromAd => source == UnlockSource.rewardedAd;

  /// Verifica se foi comprado
  bool get isPurchased => source == UnlockSource.purchase;

  /// Verifica se é acesso ilimitado
  bool get isUnlimited => unlockType == UnlockType.unlimited;

  /// Factory para criar um novo desbloqueio
  factory FeatureUnlock.create({
    required String userId,
    required FeatureType featureType,
    required UnlockSource source,
    UnlockType unlockType = UnlockType.unlimited,
    int? durationHours,
    int? extraQuotaAmount,
    String? adUnitId,
    String? transactionId,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    final id = '${userId}_${featureType.name}_${now.millisecondsSinceEpoch}';
    final hours = durationHours ?? source.defaultDurationHours;
    
    return FeatureUnlock(
      id: id,
      userId: userId,
      featureType: featureType,
      unlockType: unlockType,
      source: source,
      unlockedAt: now,
      expiresAt: now.add(Duration(hours: hours)),
      extraQuotaAmount: extraQuotaAmount,
      adUnitId: adUnitId,
      transactionId: transactionId,
      metadata: metadata,
    );
  }

  /// Factory para criar desbloqueio por Rewarded Ad
  factory FeatureUnlock.fromRewardedAd({
    required String userId,
    required FeatureType featureType,
    required String adUnitId,
    int durationHours = 24,
  }) {
    return FeatureUnlock.create(
      userId: userId,
      featureType: featureType,
      source: UnlockSource.rewardedAd,
      unlockType: UnlockType.unlimited,
      durationHours: durationHours,
      adUnitId: adUnitId,
      metadata: {
        'ad_watched_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Factory para criar desbloqueio de teste/trial
  factory FeatureUnlock.trial({
    required String userId,
    required FeatureType featureType,
    int durationHours = 168, // 7 dias padrão
  }) {
    return FeatureUnlock.create(
      userId: userId,
      featureType: featureType,
      source: UnlockSource.trial,
      unlockType: UnlockType.unlimited,
      durationHours: durationHours,
    );
  }

  /// Estende a duração do desbloqueio
  FeatureUnlock extend(Duration additionalTime) {
    return copyWith(
      expiresAt: expiresAt.add(additionalTime),
    );
  }

  FeatureUnlock copyWith({
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
    return FeatureUnlock(
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

  @override
  List<Object?> get props => [
        id,
        userId,
        featureType,
        unlockType,
        source,
        unlockedAt,
        expiresAt,
        extraQuotaAmount,
        adUnitId,
        transactionId,
        metadata,
      ];

  @override
  String toString() {
    return 'FeatureUnlock(id: $id, feature: ${featureType.name}, source: ${source.name}, active: $isActive, expires: $timeRemainingFormatted)';
  }
}
