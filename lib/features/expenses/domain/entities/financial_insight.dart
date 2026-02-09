/// Entidade que representa um insight financeiro personalizado
class FinancialInsight {
  final String id;
  final String title;
  final String description;
  final FinancialInsightType type;
  final FinancialInsightPriority priority;
  final Map<String, dynamic> data; // Dados específicos do insight
  final List<String> actionSuggestions;
  final DateTime createdAt;
  final bool isRead;

  const FinancialInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.data,
    required this.actionSuggestions,
    required this.createdAt,
    required this.isRead,
  });

  FinancialInsight copyWith({
    String? id,
    String? title,
    String? description,
    FinancialInsightType? type,
    FinancialInsightPriority? priority,
    Map<String, dynamic>? data,
    List<String>? actionSuggestions,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return FinancialInsight(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      data: data ?? Map.from(this.data),
      actionSuggestions: actionSuggestions ?? List.from(this.actionSuggestions),
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Marcar insight como lido
  FinancialInsight markAsRead() => copyWith(isRead: true);
}

/// Tipos de insights financeiros
enum FinancialInsightType {
  budgetExceeded,     // Orçamento excedido
  budgetWarning,      // Próximo de exceder orçamento
  savingsOpportunity, // Oportunidade de economia
  goalProgress,       // Progresso de meta
  spendingPattern,    // Padrão de gastos
  categoryAnalysis,   // Análise de categoria
  monthlyComparison,  // Comparação mensal
  positiveProgress,   // Progresso positivo (parabéns!)
}

/// Prioridades dos insights
enum FinancialInsightPriority {
  low,    // Baixa - informativo
  medium, // Média - atenção
  high,   // Alta - ação necessária
  urgent, // Urgente - ação imediata
}

extension FinancialInsightTypeExtension on FinancialInsightType {
  String get displayName {
    switch (this) {
      case FinancialInsightType.budgetExceeded:
        return 'Orçamento Excedido';
      case FinancialInsightType.budgetWarning:
        return 'Alerta de Orçamento';
      case FinancialInsightType.savingsOpportunity:
        return 'Oportunidade de Economia';
      case FinancialInsightType.goalProgress:
        return 'Progresso de Meta';
      case FinancialInsightType.spendingPattern:
        return 'Padrão de Gastos';
      case FinancialInsightType.categoryAnalysis:
        return 'Análise de Categoria';
      case FinancialInsightType.monthlyComparison:
        return 'Comparação Mensal';
      case FinancialInsightType.positiveProgress:
        return 'Progresso Positivo';
    }
  }

  String get icon {
    switch (this) {
      case FinancialInsightType.budgetExceeded:
        return '⚠️';
      case FinancialInsightType.budgetWarning:
        return '🔔';
      case FinancialInsightType.savingsOpportunity:
        return '💡';
      case FinancialInsightType.goalProgress:
        return '🎯';
      case FinancialInsightType.spendingPattern:
        return '📊';
      case FinancialInsightType.categoryAnalysis:
        return '🔍';
      case FinancialInsightType.monthlyComparison:
        return '📈';
      case FinancialInsightType.positiveProgress:
        return '🎉';
    }
  }
}

extension FinancialInsightPriorityExtension on FinancialInsightPriority {
  String get displayName {
    switch (this) {
      case FinancialInsightPriority.low:
        return 'Baixa';
      case FinancialInsightPriority.medium:
        return 'Média';
      case FinancialInsightPriority.high:
        return 'Alta';
      case FinancialInsightPriority.urgent:
        return 'Urgente';
    }
  }

  String get colorName {
    switch (this) {
      case FinancialInsightPriority.low:
        return 'blue';
      case FinancialInsightPriority.medium:
        return 'orange';
      case FinancialInsightPriority.high:
        return 'red';
      case FinancialInsightPriority.urgent:
        return 'purple';
    }
  }
}
