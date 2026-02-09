import 'package:equatable/equatable.dart';

/// Impacto da comparação no sistema de gamificação
class GamificationImpact extends Equatable {
  final int pointsEarned; // Pontos ganhos com esta comparação
  final List<String> badgesUnlocked; // IDs de badges desbloqueados
  final List<String> badgesProgress; // IDs de badges com progresso
  final Map<String, double> badgeProgressData; // Dados de progresso por badge
  final String? nextBadgeId; // Próximo badge a ser desbloqueado
  final double? nextBadgeProgress; // Progresso para próximo badge (0-1)

  const GamificationImpact({
    required this.pointsEarned,
    required this.badgesUnlocked,
    required this.badgesProgress,
    required this.badgeProgressData,
    this.nextBadgeId,
    this.nextBadgeProgress,
  });

  /// Se algum badge foi desbloqueado
  bool get hasUnlockedBadges => badgesUnlocked.isNotEmpty;

  /// Se há progresso em algum badge
  bool get hasBadgeProgress => badgesProgress.isNotEmpty;

  @override
  List<Object?> get props => [
        pointsEarned,
        badgesUnlocked,
        badgesProgress,
        badgeProgressData,
        nextBadgeId,
        nextBadgeProgress,
      ];
}



