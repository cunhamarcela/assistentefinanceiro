import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';

/// Logger helper para ExcessAlertCard
void _logExcessAlert(String message, {String level = 'INFO'}) {
  final prefix = switch (level) {
    'ERROR' => '❌ [ExcessAlertCard]',
    'WARNING' => '⚠️ [ExcessAlertCard]',
    'SUCCESS' => '✅ [ExcessAlertCard]',
    'RENDER' => '🎨 [ExcessAlertCard]',
    _ => '📋 [ExcessAlertCard]',
  };
  debugPrint('$prefix $message');
}

/// Tokens utilizados:
/// - Background (warning): colorWarning com 10% opacity
/// - Background (error): colorError com 10% opacity
/// - Texto título: colorTextPrimary
/// - Texto valor: colorError ou colorWarning
/// - Borda: colorWarning ou colorError
/// - Ícone: colorWarning ou colorError

/// Severidade do alerta de excesso
enum ExcessSeverity {
  /// Alerta (80-100% do orçamento)
  warning,
  /// Excedido (>100% do orçamento)
  exceeded,
}

/// Dados de uma categoria com excesso
class ExcessCategoryData {
  final String categoryId;
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final double budgetLimit;
  final double currentSpent;
  final double percentageUsed;
  
  const ExcessCategoryData({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.budgetLimit,
    required this.currentSpent,
    required this.percentageUsed,
  });
  
  /// Valor excedido (negativo se não excedeu)
  double get exceededAmount => currentSpent - budgetLimit;
  
  /// Se está excedido
  bool get isExceeded => currentSpent > budgetLimit;
  
  /// Severidade do alerta
  ExcessSeverity get severity => 
      isExceeded ? ExcessSeverity.exceeded : ExcessSeverity.warning;
}

/// Widget de card para alerta de excesso de categoria
class ExcessAlertCard extends StatelessWidget {
  final ExcessCategoryData data;
  final VoidCallback? onTap;

  const ExcessAlertCard({
    super.key,
    required this.data,
    this.onTap,
  });

  Color get _alertColor => data.severity == ExcessSeverity.exceeded 
      ? AppColors.colorError 
      : AppColors.colorWarning;

  IconData get _alertIcon => data.severity == ExcessSeverity.exceeded
      ? Icons.error_outline
      : Icons.warning_amber_outlined;

  String get _alertText => data.severity == ExcessSeverity.exceeded
      ? 'Excedido'
      : 'Atenção';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: _alertColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _alertColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Ícone de alerta
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _alertColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _alertIcon,
                color: _alertColor,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            
            // Informações da categoria
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        data.categoryIcon,
                        color: data.categoryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          data.categoryName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.colorTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _alertColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _alertText,
                          style: AppTextStyles.caption.copyWith(
                            color: _alertColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${data.percentageUsed.round()}% do limite',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _alertColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (data.isExceeded)
                        Text(
                          '+R\$ ${data.exceededAmount.toStringAsFixed(2)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.colorError,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        Text(
                          'R\$ ${(data.budgetLimit - data.currentSpent).toStringAsFixed(2)} restante',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.colorTextMuted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Barra de progresso
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (data.percentageUsed / 100).clamp(0.0, 1.0),
                      backgroundColor: AppColors.colorBorderSubtle,
                      valueColor: AlwaysStoppedAnimation<Color>(_alertColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget de lista de alertas de excesso
class ExcessAlertsList extends StatelessWidget {
  final List<ExcessCategoryData> alerts;
  final Function(ExcessCategoryData)? onAlertTap;
  final bool showTitle;

  const ExcessAlertsList({
    super.key,
    required this.alerts,
    this.onAlertTap,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    _logExcessAlert('ExcessAlertsList.build() - ${alerts.length} alertas', level: 'RENDER');
    
    if (alerts.isEmpty) {
      _logExcessAlert('   Nenhum alerta para exibir', level: 'RENDER');
      return const SizedBox.shrink();
    }

    // Ordenar por severidade (excedido primeiro) e depois por percentual
    final sortedAlerts = List<ExcessCategoryData>.from(alerts)
      ..sort((a, b) {
        if (a.isExceeded != b.isExceeded) {
          return a.isExceeded ? -1 : 1;
        }
        return b.percentageUsed.compareTo(a.percentageUsed);
      });
    
    _logExcessAlert('   Alertas ordenados:', level: 'RENDER');
    for (var i = 0; i < sortedAlerts.length; i++) {
      final alert = sortedAlerts[i];
      _logExcessAlert('   ${i + 1}. ${alert.categoryName}: ${alert.percentageUsed.toStringAsFixed(0)}% (${alert.isExceeded ? "EXCEDIDO" : "ALERTA"})', level: 'RENDER');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: AppColors.colorWarning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Alertas de Excesso',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.colorTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.colorError.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${alerts.length}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.colorError,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        ...sortedAlerts.map((alert) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ExcessAlertCard(
            data: alert,
            onTap: onAlertTap != null ? () => onAlertTap!(alert) : null,
          ),
        )),
      ],
    );
  }
}

