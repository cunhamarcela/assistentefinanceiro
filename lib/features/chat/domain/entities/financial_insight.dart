import 'package:equatable/equatable.dart';

/// Entidade que representa um insight financeiro gerado pela IA
class FinancialInsight extends Equatable {
  final String id;
  final String title;
  final String description;
  final FinancialInsightType type;
  final FinancialInsightPriority priority;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final List<String> tags;
  final String? actionText;
  final String? actionRoute;

  const FinancialInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.data,
    required this.createdAt,
    this.expiresAt,
    this.tags = const [],
    this.actionText,
    this.actionRoute,
  });

  /// Factory para criar um insight de gastos excessivos
  factory FinancialInsight.excessiveSpending({
    required double amount,
    required String category,
    required double averageAmount,
    required String period,
  }) {
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}_excessive_spending';
    
    return FinancialInsight(
      id: id,
      title: 'Gastos Elevados Detectados',
      description: 'Você gastou R\$ ${amount.toStringAsFixed(2)} em $category, '
                  '${((amount - averageAmount) / averageAmount * 100).toStringAsFixed(0)}% '
                  'acima da sua média de R\$ ${averageAmount.toStringAsFixed(2)}.',
      type: FinancialInsightType.warning,
      priority: FinancialInsightPriority.high,
      data: {
        'amount': amount,
        'category': category,
        'average_amount': averageAmount,
        'period': period,
        'percentage_increase': (amount - averageAmount) / averageAmount * 100,
      },
      createdAt: now,
      expiresAt: now.add(const Duration(days: 7)),
      tags: ['gastos', 'categoria', 'alerta'],
      actionText: 'Ver Detalhes',
      actionRoute: '/expenses?category=$category',
    );
  }

  /// Factory para criar um insight de economia
  factory FinancialInsight.savingsOpportunity({
    required String category,
    required double potentialSavings,
    required String suggestion,
  }) {
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}_savings_opportunity';
    
    return FinancialInsight(
      id: id,
      title: 'Oportunidade de Economia',
      description: 'Você pode economizar até R\$ ${potentialSavings.toStringAsFixed(2)} '
                  'em $category. $suggestion',
      type: FinancialInsightType.opportunity,
      priority: FinancialInsightPriority.medium,
      data: {
        'category': category,
        'potential_savings': potentialSavings,
        'suggestion': suggestion,
      },
      createdAt: now,
      expiresAt: now.add(const Duration(days: 14)),
      tags: ['economia', 'sugestão', 'categoria'],
      actionText: 'Ver Sugestões',
      actionRoute: '/insights/savings',
    );
  }

  /// Factory para criar um insight de meta
  factory FinancialInsight.goalProgress({
    required String goalName,
    required double currentAmount,
    required double targetAmount,
    required bool isOnTrack,
  }) {
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}_goal_progress';
    final progress = (currentAmount / targetAmount * 100).clamp(0, 100);
    
    return FinancialInsight(
      id: id,
      title: isOnTrack ? 'Meta no Caminho Certo!' : 'Atenção à Meta',
      description: 'Sua meta "$goalName" está ${progress.toStringAsFixed(0)}% '
                  'completa (R\$ ${currentAmount.toStringAsFixed(2)} de '
                  'R\$ ${targetAmount.toStringAsFixed(2)}).',
      type: isOnTrack ? FinancialInsightType.success : FinancialInsightType.warning,
      priority: isOnTrack ? FinancialInsightPriority.low : FinancialInsightPriority.medium,
      data: {
        'goal_name': goalName,
        'current_amount': currentAmount,
        'target_amount': targetAmount,
        'progress_percentage': progress,
        'is_on_track': isOnTrack,
      },
      createdAt: now,
      expiresAt: now.add(const Duration(days: 30)),
      tags: ['meta', 'progresso'],
      actionText: 'Ver Metas',
      actionRoute: '/goals',
    );
  }

  /// Cria uma cópia do insight com novos valores
  FinancialInsight copyWith({
    String? id,
    String? title,
    String? description,
    FinancialInsightType? type,
    FinancialInsightPriority? priority,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? tags,
    String? actionText,
    String? actionRoute,
  }) {
    return FinancialInsight(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      tags: tags ?? this.tags,
      actionText: actionText ?? this.actionText,
      actionRoute: actionRoute ?? this.actionRoute,
    );
  }

  /// Verifica se o insight ainda é válido
  bool get isValid {
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Verifica se o insight expirou
  bool get isExpired => !isValid;

  /// Verifica se tem ação disponível
  bool get hasAction => actionText != null && actionRoute != null;

  /// Retorna a cor associada ao tipo do insight
  String get colorCode {
    switch (type) {
      case FinancialInsightType.success:
        return '#34C759'; // Verde
      case FinancialInsightType.warning:
        return '#FF9500'; // Laranja
      case FinancialInsightType.error:
        return '#FF3B30'; // Vermelho
      case FinancialInsightType.info:
        return '#007AFF'; // Azul
      case FinancialInsightType.opportunity:
        return '#6A4DFF'; // Roxo
    }
  }

  /// Retorna o ícone associado ao tipo do insight
  String get iconCode {
    switch (type) {
      case FinancialInsightType.success:
        return 'check_circle';
      case FinancialInsightType.warning:
        return 'warning';
      case FinancialInsightType.error:
        return 'error';
      case FinancialInsightType.info:
        return 'info';
      case FinancialInsightType.opportunity:
        return 'lightbulb';
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        priority,
        data,
        createdAt,
        expiresAt,
        tags,
        actionText,
        actionRoute,
      ];

  @override
  String toString() {
    return 'FinancialInsight(id: $id, title: $title, type: $type, priority: $priority)';
  }
}

/// Tipos de insights financeiros
enum FinancialInsightType {
  success,
  warning,
  error,
  info,
  opportunity,
}

/// Prioridades dos insights
enum FinancialInsightPriority {
  low,
  medium,
  high,
  critical,
}

