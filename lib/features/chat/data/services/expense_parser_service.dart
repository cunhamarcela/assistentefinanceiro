import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../core/services/openai_service.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/entities/category.dart';
import '../../../expenses/domain/entities/credit_card.dart';

/// Resultado do parsing de uma mensagem
class ExpenseParseResult {
  final bool isExpenseRequest;
  final double? amount;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final DateTime? date;
  final String? notes;
  final PaymentType? paymentType;
  final double confidence;
  final String? rawParsedData;
  final String? errorMessage;
  
  // Campos para parcelamento e cartão
  final bool isInstallment;
  final int? installments;
  final String? creditCardId;
  final String? creditCardName;

  const ExpenseParseResult({
    required this.isExpenseRequest,
    this.amount,
    this.description,
    this.categoryId,
    this.categoryName,
    this.date,
    this.notes,
    this.paymentType,
    this.confidence = 0.0,
    this.rawParsedData,
    this.errorMessage,
    this.isInstallment = false,
    this.installments,
    this.creditCardId,
    this.creditCardName,
  });

  /// Verifica se o parsing foi bem-sucedido
  bool get isValid => isExpenseRequest && amount != null && amount! > 0;

  /// Verifica se todos os campos obrigatórios estão presentes
  bool get hasRequiredFields => amount != null && description != null;

  /// Verifica se tem categoria identificada
  bool get hasCategory => categoryId != null || categoryName != null;

  /// Verifica se a confiança é alta (>= 80%)
  bool get hasHighConfidence => confidence >= 0.8;

  /// Verifica se precisa de confirmação do usuário
  bool get needsConfirmation => isValid && confidence < 0.9;

  /// Formata o valor para exibição
  String get formattedAmount => amount != null 
      ? 'R\$ ${amount!.toStringAsFixed(2)}'
      : 'Valor não identificado';

  /// Gera mensagem de resumo do parsing
  String get summaryMessage {
    if (!isExpenseRequest) {
      return 'Não foi identificado um pedido de registro de gasto.';
    }
    if (!isValid) {
      return 'Não foi possível identificar os dados do gasto. ${errorMessage ?? ''}';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('📝 Gasto identificado:');
    buffer.writeln('• Valor: $formattedAmount');
    if (description != null) buffer.writeln('• Descrição: $description');
    if (categoryName != null) buffer.writeln('• Categoria: $categoryName');
    if (date != null) {
      final dateStr = '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}';
      buffer.writeln('• Data: $dateStr');
    }
    if (paymentType != null) buffer.writeln('• Forma de pagamento: ${_paymentTypeName(paymentType!)}');
    if (isInstallment && installments != null) {
      buffer.writeln('• Parcelamento: ${installments}x');
    }
    if (creditCardName != null) buffer.writeln('• Cartão: $creditCardName');
    buffer.writeln('\nConfiança: ${(confidence * 100).toStringAsFixed(0)}%');
    
    return buffer.toString();
  }

  String _paymentTypeName(PaymentType type) {
    switch (type) {
      case PaymentType.cash: return 'Dinheiro';
      case PaymentType.debit: return 'Débito';
      case PaymentType.credit: return 'Crédito';
      case PaymentType.pix: return 'PIX';
      case PaymentType.other: return 'Outro';
    }
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() => {
    'isExpenseRequest': isExpenseRequest,
    'amount': amount,
    'description': description,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'date': date?.toIso8601String(),
    'notes': notes,
    'paymentType': paymentType?.name,
    'confidence': confidence,
    'rawParsedData': rawParsedData,
    'errorMessage': errorMessage,
    'isInstallment': isInstallment,
    'installments': installments,
    'creditCardId': creditCardId,
    'creditCardName': creditCardName,
  };

  factory ExpenseParseResult.empty() => const ExpenseParseResult(
    isExpenseRequest: false,
    confidence: 0.0,
  );

  factory ExpenseParseResult.error(String message) => ExpenseParseResult(
    isExpenseRequest: false,
    confidence: 0.0,
    errorMessage: message,
  );
  
  /// Gera mensagem de erro amigável baseada no que está faltando
  String getValidationMessage() {
    final missing = <String>[];
    final hints = <String>[];
    
    if (amount == null || amount! <= 0) {
      missing.add('💰 **Valor** não identificado');
      hints.add('"Gastei **50 reais**..."');
    }
    
    if (description == null || description!.isEmpty) {
      missing.add('📝 **Descrição** não identificada');
      hints.add('"...no **mercado**" ou "...com **roupa**"');
    }
    
    if (missing.isEmpty) return '';
    
    final buffer = StringBuffer();
    buffer.writeln('⚠️ **Informações faltando:**\n');
    for (final item in missing) {
      buffer.writeln('• $item');
    }
    buffer.writeln('\n💡 **Como informar:**');
    for (final hint in hints) {
      buffer.writeln('• $hint');
    }
    
    return buffer.toString();
  }
}

/// Serviço para parsing de texto natural para criar despesas
class ExpenseParserService extends GetxService {
  late final OpenAIService _openAIService;
  
  // Cache de categorias para matching local
  List<ExpenseCategory> _availableCategories = [];
  
  // Cache de cartões de crédito para matching
  List<CreditCard> _availableCreditCards = [];

  @override
  void onInit() {
    super.onInit();
    _openAIService = Get.find<OpenAIService>();
  }

  /// Atualiza a lista de categorias disponíveis
  void updateCategories(List<ExpenseCategory> categories) {
    _availableCategories = categories;
  }
  
  /// Atualiza a lista de cartões de crédito disponíveis
  void updateCreditCards(List<CreditCard> cards) {
    _availableCreditCards = cards;
  }

  /// Verifica se uma mensagem parece ser um pedido de registro de gasto
  bool looksLikeExpenseRequest(String message) {
    final lowerMessage = message.toLowerCase();
    final keywords = [
      'gastei', 'comprei', 'paguei', 'registrar', 'adicionar',
      'anotar', 'lançar', 'gasto', 'despesa', 'custou', 'foi', 'deu',
      'saiu', 'custa', 'pago', 'gastar', 'comprar', 'parcelei', 'parcelado',
    ];
    return keywords.any((kw) => lowerMessage.contains(kw));
  }

  /// Faz o parsing de uma mensagem para extrair dados de despesa (retorna ParsedExpense)
  Future<ParsedExpense?> parseExpenseFromText(
    String text, {
    required List<ExpenseCategory> availableCategories,
  }) async {
    // Atualiza categorias
    _availableCategories = availableCategories;
    
    // Faz o parsing
    final result = await parseMessage(text);
    
    if (!result.isExpenseRequest || !result.isValid) {
      return null;
    }
    
    return ParsedExpense.fromParseResult(result, text);
  }

  /// Faz o parsing de uma mensagem para extrair dados de despesa
  Future<ExpenseParseResult> parseMessage(String message) async {
    try {
      // Primeiro, tenta parsing local (mais rápido)
      final localResult = _parseLocally(message);
      if (localResult.isValid && localResult.hasHighConfidence) {
        return localResult;
      }

      // Se não conseguiu localmente ou confiança baixa, usa IA
      final aiResult = await _parseWithAI(message);
      
      // Combina resultados se necessário
      if (aiResult.isValid) {
        return aiResult;
      }
      
      // Retorna o melhor resultado
      return localResult.confidence > aiResult.confidence ? localResult : aiResult;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro no parsing: $e');
      }
      return ExpenseParseResult.error(e.toString());
    }
  }

  /// Parsing local usando regex e heurísticas
  ExpenseParseResult _parseLocally(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Verifica se é um pedido de registro de gasto
    final expenseKeywords = [
      'gastei', 'comprei', 'paguei', 'registrar', 'adicionar',
      'anotar', 'lançar', 'gasto de', 'despesa de', 'gastou',
      'custou', 'foi', 'deu', 'saiu', 'gasto', 'despesa',
    ];
    
    final isExpenseRequest = expenseKeywords.any((kw) => lowerMessage.contains(kw));
    
    if (!isExpenseRequest) {
      return ExpenseParseResult.empty();
    }

    // Extrai valor monetário
    final amount = _extractAmount(message);
    if (amount == null) {
      return ExpenseParseResult(
        isExpenseRequest: true,
        confidence: 0.3,
        errorMessage: '💰 **Não consegui identificar o valor.**\n\n'
            'Por favor, inclua o valor da compra. Exemplos:\n'
            '• "Gastei **50 reais** no mercado"\n'
            '• "Comprei uma blusa por **R\$ 89,90**"\n'
            '• "Paguei **150** no restaurante"',
      );
    }

    // Extrai descrição
    final description = _extractDescription(message);
    
    // Identifica categoria
    final categoryMatch = _matchCategory(message);
    
    // Identifica forma de pagamento
    var paymentType = _extractPaymentType(message);
    
    // Identifica data
    final date = _extractDate(message);
    
    // Extrai informações de parcelamento
    final installmentInfo = _extractInstallmentInfo(message);
    // isInstallment é true se: tem número de parcelas (>1) OU se foi detectado parcelamento (-1)
    final isInstallment = installmentInfo != null && (installmentInfo > 1 || installmentInfo == -1);
    final needsInstallmentNumber = installmentInfo == -1;
    // Parcelas reais (null se não especificado)
    final actualInstallments = installmentInfo != null && installmentInfo > 1 ? installmentInfo : null;
    
    // Extrai cartão de crédito
    final creditCardMatch = _extractCreditCard(message);
    
    // Se é parcelado ou menciona cartão, força tipo de pagamento como crédito
    if (isInstallment || creditCardMatch != null) {
      paymentType = PaymentType.credit;
    }
    
    // Calcula confiança baseada em quantos campos foram identificados
    double confidence = 0.7; // Base (0.5 + 0.2 pelo valor já identificado acima)
    if (description != null && description.isNotEmpty) confidence += 0.15;
    if (categoryMatch != null) confidence += 0.1;
    if (paymentType != null) confidence += 0.05;
    if (isInstallment && !needsInstallmentNumber) confidence += 0.05;
    if (creditCardMatch != null) confidence += 0.05;
    // Se detectou parcelamento mas não o número, reduz confiança
    if (needsInstallmentNumber) confidence -= 0.1;
    
    return ExpenseParseResult(
      isExpenseRequest: true,
      amount: amount,
      description: description ?? _generateDescription(message, categoryMatch),
      categoryId: categoryMatch?.id,
      categoryName: categoryMatch?.name,
      date: date ?? DateTime.now(),
      paymentType: paymentType,
      confidence: confidence.clamp(0.0, 1.0),
      isInstallment: isInstallment,
      installments: actualInstallments,
      creditCardId: creditCardMatch?.id,
      creditCardName: creditCardMatch?.name,
      rawParsedData: jsonEncode({
        'method': 'local',
        'originalMessage': message,
        'isInstallment': isInstallment,
        'installments': actualInstallments,
        'needsInstallmentNumber': needsInstallmentNumber,
        'creditCard': creditCardMatch?.name,
      }),
    );
  }

  /// Parsing usando OpenAI
  Future<ExpenseParseResult> _parseWithAI(String message) async {
    try {
      final isConfigured = await _openAIService.isConfigured();
      if (!isConfigured) {
        return ExpenseParseResult(
          isExpenseRequest: false,
          confidence: 0.0,
          errorMessage: 'Serviço de IA não configurado',
        );
      }

      final categoryNames = _availableCategories.map((c) => c.name).toList();
      
      final cardNames = _availableCreditCards.map((c) => c.name).toList();
      
      final prompt = '''
Analise a mensagem abaixo e extraia informações de despesa/gasto financeiro.

Mensagem: "$message"

Categorias disponíveis: ${categoryNames.join(', ')}
Cartões cadastrados: ${cardNames.isNotEmpty ? cardNames.join(', ') : 'Nenhum cadastrado'}

Responda APENAS em JSON válido no formato:
{
  "isExpense": true/false,
  "amount": número (apenas o valor numérico total, sem R\$),
  "description": "descrição curta do gasto",
  "category": "nome da categoria mais apropriada da lista",
  "paymentType": "cash" ou "debit" ou "credit" ou "pix" ou "other",
  "date": "YYYY-MM-DD" (se mencionado, senão null),
  "isInstallment": true/false (se é compra parcelada),
  "installments": número de parcelas (se parcelado, ex: 10 para 10x),
  "creditCardName": "nome do cartão" (se mencionado),
  "confidence": número de 0 a 1
}

REGRAS IMPORTANTES:
- Se mencionar "parcelado", "em Xx", "X vezes", "X parcelas" → isInstallment: true
- Se mencionar "à vista" ou não mencionar parcelamento → isInstallment: false
- O "amount" deve ser o valor TOTAL da compra, não da parcela
- Se for parcelado, o paymentType deve ser "credit"
- Detecte nomes de bancos/cartões: Nubank, Inter, Itaú, Bradesco, C6, etc.

Se não for um pedido de registro de gasto, retorne:
{"isExpense": false, "confidence": 0}
''';

      final response = await _openAIService.generateChatResponse(
        conversationHistory: [
          {'role': 'user', 'content': prompt},
        ],
        userProfile: null,
        context: {'task': 'expense_parsing'},
      );

      // Extrai JSON da resposta
      final jsonMatch = RegExp(r'\{[^{}]*\}').firstMatch(response);
      if (jsonMatch == null) {
        return ExpenseParseResult(
          isExpenseRequest: false,
          confidence: 0.3,
          errorMessage: 'Não foi possível processar a resposta da IA',
        );
      }

      final parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      
      final isExpense = parsed['isExpense'] as bool? ?? false;
      if (!isExpense) {
        return ExpenseParseResult.empty();
      }

      final categoryName = parsed['category'] as String?;
      final matchedCategory = categoryName != null
          ? _availableCategories.firstWhereOrNull(
              (c) => c.name.toLowerCase() == categoryName.toLowerCase())
          : null;

      DateTime? parsedDate;
      if (parsed['date'] != null && parsed['date'] != 'null') {
        try {
          parsedDate = DateTime.parse(parsed['date'] as String);
        } catch (_) {
          parsedDate = DateTime.now();
        }
      }

      PaymentType? paymentType;
      final paymentStr = parsed['paymentType'] as String?;
      if (paymentStr != null) {
        paymentType = PaymentType.values.firstWhereOrNull(
          (p) => p.name == paymentStr,
        );
      }
      
      // Extrai informações de parcelamento
      final isInstallment = parsed['isInstallment'] as bool? ?? false;
      final installments = (parsed['installments'] as num?)?.toInt();
      
      // Se é parcelado, força tipo de pagamento como crédito
      if (isInstallment) {
        paymentType = PaymentType.credit;
      }
      
      // Extrai cartão de crédito
      final creditCardName = parsed['creditCardName'] as String?;
      CreditCard? matchedCard;
      if (creditCardName != null) {
        matchedCard = _availableCreditCards.firstWhereOrNull(
          (c) => c.name.toLowerCase().contains(creditCardName.toLowerCase()) ||
                 creditCardName.toLowerCase().contains(c.name.toLowerCase())
        );
      }

      return ExpenseParseResult(
        isExpenseRequest: true,
        amount: (parsed['amount'] as num?)?.toDouble(),
        description: parsed['description'] as String?,
        categoryId: matchedCategory?.id,
        categoryName: categoryName,
        date: parsedDate ?? DateTime.now(),
        paymentType: paymentType,
        confidence: (parsed['confidence'] as num?)?.toDouble() ?? 0.7,
        isInstallment: isInstallment,
        installments: installments,
        creditCardId: matchedCard?.id,
        creditCardName: creditCardName ?? matchedCard?.name,
        rawParsedData: jsonEncode({
          'method': 'ai',
          'originalMessage': message,
          'aiResponse': parsed,
        }),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro no parsing com IA: $e');
      }
      return ExpenseParseResult.error('Erro ao processar com IA: $e');
    }
  }

  /// Extrai valor monetário da mensagem
  double? _extractAmount(String message) {
    // Padrões de valor: R$ 50, R$50, 50 reais, 50,00, 50.00, etc.
    final patterns = [
      RegExp(r'R\$\s*(\d+[.,]?\d*)', caseSensitive: false),
      RegExp(r'(\d+[.,]?\d*)\s*(?:reais|reias)', caseSensitive: false),
      RegExp(r'(\d+[.,]\d{2})'),
      RegExp(r'(\d+)\s*(?:conto|contos|real|reais|reias|R\$)', caseSensitive: false),
      RegExp(r'(?:gastei|comprei|paguei|custou|foi|deu|saiu)\s*(?:R\$)?\s*(\d+[.,]?\d*)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(message);
      if (match != null && match.group(1) != null) {
        final valueStr = match.group(1)!.replaceAll(',', '.');
        final value = double.tryParse(valueStr);
        if (value != null && value > 0) {
          return value;
        }
      }
    }
    
    return null;
  }

  /// Extrai descrição do gasto
  String? _extractDescription(String message) {
    // Remove padrões de valor
    var cleaned = message
        .replaceAll(RegExp(r'R\$\s*\d+[.,]?\d*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\d+[.,]?\d*\s*(?:reais|reias)', caseSensitive: false), '')
        .replaceAll(RegExp(r'gastei|comprei|paguei|registrar|adicionar|anotar|lançar', caseSensitive: false), '')
        .replaceAll(RegExp(r'gasto de|despesa de', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(no|na|em|de|com|para)\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    if (cleaned.length < 3) return null;
    
    // Capitaliza primeira letra
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  /// Gera descrição baseada na mensagem e categoria
  String _generateDescription(String message, ExpenseCategory? category) {
    if (category != null) {
      return 'Gasto em ${category.name}';
    }
    
    // Extrai substantivos principais
    final words = message.split(' ')
        .where((w) => w.length > 3)
        .take(3)
        .join(' ');
    
    return words.isNotEmpty ? words : 'Gasto registrado via chat';
  }

  /// Faz matching de categoria baseado em keywords
  ExpenseCategory? _matchCategory(String message) {
    final lowerMessage = message.toLowerCase();
    
    ExpenseCategory? bestMatch;
    int bestScore = 0;
    
    for (final category in _availableCategories) {
      int score = 0;
      
      // Verifica nome da categoria
      if (lowerMessage.contains(category.name.toLowerCase())) {
        score += 10;
      }
      
      // Verifica keywords da categoria
      for (final keyword in category.keywords) {
        if (lowerMessage.contains(keyword.toLowerCase())) {
          score += 5;
        }
      }
      
      if (score > bestScore) {
        bestScore = score;
        bestMatch = category;
      }
    }
    
    return bestScore >= 5 ? bestMatch : null;
  }

  /// Extrai forma de pagamento da mensagem
  PaymentType? _extractPaymentType(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('pix')) return PaymentType.pix;
    if (lowerMessage.contains('crédito') || lowerMessage.contains('credito')) return PaymentType.credit;
    if (lowerMessage.contains('débito') || lowerMessage.contains('debito')) return PaymentType.debit;
    if (lowerMessage.contains('dinheiro') || lowerMessage.contains('espécie')) return PaymentType.cash;
    
    return null;
  }

  /// Extrai data da mensagem
  DateTime? _extractDate(String message) {
    final lowerMessage = message.toLowerCase();
    final now = DateTime.now();
    
    // Palavras-chave relativas
    if (lowerMessage.contains('hoje')) return now;
    if (lowerMessage.contains('ontem')) return now.subtract(const Duration(days: 1));
    if (lowerMessage.contains('anteontem')) return now.subtract(const Duration(days: 2));
    
    // Tenta encontrar data no formato DD/MM
    final datePattern = RegExp(r'(\d{1,2})[/\-](\d{1,2})(?:[/\-](\d{2,4}))?');
    final match = datePattern.firstMatch(message);
    if (match != null) {
      final day = int.tryParse(match.group(1)!) ?? 1;
      final month = int.tryParse(match.group(2)!) ?? now.month;
      var year = match.group(3) != null 
          ? int.tryParse(match.group(3)!) ?? now.year
          : now.year;
      if (year < 100) year += 2000;
      
      try {
        return DateTime(year, month, day);
      } catch (_) {
        return null;
      }
    }
    
    return null;
  }

  /// Extrai informações de parcelamento da mensagem
  /// Retorna: número de parcelas, -1 se parcelado mas sem número, null se à vista/não mencionado
  int? _extractInstallmentInfo(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Verifica se é à vista (não parcelado)
    final cashPatterns = ['à vista', 'a vista', 'avista', 'sem parcela'];
    if (cashPatterns.any((p) => lowerMessage.contains(p))) {
      return 1;
    }
    
    // Padrões para identificar parcelamento com número específico
    // "parcelado em 10x", "em 10x", "10x", "10 vezes", "10 parcelas"
    final patterns = [
      // "parcelado em 10x" ou "parcelado em 10 vezes"
      RegExp(r'parcelad[oa]?\s*(?:em)?\s*(\d+)\s*(?:x|vezes|parcelas?)', caseSensitive: false),
      // "em 10x" ou "10x"
      RegExp(r'(?:em\s+)?(\d+)\s*x(?:\s|$|,|\.)', caseSensitive: false),
      // "10 vezes" ou "10 parcelas"
      RegExp(r'(\d+)\s*(?:vezes|parcelas?)', caseSensitive: false),
      // "de 10x"
      RegExp(r'de\s+(\d+)\s*x', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(lowerMessage);
      if (match != null && match.group(1) != null) {
        final installments = int.tryParse(match.group(1)!);
        if (installments != null && installments >= 2 && installments <= 48) {
          return installments;
        }
      }
    }
    
    // Verifica menções genéricas de parcelamento sem número específico
    final installmentKeywords = ['parcelado', 'parcelei', 'parcelada', 'parcela'];
    if (installmentKeywords.any((kw) => lowerMessage.contains(kw))) {
      // Parcelado mas sem número específico - retorna -1 para indicar que precisa perguntar
      return -1;
    }
    
    return null;
  }
  
  /// Verifica se o parcelamento foi detectado mas sem número de parcelas
  bool _isInstallmentWithoutNumber(int? installmentInfo) {
    return installmentInfo == -1;
  }
  
  /// Extrai cartão de crédito da mensagem
  /// Retorna o cartão correspondente ou null se não encontrado
  CreditCard? _extractCreditCard(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Primeiro, tenta encontrar pelos cartões cadastrados do usuário
    for (final card in _availableCreditCards) {
      if (lowerMessage.contains(card.name.toLowerCase())) {
        return card;
      }
      // Tenta pelos últimos 4 dígitos
      if (lowerMessage.contains(card.lastFourDigits)) {
        return card;
      }
    }
    
    // Padrões para extrair nome do cartão mencionado
    final patterns = [
      // "no cartão X", "no X", "cartão X"
      RegExp(r'(?:no\s+)?cart[aã]o\s+(?:de\s+cr[eé]dito\s+)?(?:do\s+)?(\w+)', caseSensitive: false),
      // "no nubank", "no inter", "no c6", etc.
      RegExp(r'no\s+(nubank|inter|itau|itaú|bradesco|santander|bb|banco\s*do\s*brasil|caixa|c6|picpay|will|original|pan|next|neon|xp|btg|safra)', caseSensitive: false),
      // "pelo nubank", "pelo inter"
      RegExp(r'pel[oa]\s+(nubank|inter|itau|itaú|bradesco|santander|bb|banco\s*do\s*brasil|caixa|c6|picpay|will|original|pan|next|neon|xp|btg|safra)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(lowerMessage);
      if (match != null && match.group(1) != null) {
        final cardName = _normalizeCardName(match.group(1)!);
        
        // Procura o cartão cadastrado com nome similar
        for (final card in _availableCreditCards) {
          if (card.name.toLowerCase().contains(cardName.toLowerCase()) ||
              cardName.toLowerCase().contains(card.name.toLowerCase())) {
            return card;
          }
        }
        
        // Se não achou cartão cadastrado, retorna um cartão "virtual" com o nome encontrado
        // Isso permite ao sistema perguntar qual cartão usar
        return CreditCard(
          id: 'temp_${cardName.hashCode}',
          name: cardName,
          lastFourDigits: '0000',
          closingDay: 1,
          dueDay: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    }
    
    return null;
  }
  
  /// Normaliza o nome do cartão
  String _normalizeCardName(String name) {
    final normalized = name.trim();
    
    // Mapeamento de nomes comuns
    final cardNameMap = {
      'bb': 'Banco do Brasil',
      'banco do brasil': 'Banco do Brasil',
      'itau': 'Itaú',
      'itaú': 'Itaú',
      'bradesco': 'Bradesco',
      'santander': 'Santander',
      'caixa': 'Caixa',
      'nubank': 'Nubank',
      'inter': 'Inter',
      'c6': 'C6 Bank',
      'picpay': 'PicPay',
      'will': 'Will Bank',
      'original': 'Banco Original',
      'pan': 'Banco Pan',
      'next': 'Next',
      'neon': 'Neon',
      'xp': 'XP',
      'btg': 'BTG',
      'safra': 'Safra',
    };
    
    return cardNameMap[normalized.toLowerCase()] ?? 
           (normalized[0].toUpperCase() + normalized.substring(1).toLowerCase());
  }
}

/// Classe que representa uma despesa parseada (para uso no ChatController)
class ParsedExpense {
  final double? amount;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final DateTime? date;
  final PaymentType? paymentType;
  final double confidence;
  final String? originalText;
  final String? rawParsedData;
  
  // Campos para parcelamento e cartão
  final bool isInstallment;
  final int? installments;
  final String? creditCardId;
  final String? creditCardName;

  const ParsedExpense({
    this.amount,
    this.description,
    this.categoryId,
    this.categoryName,
    this.date,
    this.paymentType,
    this.confidence = 0.0,
    this.originalText,
    this.rawParsedData,
    this.isInstallment = false,
    this.installments,
    this.creditCardId,
    this.creditCardName,
  });

  /// Verifica se tem os dados mínimos para criar uma despesa
  bool get hasMinimumData => amount != null && amount! > 0 && description != null;

  /// Mensagem de confirmação para o usuário
  String get confirmationMessage {
    final buffer = StringBuffer();
    buffer.writeln('📝 **Despesa identificada:**\n');
    buffer.writeln('💰 Valor: R\$ ${amount?.toStringAsFixed(2) ?? '---'}');
    if (description != null) buffer.writeln('📌 Descrição: $description');
    if (categoryName != null) buffer.writeln('🏷️ Categoria: $categoryName');
    if (date != null) {
      final dateStr = '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}';
      buffer.writeln('📅 Data: $dateStr');
    }
    if (isInstallment && installments != null && amount != null) {
      buffer.writeln('🔄 Parcelamento: ${installments}x de R\$ ${(amount! / installments!).toStringAsFixed(2)}');
    } else if (isInstallment && installments == null) {
      buffer.writeln('🔄 Parcelamento: **Em quantas vezes?** (ex: "em 10x")');
    } else if (paymentType != null) {
      buffer.writeln('💳 Pagamento: ${_paymentTypeName(paymentType!)}');
    }
    if (creditCardName != null) {
      buffer.writeln('💳 Cartão: $creditCardName');
    }
    buffer.writeln('\n🎯 Confiança: ${(confidence * 100).toStringAsFixed(0)}%');
    return buffer.toString();
  }
  
  /// Verifica se precisa perguntar o número de parcelas
  bool get needsInstallmentNumber => isInstallment && installments == null;

  String _paymentTypeName(PaymentType type) {
    switch (type) {
      case PaymentType.cash: return 'Dinheiro';
      case PaymentType.debit: return 'Débito';
      case PaymentType.credit: return 'Crédito';
      case PaymentType.pix: return 'PIX';
      case PaymentType.other: return 'Outro';
    }
  }

  /// Converte para JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Converte para JSON
  Map<String, dynamic> toJson() => {
    'amount': amount,
    'description': description,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'date': date?.toIso8601String(),
    'paymentType': paymentType?.name,
    'confidence': confidence,
    'originalText': originalText,
    'isInstallment': isInstallment,
    'installments': installments,
    'creditCardId': creditCardId,
    'creditCardName': creditCardName,
  };

  /// Cria a partir de ExpenseParseResult
  factory ParsedExpense.fromParseResult(ExpenseParseResult result, String originalText) {
    return ParsedExpense(
      amount: result.amount,
      description: result.description,
      categoryId: result.categoryId,
      categoryName: result.categoryName,
      date: result.date,
      paymentType: result.paymentType,
      confidence: result.confidence,
      originalText: originalText,
      rawParsedData: result.rawParsedData,
      isInstallment: result.isInstallment,
      installments: result.installments,
      creditCardId: result.creditCardId,
      creditCardName: result.creditCardName,
    );
  }
}

