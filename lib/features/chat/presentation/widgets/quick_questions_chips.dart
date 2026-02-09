import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/logging_service.dart';
import '../../data/services/quick_questions_service.dart';

/// Widget que exibe chips de perguntas rápidas em scroll horizontal
/// 
/// Tokens utilizados:
/// - Background: colorSurfaceCard
/// - Texto: colorTextSecondary
/// - Borda: colorBorderSubtle
/// - Ícone: colorBrandSoft
/// - Hover/Selected: colorBrandPrimary
class QuickQuestionsChips extends StatelessWidget {
  final Function(QuickQuestion) onQuestionSelected;
  final bool showLabels;
  final bool compact;
  final QuickQuestionCategory? filterCategory;

  const QuickQuestionsChips({
    super.key,
    required this.onQuestionSelected,
    this.showLabels = true,
    this.compact = false,
    this.filterCategory,
  });

  @override
  Widget build(BuildContext context) {
    final questions = filterCategory != null
        ? QuickQuestionsService.getQuestionsByCategory(filterCategory!)
        : QuickQuestionsService.availableQuestions;

    AppLogger.debug(FeatureTag.chat, '🎨 [UI:Chips] Renderizando QuickQuestionsChips', data: {
      'questions_count': questions.length,
      'filter_category': filterCategory?.name,
      'compact': compact,
      'show_labels': showLabels,
    });

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: questions.map((question) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _QuickQuestionChip(
                question: question,
                onTap: () {
                  AppLogger.action('quick_question_chip_tap', feature: FeatureTag.chat, data: {
                    'question_id': question.id,
                    'question_text': question.text,
                    'category': question.category.name,
                    'source': 'chips_horizontal',
                  });
                  onQuestionSelected(question);
                },
                showLabel: showLabels,
                compact: compact,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Chip individual de pergunta rápida
class _QuickQuestionChip extends StatelessWidget {
  final QuickQuestion question;
  final VoidCallback onTap;
  final bool showLabel;
  final bool compact;

  const _QuickQuestionChip({
    required this.question,
    required this.onTap,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.sm : AppSpacing.md,
            vertical: compact ? AppSpacing.xs : AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.colorSurfaceCard,
            borderRadius: BorderRadius.circular(compact ? 16 : 20),
            border: Border.all(
              color: AppColors.colorBorderSubtle,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.colorBrandDark.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                question.icon,
                size: compact ? 16 : 18,
                color: _getIconColor(question.category),
              ),
              if (showLabel) ...[
                SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
                Text(
                  compact ? question.shortText : question.text,
                  style: (compact ? AppTextStyles.caption : AppTextStyles.bodySmall).copyWith(
                    color: AppColors.colorTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getIconColor(QuickQuestionCategory category) {
    switch (category) {
      case QuickQuestionCategory.economy:
        return AppColors.colorWarning; // Amarelo/laranja para economia
      case QuickQuestionCategory.analysis:
        return AppColors.colorBrandSoft; // Azul para análise
      case QuickQuestionCategory.suggestion:
        return AppColors.colorSuccess; // Verde para sugestões
    }
  }
}

/// Widget expandido com perguntas agrupadas por categoria
/// Usado no estado vazio do chat
class QuickQuestionsExpanded extends StatelessWidget {
  final Function(QuickQuestion) onQuestionSelected;

  const QuickQuestionsExpanded({
    super.key,
    required this.onQuestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    AppLogger.debug(FeatureTag.chat, '🎨 [UI:Expanded] Renderizando QuickQuestionsExpanded', data: {
      'total_questions': QuickQuestionsService.availableQuestions.length,
      'categories': QuickQuestionCategory.values.map((c) => c.name).toList(),
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategorySection(
          context,
          title: '💰 Economia',
          category: QuickQuestionCategory.economy,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildCategorySection(
          context,
          title: '📊 Análise',
          category: QuickQuestionCategory.analysis,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildCategorySection(
          context,
          title: '💡 Sugestões',
          category: QuickQuestionCategory.suggestion,
        ),
      ],
    );
  }

  Widget _buildCategorySection(
    BuildContext context, {
    required String title,
    required QuickQuestionCategory category,
  }) {
    final questions = QuickQuestionsService.getQuestionsByCategory(category);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
          child: Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.colorTextMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: questions.map((question) {
            return _QuickQuestionButton(
              question: question,
              onTap: () {
                AppLogger.action('quick_question_button_tap', feature: FeatureTag.chat, data: {
                  'question_id': question.id,
                  'question_text': question.text,
                  'category': category.name,
                  'source': 'expanded_view',
                });
                onQuestionSelected(question);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Botão de pergunta rápida para o layout expandido
class _QuickQuestionButton extends StatelessWidget {
  final QuickQuestion question;
  final VoidCallback onTap;

  const _QuickQuestionButton({
    required this.question,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.colorSurfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.colorBorderSubtle,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                question.icon,
                size: 16,
                color: _getIconColor(question.category),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  question.text,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.colorTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getIconColor(QuickQuestionCategory category) {
    switch (category) {
      case QuickQuestionCategory.economy:
        return AppColors.colorWarning;
      case QuickQuestionCategory.analysis:
        return AppColors.colorBrandSoft;
      case QuickQuestionCategory.suggestion:
        return AppColors.colorSuccess;
    }
  }
}

/// Seção de perguntas rápidas para a área de input
/// Exibe chips compactos acima do campo de texto
class QuickQuestionsInputSection extends StatefulWidget {
  final Function(QuickQuestion) onQuestionSelected;
  final bool isVisible;

  const QuickQuestionsInputSection({
    super.key,
    required this.onQuestionSelected,
    this.isVisible = true,
  });

  @override
  State<QuickQuestionsInputSection> createState() => _QuickQuestionsInputSectionState();
}

class _QuickQuestionsInputSectionState extends State<QuickQuestionsInputSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    AppLogger.debug(FeatureTag.chat, '🎨 [UI:InputSection] initState', data: {
      'is_visible': widget.isVisible,
    });
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(QuickQuestionsInputSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      AppLogger.debug(FeatureTag.chat, '🔄 [UI:InputSection] Visibilidade alterada', data: {
        'old_visible': oldWidget.isVisible,
        'new_visible': widget.isVisible,
      });
      
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _animation,
      axisAlignment: -1,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.colorBackgroundPrimary,
          border: Border(
            bottom: BorderSide(
              color: AppColors.colorBorderSubtle.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                top: AppSpacing.sm,
              ),
              child: Text(
                '💬 Perguntas rápidas',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.colorTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            QuickQuestionsChips(
              onQuestionSelected: (question) {
                AppLogger.info(FeatureTag.chat, '👆 [UI:InputSection] Pergunta selecionada da seção de input', data: {
                  'question_id': question.id,
                  'question_text': question.text,
                });
                widget.onQuestionSelected(question);
              },
              compact: true,
              showLabels: true,
            ),
          ],
        ),
      ),
    );
  }
}

