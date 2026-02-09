import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';

/// Logger helper para AIAnalysisSection
void _logAI(String message, {String level = 'INFO'}) {
  final prefix = switch (level) {
    'ERROR' => '❌ [AIAnalysisSection]',
    'WARNING' => '⚠️ [AIAnalysisSection]',
    'SUCCESS' => '✅ [AIAnalysisSection]',
    'RENDER' => '🎨 [AIAnalysisSection]',
    _ => '📋 [AIAnalysisSection]',
  };
  debugPrint('$prefix $message');
}

/// Tokens utilizados:
/// - Background: colorSurfaceCard
/// - Texto: colorTextSecondary
/// - Ícone IA: colorBrandSoft
/// - Borda: colorBorderSubtle
/// - Header gradient: colorBrandPrimary -> colorBrandDark

/// Widget de seção com análise/explicação gerada por IA
class AIAnalysisSection extends StatefulWidget {
  final String title;
  final String analysisText;
  final List<String>? suggestions;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final VoidCallback? onExpand;

  const AIAnalysisSection({
    super.key,
    this.title = 'Análise da IA',
    required this.analysisText,
    this.suggestions,
    this.isLoading = false,
    this.onRefresh,
    this.onExpand,
  });

  @override
  State<AIAnalysisSection> createState() => _AIAnalysisSectionState();
}

class _AIAnalysisSectionState extends State<AIAnalysisSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _logAI('initState() - Título: ${widget.title}', level: 'RENDER');
    _logAI('   Texto recebido: ${widget.analysisText.length} caracteres', level: 'RENDER');
    _logAI('   Sugestões: ${widget.suggestions?.length ?? 0}', level: 'RENDER');
    _logAI('   isLoading: ${widget.isLoading}', level: 'RENDER');
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AIAnalysisSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.analysisText != widget.analysisText) {
      _logAI('didUpdateWidget() - Texto da IA alterado!', level: 'RENDER');
      _logAI('   Antigo: ${oldWidget.analysisText.length} chars', level: 'RENDER');
      _logAI('   Novo: ${widget.analysisText.length} chars', level: 'RENDER');
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.colorSurfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.colorBorderSubtle,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.colorBrandPrimary.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (widget.isLoading)
              _buildLoadingState()
            else ...[
              _buildAnalysisContent(),
              if (widget.suggestions != null && widget.suggestions!.isNotEmpty)
                _buildSuggestions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.colorBrandPrimary.withOpacity(0.1),
            AppColors.colorBrandSoft.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.colorBrandSoft.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: AppColors.colorBrandSoft,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.colorTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Baseado nos seus gastos',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.colorTextMuted,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onRefresh != null)
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: AppColors.colorBrandSoft,
                size: 20,
              ),
              onPressed: widget.onRefresh,
              tooltip: 'Atualizar análise',
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.colorBrandSoft,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Analisando seus dados...',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.colorTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisContent() {
    final displayText = _isExpanded || widget.analysisText.length <= 200
        ? widget.analysisText
        : '${widget.analysisText.substring(0, 200)}...';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayText,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.colorTextSecondary,
              height: 1.5,
            ),
          ),
          if (widget.analysisText.length > 200)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
                widget.onExpand?.call();
              },
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  _isExpanded ? 'Ver menos' : 'Ver mais',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.colorBrandSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.colorActionPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.colorActionPrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.colorActionPrimary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Sugestões',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.colorActionPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...widget.suggestions!.take(3).map((suggestion) => Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.colorTextMuted,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    suggestion,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.colorTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

/// Widget compacto de análise IA para uso em cards menores
class AIAnalysisCompact extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const AIAnalysisCompact({
    super.key,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.colorBrandSoft.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.colorBrandSoft.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: AppColors.colorBrandSoft,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.colorTextSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.colorTextMuted,
                size: 12,
              ),
          ],
        ),
      ),
    );
  }
}

