import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/entities/category.dart';
import '../../../expenses/domain/entities/financial_goal.dart';
import '../../../expenses/presentation/controllers/expense_controller.dart';
import '../../../expenses/presentation/controllers/category_controller.dart';
import '../../../expenses/presentation/controllers/financial_goals_controller.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/logging_service.dart';

/// Modelo de pergunta rápida pré-estabelecida
class QuickQuestion {
  final String id;
  final String text;
  final String shortText;
  final IconData icon;
  final QuickQuestionCategory category;

  const QuickQuestion({
    required this.id,
    required this.text,
    required this.shortText,
    required this.icon,
    required this.category,
  });
}

/// Categoria de perguntas rápidas
enum QuickQuestionCategory {
  economy,    // Economia e cortes
  analysis,   // Análise de hábitos
  suggestion, // Sugestões personalizadas
}

/// Resultado de uma pergunta rápida
class QuickQuestionResult {
  final String questionId;
  final String response;
  final Map<String, dynamic> data;
  final bool hasData;

  const QuickQuestionResult({
    required this.questionId,
    required this.response,
    this.data = const {},
    this.hasData = true,
  });
}

/// Serviço para processar perguntas rápidas com respostas personalizadas
class QuickQuestionsService extends GetxService {
  static QuickQuestionsService get instance => Get.find<QuickQuestionsService>();

  @override
  void onInit() {
    super.onInit();
    AppLogger.info(FeatureTag.chat, '🚀 QuickQuestionsService inicializado', data: {
      'total_questions': availableQuestions.length,
      'categories': QuickQuestionCategory.values.map((c) => c.name).toList(),
    });
  }

  /// Lista de todas as perguntas rápidas disponíveis
  static const List<QuickQuestion> availableQuestions = [
    // Economia e Cortes
    QuickQuestion(
      id: 'what_to_cut',
      text: 'O que posso cortar este mês?',
      shortText: 'O que cortar?',
      icon: Icons.content_cut,
      category: QuickQuestionCategory.economy,
    ),
    QuickQuestion(
      id: 'spending_too_much',
      text: 'Onde estou gastando demais?',
      shortText: 'Gastando demais?',
      icon: Icons.warning_amber,
      category: QuickQuestionCategory.economy,
    ),
    
    // Análise de Hábitos
    QuickQuestion(
      id: 'delivery_spending',
      text: 'Estou gastando demais com delivery?',
      shortText: 'Delivery?',
      icon: Icons.delivery_dining,
      category: QuickQuestionCategory.analysis,
    ),
    QuickQuestion(
      id: 'biggest_expense_day',
      text: 'Qual meu dia de maior gasto?',
      shortText: 'Dia de maior gasto',
      icon: Icons.calendar_today,
      category: QuickQuestionCategory.analysis,
    ),
    QuickQuestion(
      id: 'month_summary',
      text: 'Como estou indo este mês?',
      shortText: 'Resumo do mês',
      icon: Icons.assessment,
      category: QuickQuestionCategory.analysis,
    ),
    
    // Sugestões Personalizadas
    QuickQuestion(
      id: 'savings_suggestion',
      text: 'Sugestão de economia para meu perfil',
      shortText: 'Sugestões',
      icon: Icons.lightbulb,
      category: QuickQuestionCategory.suggestion,
    ),
    QuickQuestion(
      id: 'daily_budget',
      text: 'Quanto posso gastar por dia?',
      shortText: 'Gasto diário',
      icon: Icons.today,
      category: QuickQuestionCategory.suggestion,
    ),
    QuickQuestion(
      id: 'goals_status',
      text: 'Quais metas estou cumprindo?',
      shortText: 'Status das metas',
      icon: Icons.flag,
      category: QuickQuestionCategory.suggestion,
    ),
  ];

  /// Processa uma pergunta rápida e retorna resposta personalizada
  Future<QuickQuestionResult> processQuestion(String questionId) async {
    final opId = AppLogger.startOp(FeatureTag.chat, 'process_quick_question', data: {
      'question_id': questionId,
    });
    
    AppLogger.info(FeatureTag.chat, '🤖 [QuickQ] Iniciando processamento de pergunta rápida', data: {
      'question_id': questionId,
      'question_text': getQuestionById(questionId)?.text ?? 'Não encontrada',
      'category': getQuestionById(questionId)?.category.name ?? 'unknown',
    });

    final startTime = DateTime.now();

    try {
      QuickQuestionResult result;
      
      AppLogger.debug(FeatureTag.chat, '🔄 [QuickQ] Roteando para handler específico', data: {
        'question_id': questionId,
      });
      
      switch (questionId) {
        case 'what_to_cut':
          AppLogger.debug(FeatureTag.chat, '📍 [QuickQ] Handler: _handleWhatToCut');
          result = await _handleWhatToCut();
          break;
        case 'spending_too_much':
          AppLogger.debug(FeatureTag.chat, '📍 [QuickQ] Handler: _handleSpendingTooMuch');
          result = await _handleSpendingTooMuch();
          break;
        case 'delivery_spending':
          AppLogger.debug(FeatureTag.chat, '📍 [QuickQ] Handler: _handleDeliverySpending');
          result = await _handleDeliverySpending();
          break;
        case 'biggest_expense_day':
          AppLogger.debug(FeatureTag.chat, '📍 [QuickQ] Handler: _handleBiggestExpenseDay');
          result = await _handleBiggestExpenseDay();
          break;
        case 'month_summary':
          AppLogger.debug(FeatureTag.chat, '📍 [QuickQ] Handler: _handleMonthSummary');
          result = await _handleMonthSummary();
          break;
        case 'savings_suggestion':
          AppLogger.debug(FeatureTag.chat, '📍 [QuickQ] Handler: _handleSavingsSuggestion');
          result = await _handleSavingsSuggestion();
          break;
        case 'daily_budget':
          AppLogger.debug(FeatureTag.chat, '📍 [QuickQ] Handler: _handleDailyBudget');
          result = await _handleDailyBudget();
          break;
        case 'goals_status':
          AppLogger.debug(FeatureTag.chat, '📍 [QuickQ] Handler: _handleGoalsStatus');
          result = await _handleGoalsStatus();
          break;
        default:
          AppLogger.warning(FeatureTag.chat, '⚠️ [QuickQ] Pergunta não reconhecida', data: {
            'question_id': questionId,
          });
          result = QuickQuestionResult(
            questionId: questionId,
            response: '❓ Desculpe, não reconheci essa pergunta. Tente uma das opções sugeridas.',
            hasData: false,
          );
      }
      
      final duration = DateTime.now().difference(startTime);
      AppLogger.completeOp(opId, message: 'Pergunta rápida processada com sucesso', data: {
        'question_id': questionId,
        'has_data': result.hasData,
        'response_length': result.response.length,
        'data_keys': result.data.keys.toList(),
        'duration_ms': duration.inMilliseconds,
      });
      
      AppLogger.info(FeatureTag.chat, '✅ [QuickQ] Resposta gerada', data: {
        'question_id': questionId,
        'response_preview': result.response.substring(0, result.response.length.clamp(0, 100)),
        'data_summary': result.data,
      });
      
      return result;
      
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      AppLogger.failOp(opId, 'Erro ao processar pergunta rápida', exception: e);
      AppLogger.error(FeatureTag.chat, '❌ [QuickQ] Exceção durante processamento', error: e, data: {
        'question_id': questionId,
        'duration_ms': duration.inMilliseconds,
        'stack_trace': stackTrace.toString().substring(0, 500),
      });
      
      return QuickQuestionResult(
        questionId: questionId,
        response: '❌ Ocorreu um erro ao processar sua pergunta. Tente novamente.',
        hasData: false,
      );
    }
  }

  // ============================================
  // HANDLERS DE PERGUNTAS
  // ============================================

  /// "O que posso cortar este mês?"
  Future<QuickQuestionResult> _handleWhatToCut() async {
    AppLogger.info(FeatureTag.chat, '🔍 [QuickQ:WhatToCut] Iniciando análise de cortes possíveis');
    
    final expenses = _getMonthExpenses();
    final categories = _getCategories();
    final goals = await _getGoals();

    AppLogger.debug(FeatureTag.chat, '📊 [QuickQ:WhatToCut] Dados carregados', data: {
      'expenses_count': expenses.length,
      'categories_count': categories.length,
      'goals_count': goals.length,
    });

    if (expenses.isEmpty) {
      AppLogger.info(FeatureTag.chat, '⚠️ [QuickQ:WhatToCut] Sem despesas - retornando mensagem padrão');
      return const QuickQuestionResult(
        questionId: 'what_to_cut',
        response: '📊 Você ainda não tem gastos registrados este mês.\n\n'
            'Registre seus gastos para que eu possa analisar oportunidades de economia!',
        hasData: false,
      );
    }
    
    AppLogger.debug(FeatureTag.chat, '🧮 [QuickQ:WhatToCut] Iniciando análise de categorias');

    final buffer = StringBuffer();
    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;
    final daysRemaining = daysInMonth - daysPassed;
    
    buffer.writeln('✂️ **Análise de Cortes Possíveis**\n');

    // 1. Identificar categorias com gastos acima do orçamento
    final exceededGoals = goals.where((g) => g.isExceeded && g.isActive).toList();
    final warningGoals = goals.where((g) => g.status == FinancialGoalStatus.warning && g.isActive).toList();

    if (exceededGoals.isNotEmpty) {
      buffer.writeln('🚨 **Categorias que precisam de atenção urgente:**\n');
      for (final goal in exceededGoals.take(3)) {
        final excess = goal.currentSpent - goal.monthlyLimit;
        buffer.writeln('• **${goal.categoryName}**: R\$ ${excess.toStringAsFixed(2)} acima do limite');
        
        // Encontrar maiores gastos dessa categoria
        final categoryExpenses = expenses
            .where((e) => e.categoryId == goal.categoryId)
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));
        
        if (categoryExpenses.isNotEmpty) {
          final topExpense = categoryExpenses.first;
          buffer.writeln('  → Maior gasto: R\$ ${topExpense.amount.toStringAsFixed(2)}');
          if (topExpense.description.isNotEmpty) {
            buffer.writeln('     (${topExpense.description})');
          }
        }
        buffer.writeln('');
      }
    }

    // 2. Identificar gastos não essenciais
    final nonEssentialCategories = ['lazer', 'entretenimento', 'roupas', 'compras', 'assinaturas', 'streaming'];
    final nonEssentialExpenses = expenses
        .where((e) => nonEssentialCategories.any((cat) => e.categoryId.toLowerCase().contains(cat)))
        .toList();

    final nonEssentialTotal = nonEssentialExpenses.fold(0.0, (sum, e) => sum + e.amount);
    
    if (nonEssentialTotal > 0) {
      buffer.writeln('💡 **Gastos não essenciais este mês:**\n');
      buffer.writeln('Total: R\$ ${nonEssentialTotal.toStringAsFixed(2)}\n');
      
      // Agrupar por categoria
      final grouped = <String, double>{};
      for (final expense in nonEssentialExpenses) {
        final category = _findCategoryById(expense.categoryId, categories);
        final categoryName = category?.name ?? _formatCategoryName(expense.categoryId);
        grouped[categoryName] = (grouped[categoryName] ?? 0) + expense.amount;
      }
      
      final sortedGroups = grouped.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (final entry in sortedGroups.take(3)) {
        buffer.writeln('• ${entry.key}: R\$ ${entry.value.toStringAsFixed(2)}');
      }
      buffer.writeln('');
    }

    // 3. Mostrar resumo dos gastos atuais (quando não há muito a cortar)
    if (exceededGoals.isEmpty && nonEssentialTotal == 0) {
      // Agrupar por categoria
      final categorySpending = <String, double>{};
      for (final expense in expenses) {
        categorySpending[expense.categoryId] = (categorySpending[expense.categoryId] ?? 0) + expense.amount;
      }
      
      final sortedCategories = categorySpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      buffer.writeln('📊 **Resumo dos seus gastos:**\n');
      buffer.writeln('💰 Total gasto: R\$ ${totalSpent.toStringAsFixed(2)}');
      buffer.writeln('📅 Dias restantes no mês: $daysRemaining\n');
      
      if (sortedCategories.isNotEmpty) {
        buffer.writeln('🏷️ **Onde você gastou:**\n');
        for (int i = 0; i < sortedCategories.length && i < 3; i++) {
          final entry = sortedCategories[i];
          final category = _findCategoryById(entry.key, categories);
          final categoryName = category?.name ?? _formatCategoryName(entry.key);
          final percentage = (entry.value / totalSpent * 100).round();
          buffer.writeln('• $categoryName: R\$ ${entry.value.toStringAsFixed(2)} ($percentage%)');
        }
        buffer.writeln('');
      }
    }

    // 4. Sugestões de economia
    buffer.writeln('💡 **Sugestões de economia:**\n');
    
    bool hasSuggestions = false;
    
    if (exceededGoals.isNotEmpty) {
      buffer.writeln('• Reduza gastos em ${exceededGoals.first.categoryName} nos próximos dias');
      hasSuggestions = true;
    }
    
    if (nonEssentialTotal > 100) {
      buffer.writeln('• Considere reduzir gastos não essenciais em 20% (economia de ~R\$ ${(nonEssentialTotal * 0.2).toStringAsFixed(2)})');
      hasSuggestions = true;
    }
    
    if (warningGoals.isNotEmpty) {
      buffer.writeln('• Monitore gastos em ${warningGoals.map((g) => g.categoryName).join(', ')}');
      hasSuggestions = true;
    }

    // 5. Sugestões gerais quando não há problemas específicos
    if (!hasSuggestions) {
      if (goals.isEmpty) {
        buffer.writeln('• 🎯 **Configure metas financeiras** para acompanhar melhor seus gastos');
        buffer.writeln('  → Vá em Perfil > Metas Financeiras');
        buffer.writeln('');
      }
      
      // Dicas baseadas nas categorias existentes
      final hasFood = expenses.any((e) => e.categoryId.contains('alimentacao'));
      final hasTransport = expenses.any((e) => e.categoryId.contains('transporte'));
      
      if (hasFood) {
        buffer.writeln('• 🍽️ **Alimentação**: Planeje refeições semanais para evitar gastos impulsivos');
      }
      
      if (hasTransport) {
        buffer.writeln('• 🚗 **Transporte**: Compare preços de combustível e considere caronas');
      }
      
      // Dica baseada no padrão de gastos
      if (expenses.length >= 3) {
        final avgExpense = totalSpent / expenses.length;
        buffer.writeln('• 💵 Média por transação: R\$ ${avgExpense.toStringAsFixed(2)} - avalie se cada gasto é necessário');
      }
      
      // Projeção para o fim do mês
      if (daysPassed >= 5 && daysRemaining > 0) {
        final dailyAvg = totalSpent / daysPassed;
        final projectedTotal = dailyAvg * daysInMonth;
        buffer.writeln('');
        buffer.writeln('📈 **Projeção:** Se mantiver o ritmo atual, você gastará ~R\$ ${projectedTotal.toStringAsFixed(2)} este mês');
      }
    }
    
    // 6. Dica motivacional final
    if (exceededGoals.isEmpty && warningGoals.isEmpty) {
      buffer.writeln('');
      buffer.writeln('✅ **Bom trabalho!** Seus gastos parecem estar sob controle.');
    }

    AppLogger.info(FeatureTag.chat, '✅ [QuickQ:WhatToCut] Análise concluída', data: {
      'exceeded_goals_count': exceededGoals.length,
      'warning_goals_count': warningGoals.length,
      'non_essential_total': nonEssentialTotal,
      'total_spent': totalSpent,
      'has_specific_suggestions': hasSuggestions,
      'suggestions_generated': buffer.toString().split('\n').length,
    });

    return QuickQuestionResult(
      questionId: 'what_to_cut',
      response: buffer.toString(),
      data: {
        'exceeded_goals': exceededGoals.length,
        'non_essential_total': nonEssentialTotal,
        'total_spent': totalSpent,
      },
    );
  }

  /// Formata nome de categoria a partir do ID
  String _formatCategoryName(String categoryId) {
    // Primeiro, tenta encontrar pelo mapeamento de IDs padrão
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
    
    if (categoryNames.containsKey(baseId)) {
      return categoryNames[baseId]!;
    }
    
    // Fallback para formatação genérica
    final formatted = categoryId
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');
    return formatted.isEmpty ? 'Outros' : 
        '${formatted[0].toUpperCase()}${formatted.substring(1)}';
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

  /// "Onde estou gastando demais?"
  Future<QuickQuestionResult> _handleSpendingTooMuch() async {
    final expenses = _getMonthExpenses();
    final categories = _getCategories();
    final goals = await _getGoals();

    if (expenses.isEmpty) {
      return const QuickQuestionResult(
        questionId: 'spending_too_much',
        response: '📊 Você ainda não tem gastos registrados este mês.\n\n'
            'Comece a registrar para que eu possa identificar padrões!',
        hasData: false,
      );
    }

    final buffer = StringBuffer();
    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final now = DateTime.now();
    final daysPassed = now.day;
    
    buffer.writeln('📊 **Análise de Gastos**\n');
    buffer.writeln('💰 Total gasto este mês: R\$ ${totalSpent.toStringAsFixed(2)}');
    buffer.writeln('📅 ${expenses.length} ${expenses.length == 1 ? 'transação' : 'transações'} em $daysPassed dias\n');

    // Agrupar gastos por categoria
    final categorySpending = <String, double>{};
    final categoryCount = <String, int>{};
    
    for (final expense in expenses) {
      categorySpending[expense.categoryId] = (categorySpending[expense.categoryId] ?? 0) + expense.amount;
      categoryCount[expense.categoryId] = (categoryCount[expense.categoryId] ?? 0) + 1;
    }

    // Ordenar por valor
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 1. Mostrar top categorias
    final maxCategories = sortedCategories.length.clamp(1, 3);
    buffer.writeln('🏆 **${maxCategories == 1 ? 'Sua categoria principal' : 'Top $maxCategories categorias com mais gastos'}:**\n');
    
    for (int i = 0; i < sortedCategories.length && i < 3; i++) {
      final entry = sortedCategories[i];
      final category = _findCategoryById(entry.key, categories);
      final categoryName = category?.name ?? _formatCategoryName(entry.key);
      final percentage = (entry.value / totalSpent * 100).round();
      final count = categoryCount[entry.key] ?? 0;
      
      final goal = goals.firstWhereOrNull((g) => g.categoryId == entry.key);
      String statusEmoji = '📌';
      String extraInfo = '';
      
      if (goal != null && goal.isActive) {
        if (goal.isExceeded) {
          statusEmoji = '🚨';
          extraInfo = ' (acima do limite!)';
        } else if (goal.status == FinancialGoalStatus.warning) {
          statusEmoji = '⚠️';
          extraInfo = ' (próximo do limite)';
        } else {
          statusEmoji = '✅';
          final used = (goal.progressPercentage * 100).round();
          extraInfo = ' ($used% do limite)';
        }
      }
      
      buffer.writeln('$statusEmoji **${i + 1}. $categoryName**: R\$ ${entry.value.toStringAsFixed(2)} ($percentage%)$extraInfo');
      buffer.writeln('   $count ${count == 1 ? 'transação' : 'transações'}');
      buffer.writeln('');
    }

    // 2. Alertar categorias excedidas
    final exceededGoals = goals.where((g) => g.isExceeded && g.isActive).toList();
    if (exceededGoals.isNotEmpty) {
      buffer.writeln('🚨 **Atenção! ${exceededGoals.length} ${exceededGoals.length == 1 ? 'categoria excedeu' : 'categorias excederam'} o orçamento:**\n');
      for (final goal in exceededGoals) {
        final excess = goal.currentSpent - goal.monthlyLimit;
        buffer.writeln('• ${goal.categoryName}: +R\$ ${excess.toStringAsFixed(2)} acima');
      }
    } else if (goals.isNotEmpty) {
      buffer.writeln('✅ **Bom trabalho!** Nenhuma categoria excedeu o orçamento até agora.');
    } else {
      // Sem metas configuradas
      buffer.writeln('💡 **Dica:** Configure metas financeiras para receber alertas quando estiver gastando demais!');
      buffer.writeln('   → Vá em Perfil > Metas Financeiras');
    }

    // 3. Análise comparativa (se houver dados suficientes)
    if (daysPassed >= 7 && expenses.length >= 3) {
      buffer.writeln('');
      final dailyAvg = totalSpent / daysPassed;
      buffer.writeln('📈 **Média diária:** R\$ ${dailyAvg.toStringAsFixed(2)}/dia');
      
      // Maior gasto
      final sorted = expenses.toList()..sort((a, b) => b.amount.compareTo(a.amount));
      final topExpense = sorted.first;
      buffer.writeln('🔝 **Maior gasto:** R\$ ${topExpense.amount.toStringAsFixed(2)}');
      if (topExpense.description.isNotEmpty) {
        buffer.writeln('   (${topExpense.description})');
      }
    }

    return QuickQuestionResult(
      questionId: 'spending_too_much',
      response: buffer.toString(),
      data: {
        'total_spent': totalSpent,
        'top_category': sortedCategories.isNotEmpty ? sortedCategories.first.key : null,
        'exceeded_goals': exceededGoals.length,
      },
    );
  }

  /// "Estou gastando demais com delivery?"
  Future<QuickQuestionResult> _handleDeliverySpending() async {
    final expenses = _getMonthExpenses();
    
    if (expenses.isEmpty) {
      return const QuickQuestionResult(
        questionId: 'delivery_spending',
        response: '📊 Você ainda não tem gastos registrados este mês.\n\n'
            'Registre seus gastos com delivery para analisar!',
        hasData: false,
      );
    }

    // Palavras-chave para identificar delivery
    final deliveryKeywords = ['ifood', 'rappi', 'uber eats', 'delivery', 'entrega', 'zé delivery', 'aiqfome'];
    
    final deliveryExpenses = expenses.where((e) {
      final description = e.description.toLowerCase();
      return deliveryKeywords.any((keyword) => description.contains(keyword)) ||
             (e.categoryId == 'alimentacao' && description.contains('app'));
    }).toList();

    // Também considerar alimentação em geral
    final foodExpenses = expenses.where((e) => e.categoryId == 'alimentacao').toList();
    
    final totalDelivery = deliveryExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalFood = foodExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);

    final buffer = StringBuffer();
    buffer.writeln('🛵 **Análise de Gastos com Delivery**\n');

    if (deliveryExpenses.isEmpty) {
      buffer.writeln('Não encontrei gastos identificados como delivery este mês.\n');
      buffer.writeln('**Dica:** Ao registrar gastos com delivery, inclua o nome do app na descrição (ex: "iFood", "Rappi").\n');
      
      if (foodExpenses.isNotEmpty) {
        buffer.writeln('📊 **Gastos com Alimentação:**');
        buffer.writeln('Total: R\$ ${totalFood.toStringAsFixed(2)} (${(totalFood / totalSpent * 100).round()}% do total)');
        buffer.writeln('${foodExpenses.length} transações');
      }
    } else {
      final deliveryPercentOfFood = totalFood > 0 ? (totalDelivery / totalFood * 100) : 0;
      final deliveryPercentOfTotal = (totalDelivery / totalSpent * 100);
      
      buffer.writeln('💰 **Gastos com Delivery:** R\$ ${totalDelivery.toStringAsFixed(2)}');
      buffer.writeln('📊 ${deliveryExpenses.length} pedidos este mês');
      buffer.writeln('📈 ${deliveryPercentOfFood.round()}% dos gastos com alimentação');
      buffer.writeln('📈 ${deliveryPercentOfTotal.round()}% do total gasto\n');

      // Média por pedido
      final avgPerOrder = totalDelivery / deliveryExpenses.length;
      buffer.writeln('💵 Média por pedido: R\$ ${avgPerOrder.toStringAsFixed(2)}\n');

      // Análise
      if (deliveryPercentOfFood > 50) {
        buffer.writeln('⚠️ **Atenção!** Você gasta mais da metade do orçamento de alimentação com delivery.\n');
        buffer.writeln('💡 **Sugestão:** Cozinhar em casa pode economizar até 60% comparado ao delivery.\n');
        
        final potentialSavings = totalDelivery * 0.5;
        buffer.writeln('💰 Economia potencial: ~R\$ ${potentialSavings.toStringAsFixed(2)}/mês');
      } else if (deliveryPercentOfFood > 30) {
        buffer.writeln('📊 Seus gastos com delivery estão na média. Considere equilibrar com mais refeições em casa.');
      } else {
        buffer.writeln('✅ **Parabéns!** Você mantém os gastos com delivery sob controle.');
      }
    }

    return QuickQuestionResult(
      questionId: 'delivery_spending',
      response: buffer.toString(),
      data: {
        'delivery_total': totalDelivery,
        'delivery_count': deliveryExpenses.length,
        'food_total': totalFood,
      },
    );
  }

  /// "Qual meu dia de maior gasto?"
  Future<QuickQuestionResult> _handleBiggestExpenseDay() async {
    final expenses = _getMonthExpenses();
    
    if (expenses.isEmpty) {
      return const QuickQuestionResult(
        questionId: 'biggest_expense_day',
        response: '📊 Você ainda não tem gastos registrados este mês.\n\n'
            'Registre seus gastos para descobrir seus padrões!',
        hasData: false,
      );
    }

    final buffer = StringBuffer();
    buffer.writeln('📅 **Análise de Padrões por Dia da Semana**\n');

    // Agrupar por dia da semana
    final weekdaySpending = <int, double>{};
    final weekdayCount = <int, int>{};
    final weekdayNames = ['', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    
    for (final expense in expenses) {
      final weekday = expense.date.weekday;
      weekdaySpending[weekday] = (weekdaySpending[weekday] ?? 0) + expense.amount;
      weekdayCount[weekday] = (weekdayCount[weekday] ?? 0) + 1;
    }

    // Ordenar por valor gasto
    final sortedDays = weekdaySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
    
    // Dia de maior gasto
    final topDay = sortedDays.first;
    final topDayName = weekdayNames[topDay.key];
    final topDayPercentage = (topDay.value / totalSpent * 100).round();
    final topDayCount = weekdayCount[topDay.key] ?? 0;

    buffer.writeln('🏆 **Dia de Maior Gasto: $topDayName**');
    buffer.writeln('💰 Total: R\$ ${topDay.value.toStringAsFixed(2)} ($topDayPercentage% do total)');
    buffer.writeln('📊 $topDayCount transações\n');

    // Ranking completo
    buffer.writeln('📈 **Ranking por dia:**\n');
    for (int i = 0; i < sortedDays.length; i++) {
      final day = sortedDays[i];
      final dayName = weekdayNames[day.key];
      final percentage = (day.value / totalSpent * 100).round();
      final count = weekdayCount[day.key] ?? 0;
      
      String emoji = i == 0 ? '🥇' : (i == 1 ? '🥈' : (i == 2 ? '🥉' : '  '));
      buffer.writeln('$emoji $dayName: R\$ ${day.value.toStringAsFixed(2)} ($percentage%) - $count trans.');
    }

    // Sugestões
    buffer.writeln('\n💡 **Dica:**');
    if (topDay.key == 6 || topDay.key == 7) { // Fim de semana
      buffer.writeln('Você gasta mais nos finais de semana. Planeje atividades de lazer mais econômicas!');
    } else if (topDay.key == 1) { // Segunda
      buffer.writeln('Segundas são seus dias de maior gasto. Talvez compras pós-fim de semana?');
    } else if (topDay.key == 5) { // Sexta
      buffer.writeln('Sextas são seus dias de maior gasto. Típico de programas de fim de semana!');
    } else {
      buffer.writeln('Preste atenção especial aos seus gastos às ${topDayName}s.');
    }

    return QuickQuestionResult(
      questionId: 'biggest_expense_day',
      response: buffer.toString(),
      data: {
        'top_day': topDay.key,
        'top_day_name': topDayName,
        'top_day_amount': topDay.value,
      },
    );
  }

  /// "Como estou indo este mês?"
  Future<QuickQuestionResult> _handleMonthSummary() async {
    final expenses = _getMonthExpenses();
    final goals = await _getGoals();
    final categories = _getCategories();
    
    final buffer = StringBuffer();
    final now = DateTime.now();
    final monthName = _getMonthName(now.month);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;
    final daysRemaining = daysInMonth - daysPassed;

    buffer.writeln('📊 **Resumo de $monthName**\n');

    if (expenses.isEmpty && goals.isEmpty) {
      buffer.writeln('Você ainda não tem gastos ou metas registradas este mês.\n\n');
      buffer.writeln('📝 Comece a registrar seus gastos para acompanhar suas finanças!');
      return QuickQuestionResult(
        questionId: 'month_summary',
        response: buffer.toString(),
        hasData: false,
      );
    }

    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalBudget = goals.fold(0.0, (sum, g) => sum + g.monthlyLimit);
    final totalRemaining = totalBudget - totalSpent;
    final percentageUsed = totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0;

    // Status geral
    String statusEmoji;
    String statusText;
    if (percentageUsed > 100) {
      statusEmoji = '🚨';
      statusText = 'Orçamento Excedido';
    } else if (percentageUsed > 80) {
      statusEmoji = '⚠️';
      statusText = 'Próximo do Limite';
    } else if (percentageUsed > 50) {
      statusEmoji = '📈';
      statusText = 'Na Metade do Caminho';
    } else {
      statusEmoji = '✅';
      statusText = 'Dentro do Orçamento';
    }

    buffer.writeln('$statusEmoji **Status:** $statusText\n');
    
    // Valores principais
    buffer.writeln('💰 **Gasto até agora:** R\$ ${totalSpent.toStringAsFixed(2)}');
    if (totalBudget > 0) {
      buffer.writeln('📋 **Orçamento total:** R\$ ${totalBudget.toStringAsFixed(2)}');
      buffer.writeln('📊 **Utilizado:** ${percentageUsed.round()}%');
      buffer.writeln('💵 **Restante:** R\$ ${totalRemaining.toStringAsFixed(2)}\n');
    }
    
    buffer.writeln('📅 **Dias restantes:** $daysRemaining de $daysInMonth\n');

    // Gastos por categoria (top 3)
    final categorySpending = <String, double>{};
    for (final expense in expenses) {
      categorySpending[expense.categoryId] = (categorySpending[expense.categoryId] ?? 0) + expense.amount;
    }
    
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.isNotEmpty) {
      buffer.writeln('🏷️ **Principais categorias:**\n');
      for (int i = 0; i < sortedCategories.length && i < 3; i++) {
        final entry = sortedCategories[i];
        final category = _findCategoryById(entry.key, categories);
        final categoryName = category?.name ?? _formatCategoryName(entry.key);
        buffer.writeln('• $categoryName: R\$ ${entry.value.toStringAsFixed(2)}');
      }
      buffer.writeln('');
    }

    // Metas
    final exceededCount = goals.where((g) => g.isExceeded && g.isActive).length;
    final warningCount = goals.where((g) => g.status == FinancialGoalStatus.warning && g.isActive).length;
    final goodCount = goals.where((g) => g.status == FinancialGoalStatus.good && g.isActive).length;

    if (goals.isNotEmpty) {
      buffer.writeln('🎯 **Status das Metas:**');
      if (goodCount > 0) buffer.writeln('✅ $goodCount no caminho certo');
      if (warningCount > 0) buffer.writeln('⚠️ $warningCount precisam de atenção');
      if (exceededCount > 0) buffer.writeln('🚨 $exceededCount excedidas');
      buffer.writeln('');
    }

    // Projeção
    if (totalBudget > 0 && daysPassed > 5 && daysRemaining > 0) {
      final dailyAverage = totalSpent / daysPassed;
      final projectedTotal = dailyAverage * daysInMonth;
      
      if (projectedTotal > totalBudget * 1.1) {
        buffer.writeln('🔮 **Projeção:** No ritmo atual, você pode gastar ~R\$ ${projectedTotal.toStringAsFixed(2)} até o fim do mês.');
        buffer.writeln('💡 Reduza para R\$ ${(totalRemaining / daysRemaining).toStringAsFixed(2)}/dia para ficar dentro do orçamento.');
      }
    }

    return QuickQuestionResult(
      questionId: 'month_summary',
      response: buffer.toString(),
      data: {
        'total_spent': totalSpent,
        'total_budget': totalBudget,
        'percentage_used': percentageUsed,
        'days_remaining': daysRemaining,
      },
    );
  }

  /// "Sugestão de economia para meu perfil"
  Future<QuickQuestionResult> _handleSavingsSuggestion() async {
    final expenses = _getMonthExpenses();
    final goals = await _getGoals();
    final categories = _getCategories();
    
    final buffer = StringBuffer();
    buffer.writeln('💡 **Sugestões de Economia Personalizadas**\n');
    
    // Cenário: sem gastos registrados
    if (expenses.isEmpty) {
      buffer.writeln('📊 Você ainda não tem gastos registrados este mês.\n');
      buffer.writeln('Para criar sugestões personalizadas, registre seus gastos!\n');
      buffer.writeln('---\n');
      buffer.writeln('🌟 **Dicas gerais de economia:**\n');
      buffer.writeln('• 📝 Anote TODOS os gastos, mesmo os pequenos');
      buffer.writeln('• 🎯 Defina metas de gastos por categoria');
      buffer.writeln('• 💰 Separe pelo menos 10% da renda para poupança');
      buffer.writeln('• 📆 Faça um planejamento financeiro mensal');
      buffer.writeln('• 🛒 Evite compras por impulso - espere 24h antes de decidir');
      
      return QuickQuestionResult(
        questionId: 'savings_suggestion',
        response: buffer.toString(),
        hasData: false,
      );
    }

    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final now = DateTime.now();
    final daysPassed = now.day;
    
    // Analisar padrões de gastos
    final categorySpending = <String, double>{};
    for (final expense in expenses) {
      categorySpending[expense.categoryId] = (categorySpending[expense.categoryId] ?? 0) + expense.amount;
    }

    // 1. Sugestões baseadas em categorias excedidas
    final exceededGoals = goals.where((g) => g.isExceeded && g.isActive).toList();
    if (exceededGoals.isNotEmpty) {
      buffer.writeln('🚨 **Prioridade: Categorias Excedidas**\n');
      for (final goal in exceededGoals.take(2)) {
        final excess = goal.currentSpent - goal.monthlyLimit;
        buffer.writeln('• ${goal.categoryName}: Reduza R\$ ${excess.toStringAsFixed(2)} nos próximos dias');
        
        // Sugestão específica por categoria
        _addCategoryTip(buffer, goal.categoryId);
        buffer.writeln('');
      }
    }

    // 2. Sugestões baseadas nos maiores gastos
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.isNotEmpty) {
      final topCategory = sortedCategories.first;
      final category = _findCategoryById(topCategory.key, categories);
      final categoryName = category?.name ?? _formatCategoryName(topCategory.key);
      final percentage = (topCategory.value / totalSpent * 100).round();
      
      buffer.writeln('📊 **Seu maior gasto:** $categoryName ($percentage% do total)\n');
      
      if (percentage > 50) {
        buffer.writeln('⚠️ Esta categoria representa mais da metade dos seus gastos!\n');
      }
      
      buffer.writeln('**Dicas para economizar em $categoryName:**');
      _addDetailedCategoryTips(buffer, topCategory.key);
      buffer.writeln('');
    }

    // 3. Sugerir metas se não houver
    if (goals.isEmpty) {
      buffer.writeln('🎯 **Configure metas financeiras!**');
      buffer.writeln('Com metas, você recebe alertas antes de gastar demais.');
      buffer.writeln('→ Vá em Perfil > Metas Financeiras\n');
    }

    // 4. Meta de economia baseada nos gastos
    final potentialSavings = totalSpent * 0.15;
    buffer.writeln('💰 **Meta sugerida:**');
    buffer.writeln('Economize 15% e guarde ~R\$ ${potentialSavings.toStringAsFixed(2)}/mês\n');

    // 5. Média diária e projeção
    if (daysPassed >= 3) {
      final dailyAvg = totalSpent / daysPassed;
      buffer.writeln('📈 **Seu padrão atual:**');
      buffer.writeln('• Média: R\$ ${dailyAvg.toStringAsFixed(2)}/dia');
      buffer.writeln('• ${expenses.length} transações em $daysPassed dias');
      buffer.writeln('');
    }

    // 6. Dica do dia variada
    final tips = [
      'Espere 24h antes de fazer compras não planejadas acima de R\$ 50',
      'Cancele assinaturas que você não usa há mais de 30 dias',
      'Leve marmita pelo menos 3x por semana',
      'Use cashback e cupons de desconto sempre que possível',
      'Revise suas assinaturas de streaming - você usa todas?',
      'Compare preços online antes de comprar presencialmente',
      'Defina um "dia sem gastos" por semana',
      'Agrupe compras para economizar em frete',
    ];
    final randomTip = tips[DateTime.now().day % tips.length];
    
    buffer.writeln('✨ **Dica do dia:** $randomTip');

    return QuickQuestionResult(
      questionId: 'savings_suggestion',
      response: buffer.toString(),
      data: {
        'potential_savings': potentialSavings,
        'total_spent': totalSpent,
        'top_category': sortedCategories.isNotEmpty ? sortedCategories.first.key : null,
      },
    );
  }

  /// Adiciona dica específica para uma categoria
  void _addCategoryTip(StringBuffer buffer, String categoryId) {
    switch (categoryId) {
      case 'alimentacao':
        buffer.writeln('  → Prepare marmitas em casa, evite delivery');
        break;
      case 'transporte':
        buffer.writeln('  → Considere transporte público ou carona');
        break;
      case 'lazer':
        buffer.writeln('  → Opte por atividades gratuitas ou mais baratas');
        break;
      case 'compras':
        buffer.writeln('  → Avalie se realmente precisa antes de comprar');
        break;
      case 'saude':
        buffer.writeln('  → Pesquise genéricos e planos de saúde alternativos');
        break;
      default:
        buffer.writeln('  → Estabeleça um limite semanal para esta categoria');
    }
  }

  /// Adiciona dicas detalhadas para uma categoria
  void _addDetailedCategoryTips(StringBuffer buffer, String categoryId) {
    switch (categoryId) {
      case 'alimentacao':
        buffer.writeln('• Faça lista de compras antes de ir ao mercado');
        buffer.writeln('• Compare preços entre supermercados');
        buffer.writeln('• Evite fazer compras com fome');
        buffer.writeln('• Cozinhe em casa - economia de até 60%');
        break;
      case 'transporte':
        buffer.writeln('• Use apps de carona compartilhada');
        buffer.writeln('• Considere dias de home office');
        buffer.writeln('• Mantenha a manutenção do veículo em dia');
        buffer.writeln('• Compare preços de combustível na região');
        break;
      case 'lazer':
        buffer.writeln('• Busque eventos gratuitos na cidade');
        buffer.writeln('• Aproveite promoções de cinema e restaurantes');
        buffer.writeln('• Considere atividades ao ar livre');
        buffer.writeln('• Planeje passeios com antecedência');
        break;
      case 'compras':
        buffer.writeln('• Espere 24h antes de comprar itens não urgentes');
        buffer.writeln('• Compare preços em diferentes lojas');
        buffer.writeln('• Aproveite datas promocionais');
        buffer.writeln('• Questione: "Preciso ou quero?"');
        break;
      case 'saude':
        buffer.writeln('• Pesquise preços de medicamentos genéricos');
        buffer.writeln('• Use convênios e planos de desconto');
        buffer.writeln('• Previna com check-ups regulares');
        break;
      case 'educacao':
        buffer.writeln('• Busque cursos gratuitos online');
        buffer.writeln('• Aproveite bolsas e descontos');
        buffer.writeln('• Use a biblioteca pública');
        break;
      default:
        buffer.writeln('• Pesquise alternativas mais em conta');
        buffer.writeln('• Estabeleça um limite semanal');
        buffer.writeln('• Questione cada compra: "Preciso mesmo disso?"');
        buffer.writeln('• Compare preços antes de decidir');
    }
  }

  /// "Quanto posso gastar por dia?"
  Future<QuickQuestionResult> _handleDailyBudget() async {
    final expenses = _getMonthExpenses();
    final goals = await _getGoals();
    
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = daysInMonth - now.day;
    
    final buffer = StringBuffer();
    buffer.writeln('📅 **Orçamento Diário**\n');

    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalBudget = goals.fold(0.0, (sum, g) => sum + g.monthlyLimit);

    if (totalBudget == 0) {
      buffer.writeln('Você ainda não definiu metas financeiras.\n');
      buffer.writeln('📝 Configure suas metas em **Perfil > Metas Financeiras** para que eu possa calcular seu orçamento diário ideal!');
      
      if (expenses.isNotEmpty) {
        final avgDaily = totalSpent / now.day;
        buffer.writeln('\n📊 **Média atual:** R\$ ${avgDaily.toStringAsFixed(2)}/dia');
      }
      
      return QuickQuestionResult(
        questionId: 'daily_budget',
        response: buffer.toString(),
        hasData: false,
      );
    }

    final remaining = totalBudget - totalSpent;
    final dailyBudget = daysRemaining > 0 ? remaining / daysRemaining : 0;
    final idealDailyBudget = totalBudget / daysInMonth;
    final actualDailyAvg = now.day > 0 ? totalSpent / now.day : 0;

    // Comparação
    String statusEmoji;
    String statusText;
    
    if (dailyBudget <= 0) {
      statusEmoji = '🚨';
      statusText = 'Orçamento esgotado!';
    } else if (dailyBudget < idealDailyBudget * 0.5) {
      statusEmoji = '⚠️';
      statusText = 'Orçamento apertado';
    } else if (dailyBudget > idealDailyBudget) {
      statusEmoji = '✅';
      statusText = 'Confortável';
    } else {
      statusEmoji = '📊';
      statusText = 'Dentro do esperado';
    }

    buffer.writeln('$statusEmoji **Status:** $statusText\n');

    if (daysRemaining > 0 && dailyBudget > 0) {
      buffer.writeln('💰 **Você pode gastar até:**');
      buffer.writeln('🔹 R\$ ${dailyBudget.toStringAsFixed(2)} por dia');
      buffer.writeln('🔹 R\$ ${(dailyBudget * 7).toStringAsFixed(2)} por semana\n');
    }

    buffer.writeln('📊 **Comparativo:**');
    buffer.writeln('• Orçamento ideal: R\$ ${idealDailyBudget.toStringAsFixed(2)}/dia');
    buffer.writeln('• Sua média atual: R\$ ${actualDailyAvg.toStringAsFixed(2)}/dia');
    
    if (actualDailyAvg > idealDailyBudget) {
      final exceedPercentage = ((actualDailyAvg / idealDailyBudget - 1) * 100).round();
      buffer.writeln('\n⚠️ Você está gastando $exceedPercentage% acima do ideal');
    } else {
      final savedPercentage = ((1 - actualDailyAvg / idealDailyBudget) * 100).round();
      buffer.writeln('\n✅ Você está $savedPercentage% abaixo do limite diário');
    }

    buffer.writeln('\n📅 Restam **$daysRemaining dias** neste mês');
    buffer.writeln('💵 Saldo disponível: R\$ ${remaining.toStringAsFixed(2)}');

    return QuickQuestionResult(
      questionId: 'daily_budget',
      response: buffer.toString(),
      data: {
        'daily_budget': dailyBudget,
        'ideal_daily': idealDailyBudget,
        'actual_avg': actualDailyAvg,
        'days_remaining': daysRemaining,
      },
    );
  }

  /// "Quais metas estou cumprindo?"
  Future<QuickQuestionResult> _handleGoalsStatus() async {
    final goals = await _getGoals();
    
    final buffer = StringBuffer();
    buffer.writeln('🎯 **Status das Metas Financeiras**\n');

    if (goals.isEmpty) {
      buffer.writeln('Você ainda não definiu metas financeiras.\n\n');
      buffer.writeln('📝 Configure suas metas em **Perfil > Metas Financeiras** para acompanhar seu progresso!');
      return QuickQuestionResult(
        questionId: 'goals_status',
        response: buffer.toString(),
        hasData: false,
      );
    }

    final activeGoals = goals.where((g) => g.isActive).toList();
    
    // Separar por status
    final goodGoals = activeGoals.where((g) => g.status == FinancialGoalStatus.good).toList();
    final onTrackGoals = activeGoals.where((g) => g.status == FinancialGoalStatus.onTrack).toList();
    final warningGoals = activeGoals.where((g) => g.status == FinancialGoalStatus.warning).toList();
    final exceededGoals = activeGoals.where((g) => g.status == FinancialGoalStatus.exceeded).toList();

    // Resumo
    final totalGoals = activeGoals.length;
    final successfulGoals = goodGoals.length + onTrackGoals.length;
    final successRate = totalGoals > 0 ? (successfulGoals / totalGoals * 100).round() : 0;

    buffer.writeln('📊 **Resumo:** $successfulGoals de $totalGoals metas no caminho certo ($successRate%)\n');

    // Metas boas
    if (goodGoals.isNotEmpty) {
      buffer.writeln('✅ **Excelente (0-50% usado):**\n');
      for (final goal in goodGoals) {
        final usedPercentage = (goal.progressPercentage * 100).round();
        buffer.writeln('• ${goal.categoryName}: $usedPercentage% usado');
        buffer.writeln('  (R\$ ${goal.remainingAmount.toStringAsFixed(2)} restante)');
      }
      buffer.writeln('');
    }

    // Metas on track
    if (onTrackGoals.isNotEmpty) {
      buffer.writeln('👍 **No Caminho (50-80% usado):**\n');
      for (final goal in onTrackGoals) {
        final usedPercentage = (goal.progressPercentage * 100).round();
        buffer.writeln('• ${goal.categoryName}: $usedPercentage% usado');
      }
      buffer.writeln('');
    }

    // Metas em alerta
    if (warningGoals.isNotEmpty) {
      buffer.writeln('⚠️ **Atenção (80-100% usado):**\n');
      for (final goal in warningGoals) {
        final usedPercentage = (goal.progressPercentage * 100).round();
        buffer.writeln('• ${goal.categoryName}: $usedPercentage% usado');
        buffer.writeln('  (apenas R\$ ${goal.remainingAmount.toStringAsFixed(2)} restante)');
      }
      buffer.writeln('');
    }

    // Metas excedidas
    if (exceededGoals.isNotEmpty) {
      buffer.writeln('🚨 **Excedidas:**\n');
      for (final goal in exceededGoals) {
        final excess = goal.currentSpent - goal.monthlyLimit;
        final exceededPercentage = ((goal.progressPercentage - 1) * 100).round();
        buffer.writeln('• ${goal.categoryName}: +$exceededPercentage% acima');
        buffer.writeln('  (R\$ ${excess.toStringAsFixed(2)} excedido)');
      }
      buffer.writeln('');
    }

    // Dica final
    if (exceededGoals.isNotEmpty) {
      buffer.writeln('💡 **Dica:** Foque em reduzir gastos nas categorias excedidas nos próximos dias.');
    } else if (warningGoals.isNotEmpty) {
      buffer.writeln('💡 **Dica:** Monitore de perto as categorias em alerta para não exceder.');
    } else {
      buffer.writeln('🎉 **Parabéns!** Você está mantendo todas as metas sob controle!');
    }

    return QuickQuestionResult(
      questionId: 'goals_status',
      response: buffer.toString(),
      data: {
        'total_goals': totalGoals,
        'good_goals': goodGoals.length,
        'warning_goals': warningGoals.length,
        'exceeded_goals': exceededGoals.length,
        'success_rate': successRate,
      },
    );
  }

  // ============================================
  // HELPERS - BUSCA DE DADOS
  // ============================================

  /// Obtém despesas do mês atual
  List<Expense> _getMonthExpenses() {
    AppLogger.debug(FeatureTag.chat, '📊 [QuickQ] Buscando despesas do mês atual');
    
    try {
      final isRegistered = Get.isRegistered<ExpenseController>();
      AppLogger.debug(FeatureTag.chat, '🔍 [QuickQ] ExpenseController registrado: $isRegistered');
      
      if (isRegistered) {
        final controller = Get.find<ExpenseController>();
        final now = DateTime.now();
        final allExpenses = controller.expenses;
        
        AppLogger.debug(FeatureTag.chat, '📋 [QuickQ] Total de despesas no controller: ${allExpenses.length}');
        
        final monthExpenses = allExpenses.where((e) => 
          e.date.year == now.year && 
          e.date.month == now.month
        ).toList();
        
        final totalAmount = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);
        
        AppLogger.info(FeatureTag.chat, '✅ [QuickQ] Despesas do mês carregadas', data: {
          'month': now.month,
          'year': now.year,
          'count': monthExpenses.length,
          'total_amount': totalAmount,
        });
        
        return monthExpenses;
      }
    } catch (e, stackTrace) {
      AppLogger.error(FeatureTag.chat, '❌ [QuickQ] Erro ao obter despesas', error: e, data: {
        'stack_trace': stackTrace.toString().substring(0, 300),
      });
    }
    
    AppLogger.warning(FeatureTag.chat, '⚠️ [QuickQ] Retornando lista vazia de despesas');
    return [];
  }

  /// Obtém categorias disponíveis
  List<ExpenseCategory> _getCategories() {
    AppLogger.debug(FeatureTag.chat, '🏷️ [QuickQ] Buscando categorias');
    
    try {
      final isRegistered = Get.isRegistered<CategoryController>();
      AppLogger.debug(FeatureTag.chat, '🔍 [QuickQ] CategoryController registrado: $isRegistered');
      
      if (isRegistered) {
        final controller = Get.find<CategoryController>();
        final categories = controller.categories;
        
        AppLogger.info(FeatureTag.chat, '✅ [QuickQ] Categorias carregadas', data: {
          'count': categories.length,
          'names': categories.map((c) => c.name).toList(),
        });
        
        return categories;
      }
    } catch (e, stackTrace) {
      AppLogger.error(FeatureTag.chat, '❌ [QuickQ] Erro ao obter categorias', error: e, data: {
        'stack_trace': stackTrace.toString().substring(0, 300),
      });
    }
    
    AppLogger.warning(FeatureTag.chat, '⚠️ [QuickQ] Usando categorias padrão');
    return ExpenseCategory.defaultCategories;
  }

  /// Obtém metas financeiras
  Future<List<FinancialGoal>> _getGoals() async {
    AppLogger.debug(FeatureTag.chat, '🎯 [QuickQ] Buscando metas financeiras');
    
    try {
      final isRegistered = Get.isRegistered<FinancialGoalsController>();
      AppLogger.debug(FeatureTag.chat, '🔍 [QuickQ] FinancialGoalsController registrado: $isRegistered');
      
      if (isRegistered) {
        final controller = Get.find<FinancialGoalsController>();
        
        AppLogger.debug(FeatureTag.chat, '⏳ [QuickQ] Carregando metas do mês atual...');
        final goals = await controller.loadCurrentMonthGoals();
        
        final activeGoals = goals.where((g) => g.isActive).toList();
        final exceededGoals = goals.where((g) => g.isExceeded).toList();
        final warningGoals = goals.where((g) => g.status == FinancialGoalStatus.warning).toList();
        
        AppLogger.info(FeatureTag.chat, '✅ [QuickQ] Metas carregadas', data: {
          'total': goals.length,
          'active': activeGoals.length,
          'exceeded': exceededGoals.length,
          'warning': warningGoals.length,
          'categories': goals.map((g) => g.categoryName).toList(),
        });
        
        return goals;
      }
    } catch (e, stackTrace) {
      AppLogger.error(FeatureTag.chat, '❌ [QuickQ] Erro ao obter metas', error: e, data: {
        'stack_trace': stackTrace.toString().substring(0, 300),
      });
    }
    
    AppLogger.warning(FeatureTag.chat, '⚠️ [QuickQ] Retornando lista vazia de metas');
    return [];
  }

  /// Retorna nome do mês
  String _getMonthName(int month) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return months[month - 1];
  }

  /// Retorna perguntas por categoria
  static List<QuickQuestion> getQuestionsByCategory(QuickQuestionCategory category) {
    return availableQuestions.where((q) => q.category == category).toList();
  }

  /// Retorna uma pergunta pelo ID
  static QuickQuestion? getQuestionById(String id) {
    try {
      return availableQuestions.firstWhere((q) => q.id == id);
    } catch (e) {
      return null;
    }
  }
}

