import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';

/// Logger helper para QuickAnalysisCard
void _logQuickCard(String message, {String level = 'INFO'}) {
  final prefix = switch (level) {
    'TAP' => '👆 [QuickAnalysisCard]',
    'RENDER' => '🎨 [QuickAnalysisCard]',
    _ => '📋 [QuickAnalysisCard]',
  };
  debugPrint('$prefix $message');
}

/// Tokens utilizados:
/// - Background: colorSurfaceCard
/// - Texto título: colorTextPrimary
/// - Texto subtítulo: colorTextMuted
/// - Ícone: colorBrandSoft
/// - Borda: colorBorderSubtle
/// - Hover: colorBackgroundSecondary (10% opacity)

/// Widget de card para ações de análise rápida
class QuickAnalysisCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool isHighlighted;

  const QuickAnalysisCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    _logQuickCard('build() - "$title"', level: 'RENDER');
    
    return GestureDetector(
      onTap: () {
        _logQuickCard('CLIQUE em "$title"', level: 'TAP');
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.colorSurfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted 
                ? AppColors.colorActionPrimary 
                : AppColors.colorBorderSubtle,
            width: isHighlighted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.colorBrandPrimary.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.colorBrandSoft).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.colorBrandSoft,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.colorTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.colorTextMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.colorTextMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

/// Variante horizontal com scroll para múltiplos cards
class QuickAnalysisCardsRow extends StatelessWidget {
  final List<QuickAnalysisCardData> cards;

  const QuickAnalysisCardsRow({
    super.key,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final card = cards[index];
          return SizedBox(
            width: 280,
            child: QuickAnalysisCard(
              icon: card.icon,
              title: card.title,
              subtitle: card.subtitle,
              onTap: card.onTap,
              iconColor: card.iconColor,
              isHighlighted: card.isHighlighted,
            ),
          );
        },
      ),
    );
  }
}

/// Dados para um card de análise rápida
class QuickAnalysisCardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool isHighlighted;

  const QuickAnalysisCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.isHighlighted = false,
  });
}

