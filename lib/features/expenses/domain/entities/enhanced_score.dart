import 'package:equatable/equatable.dart';
import 'multi_period_comparison.dart';

/// Score expandido que combina múltiplas métricas
class EnhancedScore extends Equatable {
  final ComparisonScore baseScore; // Score atual (melhoria + consistência)
  final double budgetAdherenceScore; // 0-100 baseado em aderência ao orçamento
  final double goalPerformanceScore; // 0-100 performance vs metas
  final double overallScore; // Score combinado
  final String grade; // Nota final (A+, A, B+, B, C, D, F)

  const EnhancedScore({
    required this.baseScore,
    required this.budgetAdherenceScore,
    required this.goalPerformanceScore,
    required this.overallScore,
    required this.grade,
  });

  /// Retorna cor baseada na nota
  String get gradeColor {
    switch (grade) {
      case 'A+':
      case 'A':
        return '#34C759'; // Success green
      case 'B+':
      case 'B':
        return '#6A4DFF'; // Purple
      case 'C':
        return '#FFC542'; // Warning yellow
      case 'D':
        return '#FF9500'; // Orange
      case 'F':
        return '#FF3B30'; // Error red
      default:
        return '#8E8E93'; // Gray
    }
  }

  /// Retorna emoji baseado na nota
  String get gradeEmoji {
    switch (grade) {
      case 'A+':
      case 'A':
        return '🎉';
      case 'B+':
      case 'B':
        return '👍';
      case 'C':
        return '💪';
      case 'D':
        return '⚠️';
      case 'F':
        return '🚨';
      default:
        return '📊';
    }
  }

  @override
  List<Object?> get props => [
        baseScore,
        budgetAdherenceScore,
        goalPerformanceScore,
        overallScore,
        grade,
      ];
}



