import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/expense.dart';
import '../../core/expense_filters.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/financial_goal.dart';
import '../../domain/entities/financial_profile.dart';

/// Logger helper para o QuickAnalysisService
void _log(String message, {String level = 'INFO'}) {
  final prefix = switch (level) {
    'ERROR' => '❌ [QuickAnalysisService]',
    'WARNING' => '⚠️ [QuickAnalysisService]',
    'SUCCESS' => '✅ [QuickAnalysisService]',
    'AI' => '🤖 [QuickAnalysisService-IA]',
    'DATA' => '📊 [QuickAnalysisService]',
    _ => '📋 [QuickAnalysisService]',
  };
  debugPrint('$prefix $message');
}

/// Dados de uma categoria dominante
class DominantCategoryData {
  final String categoryId;
  final String categoryName;
  final double amount;
  final double percentage;
  final int transactionCount;

  const DominantCategoryData({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
  });
}

/// Resultado da análise rápida
class QuickAnalysisResult {
  final double totalSpent;
  final double budget;
  final double remaining;
  final double percentageUsed;
  final List<DominantCategoryData> dominantCategories;
  final List<FinancialGoal> exceededGoals;
  final List<FinancialGoal> warningGoals;
  final String aiSummaryText;
  final List<String> suggestions;

  const QuickAnalysisResult({
    required this.totalSpent,
    required this.budget,
    required this.remaining,
    required this.percentageUsed,
    required this.dominantCategories,
    required this.exceededGoals,
    required this.warningGoals,
    required this.aiSummaryText,
    required this.suggestions,
  });
}

/// Serviço para gerar análises rápidas com texto em linguagem natural
class QuickAnalysisService extends GetxService {
  static QuickAnalysisService get instance => Get.find<QuickAnalysisService>();

  /// Gerar análise completa do mês
  QuickAnalysisResult generateMonthAnalysis({
    required List<Expense> expenses,
    required List<ExpenseCategory> categories,
    required List<FinancialGoal> goals,
    FinancialProfile? profile,
    required DateTime referenceDate,
  }) {
    _log('═══════════════════════════════════════════════════════════════');
    _log('INICIANDO ANÁLISE DO MÊS', level: 'INFO');
    _log('═══════════════════════════════════════════════════════════════');
    
    _log('📅 Data de referência: ${referenceDate.day}/${referenceDate.month}/${referenceDate.year}', level: 'DATA');
    _log('📦 Dados recebidos:', level: 'DATA');
    _log('   - Despesas: ${expenses.length} registros', level: 'DATA');
    _log('   - Categorias: ${categories.length} registros', level: 'DATA');
    _log('   - Metas financeiras: ${goals.length} registros', level: 'DATA');
    _log('   - Perfil financeiro: ${profile != null ? "SIM" : "NÃO"}', level: 'DATA');
    
    // Filtrar investimentos das despesas (investimentos não são despesas)
    final expensesWithoutInvestments = ExpenseFilters.excludeInvestments(expenses);
    
    // Calcular total gasto (sem investimentos)
    final totalSpent = expensesWithoutInvestments.fold(0.0, (sum, e) => sum + e.amount);
    _log('💰 Total gasto calculado: R\$ ${totalSpent.toStringAsFixed(2)}', level: 'DATA');
    
    // Calcular orçamento
    final double budget = profile?.totalBudget ?? 
        goals.fold<double>(0.0, (sum, g) => sum + g.monthlyLimit);
    _log('📊 Orçamento total: R\$ ${budget.toStringAsFixed(2)} (fonte: ${profile != null ? "perfil" : "soma das metas"})', level: 'DATA');
    
    // Calcular restante
    final remaining = budget - totalSpent;
    final percentageUsed = budget > 0 ? (totalSpent / budget * 100) : 0.0;
    _log('📈 Percentual usado: ${percentageUsed.toStringAsFixed(1)}%', level: 'DATA');
    _log('💵 Restante: R\$ ${remaining.toStringAsFixed(2)}', level: 'DATA');
    
    // Calcular categorias dominantes
    _log('🔍 Calculando categorias dominantes...', level: 'INFO');
    final dominantCategories = _calculateDominantCategories(
      expenses, categories, totalSpent,
    );
    _log('📊 Categorias dominantes encontradas: ${dominantCategories.length}', level: 'SUCCESS');
    for (var i = 0; i < dominantCategories.length; i++) {
      final cat = dominantCategories[i];
      _log('   ${i + 1}. ${cat.categoryName}: R\$ ${cat.amount.toStringAsFixed(2)} (${cat.percentage.toStringAsFixed(1)}%)', level: 'DATA');
    }
    
    // Separar metas excedidas e em alerta
    final exceededGoals = goals.where((g) => g.isExceeded && g.isActive).toList();
    final warningGoals = goals.where((g) => 
      g.status == FinancialGoalStatus.warning && g.isActive && !g.isExceeded
    ).toList();
    
    _log('⚠️ Metas excedidas: ${exceededGoals.length}', level: exceededGoals.isNotEmpty ? 'WARNING' : 'INFO');
    for (final goal in exceededGoals) {
      _log('   - ${goal.categoryName}: ${(goal.progressPercentage * 100).toStringAsFixed(0)}%', level: 'WARNING');
    }
    _log('🔶 Metas em alerta: ${warningGoals.length}', level: warningGoals.isNotEmpty ? 'WARNING' : 'INFO');
    for (final goal in warningGoals) {
      _log('   - ${goal.categoryName}: ${(goal.progressPercentage * 100).toStringAsFixed(0)}%', level: 'WARNING');
    }
    
    // Gerar texto de análise
    _log('🤖 GERANDO TEXTO DE ANÁLISE COM IA...', level: 'AI');
    final aiSummaryText = _generateAISummaryText(
      totalSpent: totalSpent,
      budget: budget,
      remaining: remaining,
      percentageUsed: percentageUsed,
      dominantCategories: dominantCategories,
      exceededGoals: exceededGoals,
      warningGoals: warningGoals,
      referenceDate: referenceDate,
    );
    _log('🤖 Texto gerado com ${aiSummaryText.length} caracteres', level: 'AI');
    
    // Gerar sugestões
    _log('💡 Gerando sugestões personalizadas...', level: 'AI');
    final suggestions = _generateSuggestions(
      totalSpent: totalSpent,
      budget: budget,
      dominantCategories: dominantCategories,
      exceededGoals: exceededGoals,
      warningGoals: warningGoals,
    );
    _log('💡 ${suggestions.length} sugestões geradas', level: 'SUCCESS');
    for (var i = 0; i < suggestions.length; i++) {
      _log('   ${i + 1}. ${suggestions[i].substring(0, suggestions[i].length.clamp(0, 50))}...', level: 'DATA');
    }
    
    _log('═══════════════════════════════════════════════════════════════');
    _log('ANÁLISE CONCLUÍDA COM SUCESSO', level: 'SUCCESS');
    _log('═══════════════════════════════════════════════════════════════');
    
    return QuickAnalysisResult(
      totalSpent: totalSpent,
      budget: budget,
      remaining: remaining,
      percentageUsed: percentageUsed,
      dominantCategories: dominantCategories,
      exceededGoals: exceededGoals,
      warningGoals: warningGoals,
      aiSummaryText: aiSummaryText,
      suggestions: suggestions,
    );
  }

  /// Calcular categorias dominantes (top 3)
  List<DominantCategoryData> _calculateDominantCategories(
    List<Expense> expenses,
    List<ExpenseCategory> categories,
    double totalSpent,
  ) {
    _log('📊 Calculando categorias dominantes...', level: 'DATA');
    _log('   Entrada: ${expenses.length} despesas, ${categories.length} categorias, total R\$ ${totalSpent.toStringAsFixed(2)}', level: 'DATA');
    
    // Agrupar por categoria
    final categorySpending = <String, double>{};
    final categoryCount = <String, int>{};
    
    for (final expense in expenses) {
      categorySpending[expense.categoryId] = 
          (categorySpending[expense.categoryId] ?? 0) + expense.amount;
      categoryCount[expense.categoryId] = 
          (categoryCount[expense.categoryId] ?? 0) + 1;
    }
    
    _log('   ${categorySpending.length} categorias com gastos detectadas', level: 'DATA');
    
    // Ordenar por valor
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Pegar top 3
    final result = sortedCategories.take(3).map((entry) {
      final category = _findCategoryById(entry.key, categories);
      final percentage = totalSpent > 0 ? (entry.value / totalSpent * 100) : 0.0;
      
      final categoryName = category?.name ?? _getCategoryNameFromId(entry.key);
      
      return DominantCategoryData(
        categoryId: entry.key,
        categoryName: categoryName,
        amount: entry.value,
        percentage: percentage,
        transactionCount: categoryCount[entry.key] ?? 0,
      );
    }).toList();
    
    _log('   Top ${result.length} categorias selecionadas', level: 'SUCCESS');
    
    return result;
  }
  
  /// Busca categoria por ID com fallback para IDs sem sufixo do usuário
  ExpenseCategory? _findCategoryById(String categoryId, List<ExpenseCategory> categories) {
    if (categoryId.isEmpty || categories.isEmpty) return null;
    
    // 1. Tentar match exato
    final exactMatch = categories.firstWhereOrNull((cat) => cat.id == categoryId);
    if (exactMatch != null) return exactMatch;
    
    // 2. Tentar match onde o ID da categoria começa com o categoryId buscado
    final startsWithMatch = categories.firstWhereOrNull(
      (cat) => cat.id.startsWith('${categoryId}_')
    );
    if (startsWithMatch != null) return startsWithMatch;
    
    // 3. Tentar match onde o categoryId começa com o ID base da categoria
    final reverseMatch = categories.firstWhereOrNull(
      (cat) => categoryId.startsWith('${cat.id}_')
    );
    if (reverseMatch != null) return reverseMatch;
    
    // 4. Extrair ID base e tentar match
    final baseId = _extractBaseCategoryId(categoryId);
    if (baseId != categoryId) {
      return categories.firstWhereOrNull(
        (cat) => cat.id == baseId || 
                 cat.id.startsWith('${baseId}_') ||
                 _extractBaseCategoryId(cat.id) == baseId
      );
    }
    
    return null;
  }
  
  /// Extrai o ID base de uma categoria removendo o sufixo do usuário
  String _extractBaseCategoryId(String categoryId) {
    final defaultIds = [
      'alimentacao', 'transporte', 'saude', 'contas', 'lazer',
      'casa', 'educacao', 'roupas', 'tecnologia', 'pets', 'outros', 'investimentos'
    ];
    
    for (final baseId in defaultIds) {
      if (categoryId == baseId || categoryId.startsWith('${baseId}_')) {
        return baseId;
      }
    }
    return categoryId;
  }
  
  /// Obtém o nome da categoria a partir do ID base
  String _getCategoryNameFromId(String categoryId) {
    final baseId = _extractBaseCategoryId(categoryId);
    
    final categoryNames = {
      'alimentacao': 'Alimentação',
      'transporte': 'Transporte',
      'saude': 'Saúde',
      'contas': 'Contas',
      'lazer': 'Lazer',
      'casa': 'Casa',
      'educacao': 'Educação',
      'roupas': 'Roupas e Beleza',
      'tecnologia': 'Tecnologia',
      'pets': 'Pets',
      'outros': 'Outros',
      'investimentos': 'Investimentos',
    };
    
    return categoryNames[baseId] ?? 'Categoria';
  }

  /// Gerar texto de resumo em linguagem natural
  String _generateAISummaryText({
    required double totalSpent,
    required double budget,
    required double remaining,
    required double percentageUsed,
    required List<DominantCategoryData> dominantCategories,
    required List<FinancialGoal> exceededGoals,
    required List<FinancialGoal> warningGoals,
    required DateTime referenceDate,
  }) {
    _log('───────────────────────────────────────────────────────────────', level: 'AI');
    _log('LÓGICA DE GERAÇÃO DE TEXTO IA', level: 'AI');
    _log('───────────────────────────────────────────────────────────────', level: 'AI');
    
    final buffer = StringBuffer();
    final monthName = _getMonthName(referenceDate.month);
    final daysInMonth = DateTime(referenceDate.year, referenceDate.month + 1, 0).day;
    final daysPassed = referenceDate.day;
    final daysRemaining = daysInMonth - daysPassed;
    
    _log('📅 Contexto temporal:', level: 'AI');
    _log('   - Mês: $monthName', level: 'AI');
    _log('   - Dias no mês: $daysInMonth', level: 'AI');
    _log('   - Dias passados: $daysPassed', level: 'AI');
    _log('   - Dias restantes: $daysRemaining', level: 'AI');
    
    // Abertura - DECISÃO DE LÓGICA
    _log('🔀 Decisão de abertura baseada em percentageUsed: ${percentageUsed.toStringAsFixed(1)}%', level: 'AI');
    if (percentageUsed > 100) {
      _log('   → Escolhido: ALERTA CRÍTICO (>100%)', level: 'AI');
      buffer.write('⚠️ Atenção! Você já ultrapassou o orçamento de $monthName. ');
    } else if (percentageUsed > 80) {
      _log('   → Escolhido: ALERTA MODERADO (>80%)', level: 'AI');
      buffer.write('📊 Seus gastos em $monthName estão próximos do limite. ');
    } else if (percentageUsed > 50) {
      _log('   → Escolhido: NEUTRO (>50%)', level: 'AI');
      buffer.write('💰 Você está na metade do caminho em $monthName. ');
    } else {
      _log('   → Escolhido: POSITIVO (<=50%)', level: 'AI');
      buffer.write('✨ Excelente controle em $monthName! ');
    }
    
    // Resumo de valores
    buffer.write('Até agora, você gastou R\$ ${totalSpent.toStringAsFixed(2)}');
    if (budget > 0) {
      buffer.write(' de um orçamento de R\$ ${budget.toStringAsFixed(2)}');
      buffer.write(' (${percentageUsed.round()}% utilizado). ');
    } else {
      buffer.write('. ');
    }
    
    // Categorias dominantes
    if (dominantCategories.isNotEmpty) {
      final topCategory = dominantCategories.first;
      buffer.write('\n\n📌 A categoria "${topCategory.categoryName}" representa ');
      buffer.write('${topCategory.percentage.round()}% dos seus gastos ');
      buffer.write('(R\$ ${topCategory.amount.toStringAsFixed(2)}). ');
      
      if (dominantCategories.length > 1) {
        final secondCategory = dominantCategories[1];
        buffer.write('Em segundo lugar vem "${secondCategory.categoryName}" ');
        buffer.write('com ${secondCategory.percentage.round()}%. ');
      }
    }
    
    // Alertas de excesso
    if (exceededGoals.isNotEmpty) {
      buffer.write('\n\n🚨 Você excedeu o limite em ${exceededGoals.length} ');
      buffer.write(exceededGoals.length == 1 ? 'categoria: ' : 'categorias: ');
      buffer.write(exceededGoals.map((g) => g.categoryName).join(', '));
      buffer.write('. Considere revisar esses gastos. ');
    }
    
    if (warningGoals.isNotEmpty) {
      buffer.write('\n\n⚠️ ${warningGoals.length} ');
      buffer.write(warningGoals.length == 1 ? 'categoria está' : 'categorias estão');
      buffer.write(' próximas do limite: ');
      buffer.write(warningGoals.map((g) => '${g.categoryName} (${(g.progressPercentage * 100).round()}%)').join(', '));
      buffer.write('. ');
    }
    
    // Projeção
    _log('🔮 Gerando projeção...', level: 'AI');
    if (daysRemaining > 0 && remaining > 0) {
      final dailyBudget = remaining / daysRemaining;
      _log('   → Cenário: Dentro do orçamento, calculando limite diário', level: 'AI');
      _log('   → Limite diário calculado: R\$ ${dailyBudget.toStringAsFixed(2)}', level: 'AI');
      buffer.write('\n\n📅 Para os próximos $daysRemaining dias, você pode gastar ');
      buffer.write('até R\$ ${dailyBudget.toStringAsFixed(2)} por dia.');
    } else if (daysRemaining > 0 && remaining < 0) {
      _log('   → Cenário: Orçamento excedido, gerando alerta', level: 'AI');
      buffer.write('\n\n📅 Você já excedeu o orçamento em R\$ ${remaining.abs().toStringAsFixed(2)}. ');
      buffer.write('Tente evitar gastos não essenciais nos próximos $daysRemaining dias.');
    } else {
      _log('   → Cenário: Sem projeção (fim do mês ou sem orçamento)', level: 'AI');
    }
    
    final result = buffer.toString().trim();
    _log('───────────────────────────────────────────────────────────────', level: 'AI');
    _log('TEXTO FINAL GERADO (${result.length} chars)', level: 'AI');
    _log('───────────────────────────────────────────────────────────────', level: 'AI');
    
    return result;
  }

  /// Gerar sugestões personalizadas
  List<String> _generateSuggestions({
    required double totalSpent,
    required double budget,
    required List<DominantCategoryData> dominantCategories,
    required List<FinancialGoal> exceededGoals,
    required List<FinancialGoal> warningGoals,
  }) {
    _log('───────────────────────────────────────────────────────────────', level: 'AI');
    _log('LÓGICA DE GERAÇÃO DE SUGESTÕES', level: 'AI');
    _log('───────────────────────────────────────────────────────────────', level: 'AI');
    
    final suggestions = <String>[];
    
    // Sugestão baseada no uso do orçamento
    final percentageUsed = budget > 0 ? (totalSpent / budget * 100) : 0.0;
    _log('📊 Analisando uso do orçamento: ${percentageUsed.toStringAsFixed(1)}%', level: 'AI');
    
    if (percentageUsed > 100) {
      _log('   → Adicionando sugestões para orçamento excedido', level: 'AI');
      suggestions.add('Evite gastos não essenciais até o final do mês');
      suggestions.add('Analise os gastos excedidos e busque alternativas mais baratas');
    } else if (percentageUsed > 80) {
      _log('   → Adicionando sugestão para orçamento próximo do limite', level: 'AI');
      suggestions.add('Limite seus gastos nos próximos dias para não exceder o orçamento');
    }
    
    // Sugestão baseada em categorias excedidas
    _log('📊 Analisando ${exceededGoals.length} categorias excedidas', level: 'AI');
    for (final goal in exceededGoals.take(2)) {
      final excess = goal.currentSpent - goal.monthlyLimit;
      _log('   → Sugestão para "${goal.categoryName}": excesso de R\$ ${excess.toStringAsFixed(2)}', level: 'AI');
      suggestions.add(
        'Reduza gastos em "${goal.categoryName}" - você está R\$ ${excess.toStringAsFixed(2)} acima do limite'
      );
    }
    
    // Sugestão baseada em categorias dominantes
    _log('📊 Analisando categorias dominantes', level: 'AI');
    if (dominantCategories.isNotEmpty) {
      final topCategory = dominantCategories.first;
      if (topCategory.percentage > 40) {
        _log('   → "${topCategory.categoryName}" muito dominante: ${topCategory.percentage.round()}%', level: 'AI');
        suggestions.add(
          'A categoria "${topCategory.categoryName}" representa ${topCategory.percentage.round()}% dos gastos. Considere diversificar.'
        );
      } else {
        _log('   → Categorias bem distribuídas (top: ${topCategory.percentage.round()}%)', level: 'AI');
      }
    }
    
    // Sugestões gerais
    if (suggestions.isEmpty) {
      _log('   → Sem problemas detectados, adicionando sugestões positivas', level: 'AI');
      suggestions.add('Continue mantendo o controle dos seus gastos');
      suggestions.add('Considere criar uma reserva de emergência com o valor economizado');
    }
    
    _log('💡 Total de sugestões geradas: ${suggestions.length}', level: 'AI');
    _log('───────────────────────────────────────────────────────────────', level: 'AI');
    
    return suggestions.take(4).toList();
  }

  /// Gerar texto explicativo de onde está gastando demais
  String generateExcessAnalysisText({
    required List<FinancialGoal> exceededGoals,
    required List<FinancialGoal> warningGoals,
    required List<Expense> expenses,
    required List<ExpenseCategory> categories,
  }) {
    _log('═══════════════════════════════════════════════════════════════');
    _log('GERANDO ANÁLISE DE EXCESSO', level: 'AI');
    _log('═══════════════════════════════════════════════════════════════');
    _log('📊 Metas excedidas: ${exceededGoals.length}', level: 'DATA');
    _log('⚠️ Metas em alerta: ${warningGoals.length}', level: 'DATA');
    _log('📦 Despesas para análise: ${expenses.length}', level: 'DATA');
    
    final buffer = StringBuffer();
    
    if (exceededGoals.isEmpty && warningGoals.isEmpty) {
      _log('✅ Nenhum problema encontrado - retornando mensagem positiva', level: 'SUCCESS');
      return '✅ Parabéns! Você está dentro do orçamento em todas as categorias. Continue assim!';
    }
    
    // Metas excedidas
    if (exceededGoals.isNotEmpty) {
      buffer.write('🚨 **Categorias com orçamento excedido:**\n\n');
      
      for (final goal in exceededGoals) {
        final excess = goal.currentSpent - goal.monthlyLimit;
        final excessPercentage = ((goal.currentSpent / goal.monthlyLimit - 1) * 100).round();
        
        buffer.write('• **${goal.categoryName}**: Você gastou R\$ ${goal.currentSpent.toStringAsFixed(2)} ');
        buffer.write('de um limite de R\$ ${goal.monthlyLimit.toStringAsFixed(2)} ');
        buffer.write('(+$excessPercentage% acima, R\$ ${excess.toStringAsFixed(2)} a mais).\n');
        
        // Analisar gastos dessa categoria
        final categoryExpenses = expenses
            .where((e) => e.categoryId == goal.categoryId)
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));
        
        if (categoryExpenses.isNotEmpty) {
          final topExpense = categoryExpenses.first;
          buffer.write('  → Maior gasto: R\$ ${topExpense.amount.toStringAsFixed(2)}');
          if (topExpense.description.isNotEmpty) {
            buffer.write(' (${topExpense.description})');
          }
          buffer.write('\n');
        }
        buffer.write('\n');
      }
    }
    
    // Metas em alerta
    if (warningGoals.isNotEmpty) {
      buffer.write('⚠️ **Categorias próximas do limite:**\n\n');
      
      for (final goal in warningGoals) {
        final remaining = goal.remainingAmount;
        final percentage = (goal.progressPercentage * 100).round();
        
        buffer.write('• **${goal.categoryName}**: $percentage% utilizado ');
        buffer.write('(R\$ ${remaining.toStringAsFixed(2)} restante).\n');
      }
    }
    
    return buffer.toString().trim();
  }

  /// Gerar texto de resumo para a tela de resumo rápido
  String generateQuickSummaryText({
    required double totalSpent,
    required double budget,
    required int totalTransactions,
    required DateTime referenceDate,
  }) {
    _log('📝 Gerando texto de resumo rápido...', level: 'AI');
    _log('   - Total gasto: R\$ ${totalSpent.toStringAsFixed(2)}', level: 'DATA');
    _log('   - Orçamento: R\$ ${budget.toStringAsFixed(2)}', level: 'DATA');
    _log('   - Transações: $totalTransactions', level: 'DATA');
    
    final monthName = _getMonthName(referenceDate.month);
    final percentageUsed = budget > 0 ? (totalSpent / budget * 100) : 0.0;
    
    final buffer = StringBuffer();
    
    buffer.write('Em $monthName, você realizou $totalTransactions ');
    buffer.write(totalTransactions == 1 ? 'transação' : 'transações');
    buffer.write(' totalizando R\$ ${totalSpent.toStringAsFixed(2)}');
    
    if (budget > 0) {
      if (percentageUsed <= 100) {
        buffer.write(', utilizando ${percentageUsed.round()}% do seu orçamento.');
      } else {
        buffer.write(', ultrapassando o orçamento em ${(percentageUsed - 100).round()}%.');
      }
    } else {
      buffer.write('.');
    }
    
    _log('📝 Resumo gerado: ${buffer.toString().substring(0, buffer.toString().length.clamp(0, 60))}...', level: 'SUCCESS');
    
    return buffer.toString();
  }

  String _getMonthName(int month) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return months[month - 1];
  }
}

