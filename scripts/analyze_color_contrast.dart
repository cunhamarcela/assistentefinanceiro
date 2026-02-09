// ignore_for_file: avoid_print
/// Script para analisar problemas de contraste de cores no código Flutter
/// Execute com: dart run scripts/analyze_color_contrast.dart

import 'dart:io';

/// Padrões problemáticos de cores
final Map<String, String> problematicPatterns = {
  // Cores hardcoded que violam o Design System
  r'Colors\.white': 'Use AppColors.colorTextOnDark ou AppColors.colorSurfaceCard',
  r'Colors\.black': 'Use AppColors.colorTextPrimary ou AppColors.colorBrandDark',
  r'Colors\.grey': 'Use AppColors.colorTextMuted ou AppColors.colorBorderSubtle',
  r'Colors\.red(?!\s*\.)': 'Use AppColors.colorError',
  r'Colors\.green(?!\s*\.)': 'Use AppColors.colorSuccess',
  r'Colors\.blue(?!\s*\.)': 'Use AppColors.colorBrandSoft ou AppColors.colorInfo',
  r'Color\(0x[0-9A-Fa-f]+\)': 'Considere usar um token do AppColors',
};

/// Padrões de potencial problema de contraste
final List<ContrastRule> contrastRules = [
  ContrastRule(
    name: 'AppBar escura com texto escuro',
    backgroundPattern: r'AppBar\([^)]*backgroundColor:\s*AppColors\.(primary|colorBrandPrimary|colorBrandDark|purple)',
    textPattern: r'AppTextStyles\.(headline|heading|subtitle|body)\d?(?!Light)',
    suggestion: 'Use AppTextStyles.*Light ou adicione .copyWith(color: AppColors.colorTextOnDark)',
  ),
  ContrastRule(
    name: 'Gradiente escuro com texto sem cor explícita',
    backgroundPattern: r'LinearGradient\([^)]*colors:\s*\[[^]]*colorBrand(Primary|Dark)',
    textPattern: r'AppTextStyles\.(headline|heading|subtitle|body)\d?[^L]',
    suggestion: 'Defina cor explícita: .copyWith(color: AppColors.colorTextOnDark)',
  ),
  ContrastRule(
    name: 'textSecondary sobre fundo escuro',
    backgroundPattern: r'(colorBrandDark|colorBrandPrimary|primary)',
    textPattern: r'color:\s*AppColors\.textSecondary',
    suggestion: 'Use AppColors.colorTextOnDark para fundos escuros',
  ),
];

class ContrastRule {
  final String name;
  final String backgroundPattern;
  final String textPattern;
  final String suggestion;

  ContrastRule({
    required this.name,
    required this.backgroundPattern,
    required this.textPattern,
    required this.suggestion,
  });
}

class Issue {
  final String file;
  final int line;
  final String type;
  final String match;
  final String suggestion;
  final String severity;

  Issue({
    required this.file,
    required this.line,
    required this.type,
    required this.match,
    required this.suggestion,
    required this.severity,
  });
}

void main() async {
  print('🔍 Analisando problemas de contraste de cores...\n');

  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('❌ Diretório lib não encontrado. Execute do diretório raiz do projeto.');
    exit(1);
  }

  final issues = <Issue>[];
  var filesAnalyzed = 0;

  // Arquivos a ignorar
  final ignoreFiles = [
    'app_colors.dart',
    'app_theme.dart',
    'color_selector.dart',
    'category.dart', // Cores de categorias são exceção
  ];

  await for (final entity in libDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final fileName = entity.path.split('/').last;
      if (ignoreFiles.contains(fileName)) continue;

      filesAnalyzed++;
      final content = await entity.readAsString();
      final lines = content.split('\n');

      // Verificar padrões problemáticos
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];

        // Verificar cores hardcoded
        for (final entry in problematicPatterns.entries) {
          final regex = RegExp(entry.key);
          if (regex.hasMatch(line)) {
            issues.add(Issue(
              file: entity.path,
              line: i + 1,
              type: 'Cor hardcoded',
              match: regex.firstMatch(line)?.group(0) ?? '',
              suggestion: entry.value,
              severity: 'MÉDIA',
            ));
          }
        }
      }

      // Verificar padrões de contraste problemáticos
      // Análise de contexto: verificar blocos de código
      for (final rule in contrastRules) {
        final bgRegex = RegExp(rule.backgroundPattern, multiLine: true);
        final textRegex = RegExp(rule.textPattern);

        // Procurar por widgets com fundo escuro
        final bgMatches = bgRegex.allMatches(content);
        for (final bgMatch in bgMatches) {
          // Verificar se há texto problemático nas próximas 20 linhas
          final startLine = content.substring(0, bgMatch.start).split('\n').length;
          final endLine = (startLine + 20).clamp(0, lines.length);

          for (var i = startLine; i < endLine; i++) {
            if (textRegex.hasMatch(lines[i])) {
              issues.add(Issue(
                file: entity.path,
                line: i + 1,
                type: rule.name,
                match: textRegex.firstMatch(lines[i])?.group(0) ?? '',
                suggestion: rule.suggestion,
                severity: 'ALTA',
              ));
            }
          }
        }
      }
    }
  }

  // Relatório
  print('═' * 80);
  print('📊 RELATÓRIO DE ANÁLISE DE CONTRASTE');
  print('═' * 80);
  print('');
  print('📁 Arquivos analisados: $filesAnalyzed');
  print('🔴 Total de problemas: ${issues.length}');
  print('');

  // Agrupar por severidade
  final altaPrioridade = issues.where((i) => i.severity == 'ALTA').toList();
  final mediaPrioridade = issues.where((i) => i.severity == 'MÉDIA').toList();

  if (altaPrioridade.isNotEmpty) {
    print('');
    print('🚨 PROBLEMAS DE ALTA PRIORIDADE (Potencial texto invisível):');
    print('-' * 80);
    for (final issue in altaPrioridade) {
      print('');
      print('📄 ${issue.file}:${issue.line}');
      print('   Tipo: ${issue.type}');
      print('   Encontrado: ${issue.match}');
      print('   💡 ${issue.suggestion}');
    }
  }

  // Agrupar por arquivo para média prioridade
  print('');
  print('');
  print('⚠️ CORES HARDCODED (Violação do Design System):');
  print('-' * 80);

  final byFile = <String, List<Issue>>{};
  for (final issue in mediaPrioridade) {
    byFile.putIfAbsent(issue.file, () => []).add(issue);
  }

  for (final entry in byFile.entries) {
    print('');
    print('📄 ${entry.key}');
    
    // Agrupar por tipo de cor
    final byPattern = <String, List<Issue>>{};
    for (final issue in entry.value) {
      byPattern.putIfAbsent(issue.match, () => []).add(issue);
    }

    for (final patternEntry in byPattern.entries) {
      final lines = patternEntry.value.map((i) => i.line).join(', ');
      print('   ${patternEntry.key}: linhas [$lines]');
      print('   💡 ${patternEntry.value.first.suggestion}');
    }
  }

  // Resumo final
  print('');
  print('═' * 80);
  print('📈 RESUMO');
  print('═' * 80);
  print('');
  print('🔴 Alta prioridade (texto invisível): ${altaPrioridade.length}');
  print('🟡 Média prioridade (design system): ${mediaPrioridade.length}');
  print('');
  print('📁 Arquivos com problemas: ${byFile.length}');
  print('');

  // Top 5 arquivos com mais problemas
  final sortedFiles = byFile.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));

  print('📊 Top 5 arquivos com mais problemas:');
  for (var i = 0; i < 5 && i < sortedFiles.length; i++) {
    print('   ${i + 1}. ${sortedFiles[i].key.split('/').last} (${sortedFiles[i].value.length} problemas)');
  }

  print('');
  print('💡 Execute: flutter analyze para verificar outros problemas de código.');
  print('');

  // Exit code baseado em problemas críticos
  if (altaPrioridade.isNotEmpty) {
    print('❌ Encontrados ${altaPrioridade.length} problemas críticos de contraste!');
    exit(1);
  } else {
    print('✅ Nenhum problema crítico de contraste encontrado.');
    exit(0);
  }
}


