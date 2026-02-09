import 'investment.dart';

/// Entidade que representa uma meta de investimento
class InvestmentGoal {
  final String id;
  final InvestmentType? type; // null = meta geral de investimento
  final String? typeName; // Nome do tipo (se type for null, é meta geral)
  final double monthlyTarget; // Meta mensal de investimento
  final double currentInvested; // Valor já investido no mês
  final DateTime month;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvestmentGoal({
    required this.id,
    this.type,
    this.typeName,
    required this.monthlyTarget,
    required this.currentInvested,
    required this.month,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Percentual investido da meta (0.0 a 1.0+)
  double get progressPercentage => monthlyTarget > 0 ? currentInvested / monthlyTarget : 0.0;

  /// Valor restante da meta
  double get remainingAmount => monthlyTarget - currentInvested;

  /// Se a meta foi atingida
  bool get isAchieved => currentInvested >= monthlyTarget;

  /// Status da meta baseado no percentual investido
  InvestmentGoalStatus get status {
    if (!isActive) return InvestmentGoalStatus.inactive;
    if (progressPercentage >= 1.0) return InvestmentGoalStatus.achieved;
    if (progressPercentage >= 0.8) return InvestmentGoalStatus.nearTarget;
    if (progressPercentage >= 0.5) return InvestmentGoalStatus.onTrack;
    return InvestmentGoalStatus.belowTarget;
  }

  /// Nome exibido do tipo
  String get displayTypeName {
    if (type != null) return type!.displayName;
    return typeName ?? 'Geral';
  }

  InvestmentGoal copyWith({
    String? id,
    InvestmentType? type,
    String? typeName,
    double? monthlyTarget,
    double? currentInvested,
    DateTime? month,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvestmentGoal(
      id: id ?? this.id,
      type: type ?? this.type,
      typeName: typeName ?? this.typeName,
      monthlyTarget: monthlyTarget ?? this.monthlyTarget,
      currentInvested: currentInvested ?? this.currentInvested,
      month: month ?? this.month,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Status de uma meta de investimento
enum InvestmentGoalStatus {
  belowTarget,  // <50% investido
  onTrack,      // 50-80% investido
  nearTarget,   // 80-100% investido
  achieved,     // >=100% investido
  inactive,     // Meta desativada
}

extension InvestmentGoalStatusExtension on InvestmentGoalStatus {
  String get displayName {
    switch (this) {
      case InvestmentGoalStatus.belowTarget:
        return 'Abaixo da Meta';
      case InvestmentGoalStatus.onTrack:
        return 'No Caminho';
      case InvestmentGoalStatus.nearTarget:
        return 'Quase Lá';
      case InvestmentGoalStatus.achieved:
        return 'Meta Atingida';
      case InvestmentGoalStatus.inactive:
        return 'Inativa';
    }
  }

  String get description {
    switch (this) {
      case InvestmentGoalStatus.belowTarget:
        return 'Você ainda precisa investir mais para atingir a meta';
      case InvestmentGoalStatus.onTrack:
        return 'Você está no caminho certo para atingir a meta';
      case InvestmentGoalStatus.nearTarget:
        return 'Falta pouco para atingir a meta!';
      case InvestmentGoalStatus.achieved:
        return 'Parabéns! Você atingiu a meta de investimento';
      case InvestmentGoalStatus.inactive:
        return 'Meta não está ativa';
    }
  }
}
