import 'package:equatable/equatable.dart';

/// Tipos de features que podem ter limite de uso
enum FeatureType {
  aiChat,        // Chat com assistente IA
  aiInsights,    // Geração de insights por IA
  aiCategorize,  // Categorização automática por IA
  aiReports,     // Relatórios avançados com IA
  premiumReports, // Relatórios premium
  comparisons,   // Comparações multi-período
}

extension FeatureTypeExtension on FeatureType {
  String get displayName {
    switch (this) {
      case FeatureType.aiChat:
        return 'Chat IA';
      case FeatureType.aiInsights:
        return 'Insights IA';
      case FeatureType.aiCategorize:
        return 'Categorização IA';
      case FeatureType.aiReports:
        return 'Relatórios IA';
      case FeatureType.premiumReports:
        return 'Relatórios Premium';
      case FeatureType.comparisons:
        return 'Comparações';
    }
  }

  String get icon {
    switch (this) {
      case FeatureType.aiChat:
        return '💬';
      case FeatureType.aiInsights:
        return '💡';
      case FeatureType.aiCategorize:
        return '🏷️';
      case FeatureType.aiReports:
        return '📊';
      case FeatureType.premiumReports:
        return '📈';
      case FeatureType.comparisons:
        return '📉';
    }
  }

  /// Limite diário padrão para usuários gratuitos
  /// Estratégia: Limites menores = mais oportunidades de ad sem frustrar
  /// 1 ad assistido = 24h de uso ilimitado da feature
  int get defaultDailyLimit {
    switch (this) {
      case FeatureType.aiChat:
        return 5; // 5 mensagens por dia (feature principal)
      case FeatureType.aiInsights:
        return 3; // 3 insights por dia
      case FeatureType.aiCategorize:
        return 10; // 10 categorizações por dia (menos restritivo)
      case FeatureType.aiReports:
        return 2; // 2 relatórios por dia
      case FeatureType.premiumReports:
        return 1; // 1 relatório premium por dia
      case FeatureType.comparisons:
        return 1; // 1 comparação por dia (feature avançada)
    }
  }

  /// Descrição do limite para exibição
  String get limitDescription {
    switch (this) {
      case FeatureType.aiChat:
        return 'mensagens com IA';
      case FeatureType.aiInsights:
        return 'insights gerados';
      case FeatureType.aiCategorize:
        return 'categorizações automáticas';
      case FeatureType.aiReports:
        return 'relatórios com IA';
      case FeatureType.premiumReports:
        return 'relatórios premium';
      case FeatureType.comparisons:
        return 'comparações de período';
    }
  }
}

/// Entidade que representa o limite de uso de uma feature
class UsageLimit extends Equatable {
  final String id;
  final String userId;
  final FeatureType featureType;
  final int dailyLimit;
  final int usedToday;
  final DateTime lastReset;
  final DateTime updatedAt;

  const UsageLimit({
    required this.id,
    required this.userId,
    required this.featureType,
    required this.dailyLimit,
    required this.usedToday,
    required this.lastReset,
    required this.updatedAt,
  });

  /// Quantidade restante de uso para hoje
  int get remainingToday => (dailyLimit - usedToday).clamp(0, dailyLimit);

  /// Percentual de uso (0.0 a 1.0)
  double get usagePercentage => dailyLimit > 0 ? usedToday / dailyLimit : 0.0;

  /// Verifica se o limite foi atingido
  bool get isLimitReached => usedToday >= dailyLimit;

  /// Verifica se ainda pode usar a feature
  bool get canUse => !isLimitReached;

  /// Verifica se precisa resetar (novo dia)
  bool get needsReset {
    final now = DateTime.now();
    return lastReset.year != now.year ||
           lastReset.month != now.month ||
           lastReset.day != now.day;
  }

  /// Verifica se está próximo do limite (>= 80% usado)
  bool get isNearLimit => usagePercentage >= 0.8;

  /// Verifica se está na metade do limite (>= 50% usado)
  bool get isHalfUsed => usagePercentage >= 0.5;
  
  /// Verifica se é o último uso disponível (para mostrar banner promocional)
  bool get isLastUse => remainingToday == 1;

  /// Mensagem de status do limite
  String get statusMessage {
    if (isLimitReached) {
      return 'Limite diário atingido';
    } else if (isNearLimit) {
      return 'Restam apenas $remainingToday ${featureType.limitDescription}';
    } else if (isHalfUsed) {
      return '$remainingToday ${featureType.limitDescription} restantes';
    } else {
      return '$remainingToday de $dailyLimit disponíveis';
    }
  }

  /// Factory para criar um novo limite
  factory UsageLimit.create({
    required String userId,
    required FeatureType featureType,
    int? customDailyLimit,
  }) {
    final now = DateTime.now();
    final id = '${userId}_${featureType.name}_${now.millisecondsSinceEpoch}';
    
    return UsageLimit(
      id: id,
      userId: userId,
      featureType: featureType,
      dailyLimit: customDailyLimit ?? featureType.defaultDailyLimit,
      usedToday: 0,
      lastReset: now,
      updatedAt: now,
    );
  }

  /// Incrementa o uso e retorna nova instância
  UsageLimit incrementUsage() {
    return copyWith(
      usedToday: usedToday + 1,
      updatedAt: DateTime.now(),
    );
  }

  /// Reseta o uso diário (para novo dia)
  UsageLimit resetDaily() {
    final now = DateTime.now();
    return copyWith(
      usedToday: 0,
      lastReset: now,
      updatedAt: now,
    );
  }

  /// Atualiza o limite diário
  UsageLimit updateLimit(int newLimit) {
    return copyWith(
      dailyLimit: newLimit,
      updatedAt: DateTime.now(),
    );
  }

  UsageLimit copyWith({
    String? id,
    String? userId,
    FeatureType? featureType,
    int? dailyLimit,
    int? usedToday,
    DateTime? lastReset,
    DateTime? updatedAt,
  }) {
    return UsageLimit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      featureType: featureType ?? this.featureType,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      usedToday: usedToday ?? this.usedToday,
      lastReset: lastReset ?? this.lastReset,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        featureType,
        dailyLimit,
        usedToday,
        lastReset,
        updatedAt,
      ];

  @override
  String toString() {
    return 'UsageLimit(id: $id, userId: $userId, feature: ${featureType.name}, used: $usedToday/$dailyLimit)';
  }
}
