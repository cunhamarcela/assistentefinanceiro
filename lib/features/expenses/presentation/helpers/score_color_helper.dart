import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/multi_period_comparison.dart';
import '../../domain/entities/enhanced_score.dart';

/// Helper para obter cores do Design System para scores e notas
/// 
/// Uso recomendado em vez de usar `score.gradeColor` diretamente,
/// que retorna strings HEX e viola as Cursor Rules.
/// 
/// Tokens utilizados:
/// - A+/A: colorSuccess (#3CB371)
/// - B+/B: colorBrandPrimary (#1A3D63)
/// - C: colorWarning (#E9C46A)
/// - D: colorWarning (variação mais intensa)
/// - F: colorError (#E76F51)
/// - default: colorTextMuted (#4A7FA7)
class ScoreColorHelper {
  ScoreColorHelper._();

  /// Obtém a cor do Design System para uma nota
  static Color getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return AppColors.colorSuccess;
      case 'B+':
      case 'B':
        return AppColors.colorBrandPrimary;
      case 'C':
        return AppColors.colorWarning;
      case 'D':
        return const Color(0xFFFF9500); // Orange - sem token específico
      case 'F':
        return AppColors.colorError;
      default:
        return AppColors.colorTextMuted;
    }
  }

  /// Obtém a cor para um ComparisonScore
  static Color getComparisonScoreColor(ComparisonScore score) {
    return getGradeColor(score.grade);
  }

  /// Obtém a cor para um EnhancedScore
  static Color getEnhancedScoreColor(EnhancedScore score) {
    return getGradeColor(score.grade);
  }

  /// Obtém cor baseada no percentual de aderência ao orçamento
  static Color getBudgetAdherenceColor(double adherencePercent) {
    if (adherencePercent <= 50) {
      return AppColors.colorSuccess; // Muito bom
    } else if (adherencePercent <= 80) {
      return AppColors.colorBrandPrimary; // Bom
    } else if (adherencePercent <= 100) {
      return AppColors.colorWarning; // Atenção
    } else {
      return AppColors.colorError; // Excedeu
    }
  }

  /// Obtém cor para tendência
  static Color getTrendColor(ComparisonTrend trend) {
    switch (trend) {
      case ComparisonTrend.decreasing:
        return AppColors.colorSuccess; // Gastos diminuindo = bom
      case ComparisonTrend.stable:
        return AppColors.colorBrandPrimary;
      case ComparisonTrend.increasing:
        return AppColors.colorWarning; // Gastos aumentando = atenção
      case ComparisonTrend.volatile:
        return AppColors.colorError; // Muito variável = problema
    }
  }

  /// Obtém cor para prioridade de recomendação
  static Color getRecommendationPriorityColor(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.low:
        return AppColors.colorBrandSoft;
      case RecommendationPriority.medium:
        return AppColors.colorActionPrimary;
      case RecommendationPriority.high:
        return AppColors.colorWarning;
      case RecommendationPriority.urgent:
        return AppColors.colorError;
    }
  }
}

/// Extension para facilitar o uso de cores em ComparisonScore
extension ComparisonScoreColorExtension on ComparisonScore {
  /// Obtém a cor do Design System para este score
  Color get gradeColorToken => ScoreColorHelper.getComparisonScoreColor(this);
}

/// Extension para facilitar o uso de cores em EnhancedScore
extension EnhancedScoreColorExtension on EnhancedScore {
  /// Obtém a cor do Design System para este score
  Color get gradeColorToken => ScoreColorHelper.getEnhancedScoreColor(this);
}

/// Extension para facilitar o uso de cores em ComparisonTrend
extension ComparisonTrendColorExtension on ComparisonTrend {
  /// Obtém a cor do Design System para esta tendência
  Color get trendColorToken => ScoreColorHelper.getTrendColor(this);
}

/// Extension para facilitar o uso de cores em RecommendationPriority
extension RecommendationPriorityColorExtension on RecommendationPriority {
  /// Obtém a cor do Design System para esta prioridade
  Color get priorityColorToken => ScoreColorHelper.getRecommendationPriorityColor(this);
}
