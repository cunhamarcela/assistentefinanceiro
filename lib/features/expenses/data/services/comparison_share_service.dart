import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/multi_period_comparison.dart';

/// Serviço para compartilhar dados de comparação multi-período
/// 
/// Funcionalidades:
/// - Copia resumo para área de transferência
/// - Gera texto formatado para compartilhamento
/// - (Futuro) Exportar como imagem/PDF quando share_plus for adicionado
class ComparisonShareService {
  static final ComparisonShareService _instance = ComparisonShareService._internal();
  factory ComparisonShareService() => _instance;
  ComparisonShareService._internal();

  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _percentFormat = NumberFormat.decimalPercentPattern(locale: 'pt_BR', decimalDigits: 1);

  /// Gera texto formatado para compartilhamento
  String generateShareText(MultiPeriodComparison comparison) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('📊 Relatório de Comparação Multi-Período');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');
    
    // Período
    buffer.writeln('📅 Período: ${comparison.periodType.displayName}');
    buffer.writeln('');
    
    // Score
    final score = comparison.insights.score;
    buffer.writeln('🏆 Seu Score: ${score.grade} (${score.overallScore.toInt()}/100 pontos)');
    buffer.writeln('   • Melhoria: ${score.improvementScore.toInt()}');
    buffer.writeln('   • Consistência: ${score.consistencyScore.toInt()}');
    buffer.writeln('');
    
    // Tendência
    buffer.writeln('${comparison.trend.emoji} Tendência: ${comparison.trend.displayName}');
    buffer.writeln('   ${comparison.trend.description}');
    buffer.writeln('');
    
    // Estatísticas
    buffer.writeln('📈 Estatísticas');
    buffer.writeln('━━━━━━━━━━━━━━━');
    buffer.writeln('   • Média Mensal: ${_currencyFormat.format(comparison.averageSpending)}');
    
    final total = comparison.periods.fold(0.0, (sum, p) => sum + p.totalSpent);
    buffer.writeln('   • Total: ${_currencyFormat.format(total)}');
    
    if (comparison.highestSpendingPeriod != null) {
      buffer.writeln('   • Maior Gasto: ${_currencyFormat.format(comparison.highestSpendingPeriod!.totalSpent)} (${comparison.highestSpendingPeriod!.periodName})');
    }
    
    if (comparison.lowestSpendingPeriod != null) {
      buffer.writeln('   • Menor Gasto: ${_currencyFormat.format(comparison.lowestSpendingPeriod!.totalSpent)} (${comparison.lowestSpendingPeriod!.periodName})');
    }
    
    final change = comparison.overallChangePercentage;
    final changeIcon = change > 0 ? '📈' : (change < 0 ? '📉' : '➡️');
    buffer.writeln('   • Variação: $changeIcon ${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%');
    buffer.writeln('');
    
    // Evolução por período
    buffer.writeln('📆 Evolução Mensal');
    buffer.writeln('━━━━━━━━━━━━━━━━━');
    for (final period in comparison.periods) {
      buffer.writeln('   • ${period.periodName}: ${_currencyFormat.format(period.totalSpent)}');
    }
    buffer.writeln('');
    
    // Highlights
    if (comparison.insights.highlights.isNotEmpty) {
      buffer.writeln('💡 Destaques');
      buffer.writeln('━━━━━━━━━━━━');
      for (final highlight in comparison.insights.highlights) {
        buffer.writeln('   • $highlight');
      }
      buffer.writeln('');
    }
    
    // Footer
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📱 Assistente Financeiro IA');
    buffer.writeln('Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
    
    return buffer.toString();
  }

  /// Copia o resumo para a área de transferência
  Future<void> copyToClipboard(MultiPeriodComparison comparison) async {
    final text = generateShareText(comparison);
    await Clipboard.setData(ClipboardData(text: text));
    
    Get.snackbar(
      '✅ Copiado!',
      'Resumo copiado para a área de transferência',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.colorSuccess.withOpacity(0.9),
      colorText: AppColors.colorTextOnDark,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  /// Mostra bottom sheet com opções de compartilhamento
  void showShareOptions(MultiPeriodComparison comparison) {
    Get.bottomSheet(
      _ShareOptionsBottomSheet(
        comparison: comparison,
        onCopyToClipboard: () => copyToClipboard(comparison),
      ),
      backgroundColor: AppColors.colorSurfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }
}

/// Bottom sheet com opções de compartilhamento
class _ShareOptionsBottomSheet extends StatelessWidget {
  final MultiPeriodComparison comparison;
  final VoidCallback onCopyToClipboard;

  const _ShareOptionsBottomSheet({
    required this.comparison,
    required this.onCopyToClipboard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.colorBorderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          Row(
            children: [
              Icon(
                Icons.share,
                color: AppColors.colorBrandPrimary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Compartilhar Relatório',
                style: TextStyle(
                  color: AppColors.colorTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Preview do score
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.colorBrandPrimary,
                  AppColors.colorBrandDark,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score ${comparison.insights.score.grade}',
                      style: TextStyle(
                        color: AppColors.colorTextOnDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${comparison.insights.score.overallScore.toInt()}/100 pontos',
                      style: TextStyle(
                        color: AppColors.colorTextOnDark.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  comparison.insights.score.gradeEmoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Share options
          _ShareOption(
            icon: Icons.copy,
            title: 'Copiar para Área de Transferência',
            subtitle: 'Cole em qualquer app de mensagens',
            onTap: () {
              Get.back();
              onCopyToClipboard();
            },
          ),
          const SizedBox(height: 12),
          _ShareOption(
            icon: Icons.image,
            title: 'Salvar como Imagem',
            subtitle: 'Em breve',
            enabled: false,
            onTap: () {
              Get.snackbar(
                'Em breve',
                'Esta funcionalidade estará disponível em breve',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          const SizedBox(height: 12),
          _ShareOption(
            icon: Icons.picture_as_pdf,
            title: 'Exportar PDF',
            subtitle: 'Em breve',
            enabled: false,
            onTap: () {
              Get.snackbar(
                'Em breve',
                'Esta funcionalidade estará disponível em breve',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  const _ShareOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: enabled 
                ? AppColors.colorBackgroundPrimary 
                : AppColors.colorBackgroundSecondary.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled 
                  ? AppColors.colorBorderSubtle 
                  : AppColors.colorBorderSubtle.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: enabled 
                      ? AppColors.colorBrandPrimary.withOpacity(0.1) 
                      : AppColors.colorBorderSubtle.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: enabled 
                      ? AppColors.colorBrandPrimary 
                      : AppColors.colorTextMuted.withOpacity(0.5),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: enabled 
                            ? AppColors.colorTextPrimary 
                            : AppColors.colorTextMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: enabled 
                            ? AppColors.colorTextMuted 
                            : AppColors.colorTextMuted.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: enabled 
                    ? AppColors.colorTextMuted 
                    : AppColors.colorTextMuted.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



