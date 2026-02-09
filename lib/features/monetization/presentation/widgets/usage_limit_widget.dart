import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/usage_limit.dart';
import '../../domain/entities/feature_unlock.dart';

/// Widget que mostra o uso restante de uma feature
class UsageLimitIndicator extends StatelessWidget {
  final UsageLimit limit;
  final FeatureUnlock? activeUnlock;
  final VoidCallback? onTap;

  const UsageLimitIndicator({
    super.key,
    required this.limit,
    this.activeUnlock,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnlock = activeUnlock != null && activeUnlock!.isActive;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getBackgroundColor(hasUnlock),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getBorderColor(hasUnlock),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIcon(hasUnlock),
              size: 16,
              color: _getIconColor(hasUnlock),
            ),
            const SizedBox(width: 6),
            Text(
              _getMessage(hasUnlock),
              style: AppTextStyles.caption.copyWith(
                color: _getTextColor(hasUnlock),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(bool hasUnlock) {
    if (hasUnlock) {
      return AppColors.colorSuccess.withOpacity(0.1);
    }
    if (limit.isLimitReached) {
      return AppColors.colorError.withOpacity(0.1);
    }
    if (limit.isNearLimit) {
      return AppColors.colorWarning.withOpacity(0.1);
    }
    return AppColors.colorBackgroundSecondary;
  }

  Color _getBorderColor(bool hasUnlock) {
    if (hasUnlock) {
      return AppColors.colorSuccess.withOpacity(0.3);
    }
    if (limit.isLimitReached) {
      return AppColors.colorError.withOpacity(0.3);
    }
    if (limit.isNearLimit) {
      return AppColors.colorWarning.withOpacity(0.3);
    }
    return AppColors.colorBorderSubtle;
  }

  IconData _getIcon(bool hasUnlock) {
    if (hasUnlock) {
      return Icons.star_rounded;
    }
    if (limit.isLimitReached) {
      return Icons.block_rounded;
    }
    if (limit.isNearLimit) {
      return Icons.warning_amber_rounded;
    }
    return Icons.check_circle_outline_rounded;
  }

  Color _getIconColor(bool hasUnlock) {
    if (hasUnlock) {
      return AppColors.colorSuccess;
    }
    if (limit.isLimitReached) {
      return AppColors.colorError;
    }
    if (limit.isNearLimit) {
      return AppColors.colorWarning;
    }
    return AppColors.colorBrandSoft;
  }

  Color _getTextColor(bool hasUnlock) {
    if (hasUnlock) {
      return AppColors.colorSuccess;
    }
    if (limit.isLimitReached) {
      return AppColors.colorError;
    }
    if (limit.isNearLimit) {
      return AppColors.colorWarning;
    }
    return AppColors.colorTextSecondary;
  }

  String _getMessage(bool hasUnlock) {
    if (hasUnlock) {
      return '✨ Ilimitado (${activeUnlock!.timeRemainingFormatted})';
    }
    if (limit.isLimitReached) {
      return 'Limite atingido';
    }
    return '${limit.remainingToday}/${limit.dailyLimit}';
  }
}

/// Dialog de limite atingido
class LimitReachedDialog extends StatelessWidget {
  final FeatureType featureType;
  final VoidCallback? onWatchAd;
  final VoidCallback? onClose;

  const LimitReachedDialog({
    super.key,
    required this.featureType,
    this.onWatchAd,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.colorWarning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.hourglass_empty_rounded,
                size: 40,
                color: AppColors.colorWarning,
              ),
            ),
            const SizedBox(height: 20),

            // Título
            Text(
              'Limite Diário Atingido',
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.colorTextPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Descrição
            Text(
              'Você atingiu o limite de ${featureType.defaultDailyLimit} ${featureType.limitDescription} por dia.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.colorTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              'Assista um anúncio para desbloquear 24 horas de uso ilimitado!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.colorTextPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Botão de assistir anúncio
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onWatchAd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.colorActionPrimary,
                  foregroundColor: AppColors.colorTextOnDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.play_circle_filled_rounded),
                label: const Text(
                  'Assistir Anúncio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Botão secundário
            TextButton(
              onPressed: onClose,
              child: Text(
                'Tentar novamente amanhã',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.colorTextMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mostra o dialog
  static Future<bool?> show(
    BuildContext context, {
    required FeatureType featureType,
    VoidCallback? onWatchAd,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LimitReachedDialog(
        featureType: featureType,
        onWatchAd: () {
          Navigator.of(context).pop(true);
          onWatchAd?.call();
        },
        onClose: () => Navigator.of(context).pop(false),
      ),
    );
  }
}

/// Banner de promoção de desbloqueio
class UnlockPromoBanner extends StatelessWidget {
  final FeatureType featureType;
  final VoidCallback? onWatchAd;

  const UnlockPromoBanner({
    super.key,
    required this.featureType,
    this.onWatchAd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.colorBrandPrimary,
            AppColors.colorBrandDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.colorBrandDark.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícone
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.colorTextOnDark.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.movie_filter_rounded,
              color: AppColors.colorTextOnDark,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Desbloqueie ${featureType.displayName}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.colorTextOnDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Assista um anúncio e ganhe 24h de uso ilimitado!',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.colorTextOnDark.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // Botão
          IconButton(
            onPressed: onWatchAd,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.colorActionPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: AppColors.colorTextOnDark,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de status de desbloqueio
class UnlockStatusChip extends StatelessWidget {
  final FeatureUnlock unlock;

  const UnlockStatusChip({
    super.key,
    required this.unlock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.colorSuccess.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.colorSuccess.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            unlock.source.icon == '🎬' ? Icons.movie_rounded : Icons.star_rounded,
            size: 14,
            color: AppColors.colorSuccess,
          ),
          const SizedBox(width: 4),
          Text(
            unlock.timeRemainingFormatted,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.colorSuccess,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

