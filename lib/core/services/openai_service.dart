import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../storage/secure_storage.dart';
import '../../features/onboarding/data/models/onboarding_question_model.dart';
import 'financial_context_service.dart';

class OpenAIService extends GetxService {
  late final Dio _dio;
  late final SecureStorage _secureStorage;
  
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _apiKeyKey = 'openai_api_key';
  
  @override
  void onInit() {
    super.onInit();
    _secureStorage = Get.find<SecureStorage>();
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Interceptor para adicionar API key automaticamente
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final apiKey = await _getApiKey();
        if (apiKey != null) {
          options.headers['Authorization'] = 'Bearer $apiKey';
        }
        handler.next(options);
      },
    ));

    // Interceptor para logs (apenas em debug)
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('🤖 OpenAI API: $obj'),
      ));
    }
  }

  /// Configura a API key da OpenAI
  Future<void> setApiKey(String apiKey) async {
    await _secureStorage.write(_apiKeyKey, apiKey);
  }

  /// Recupera a API key armazenada
  Future<String?> _getApiKey() async {
    return await _secureStorage.read(_apiKeyKey);
  }

  /// Verifica se a API key está configurada
  Future<bool> isConfigured() async {
    final apiKey = await _getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Gera insights financeiros personalizados usando GPT
  Future<String> generateFinancialInsight({
    required OnboardingProfileModel userProfile,
    required Map<String, dynamic> expenseData,
    String? specificQuestion,
  }) async {
    try {
      if (!await isConfigured()) {
        throw Exception('API key da OpenAI não configurada');
      }

      final prompt = _buildFinancialInsightPrompt(
        userProfile: userProfile,
        expenseData: expenseData,
        specificQuestion: specificQuestion,
      );

      final response = await _dio.post('/chat/completions', data: {
        'model': 'gpt-4o-mini', // Modelo mais econômico
        'messages': [
          {
            'role': 'system',
            'content': _getSystemPrompt(),
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'max_tokens': 500,
        'temperature': 0.7,
        'top_p': 0.9,
      });

      final content = response.data['choices'][0]['message']['content'] as String;
      return content.trim();
    } catch (e) {
      print('❌ Erro ao gerar insight com OpenAI: $e');
      
      // Fallback para insights locais em caso de erro
      return _generateFallbackInsight(userProfile, expenseData);
    }
  }

  /// Responde perguntas do chat usando GPT
  /// Agora inclui contexto financeiro completo (metas, gastos, alertas)
  Future<String> generateChatResponse({
    required List<Map<String, String>> conversationHistory,
    required OnboardingProfileModel? userProfile,
    Map<String, dynamic>? context,
  }) async {
    try {
      if (!await isConfigured()) {
        throw Exception('API key da OpenAI não configurada');
      }

      // Obter contexto financeiro completo para personalização
      FinancialContext? financialContext;
      try {
        if (Get.isRegistered<FinancialContextService>()) {
          financialContext = await Get.find<FinancialContextService>().getContext();
        }
      } catch (e) {
        print('⚠️ Não foi possível obter contexto financeiro: $e');
      }

      final messages = <Map<String, String>>[
        {
          'role': 'system',
          'content': _getChatSystemPromptWithContext(userProfile, financialContext),
        },
        ...conversationHistory,
      ];

      final response = await _dio.post('/chat/completions', data: {
        'model': 'gpt-4o-mini',
        'messages': messages,
        'max_tokens': 400,
        'temperature': 0.8,
        'top_p': 0.9,
      });

      final content = response.data['choices'][0]['message']['content'] as String;
      return content.trim();
    } catch (e) {
      print('❌ Erro ao gerar resposta do chat: $e');
      return _generateFallbackChatResponse();
    }
  }

  /// Categoriza automaticamente um gasto usando IA
  Future<String> categorizeExpense({
    required String description,
    required double amount,
    required List<String> availableCategories,
  }) async {
    try {
      if (!await isConfigured()) {
        // Fallback para categorização local
        return _categorizeFallback(description, availableCategories);
      }

      final prompt = '''
Categorize este gasto:
Descrição: "$description"
Valor: R\$ ${amount.toStringAsFixed(2)}

Categorias disponíveis: ${availableCategories.join(', ')}

Responda apenas com o nome da categoria mais apropriada.
''';

      final response = await _dio.post('/chat/completions', data: {
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content': 'Você é um especialista em categorização de gastos financeiros. Responda apenas com o nome da categoria, sem explicações.',
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'max_tokens': 20,
        'temperature': 0.3,
      });

      final category = response.data['choices'][0]['message']['content'] as String;
      final cleanCategory = category.trim().replaceAll('"', '');
      
      // Verifica se a categoria retornada é válida
      if (availableCategories.contains(cleanCategory)) {
        return cleanCategory;
      }
      
      // Se não for válida, usa fallback
      return _categorizeFallback(description, availableCategories);
    } catch (e) {
      print('❌ Erro ao categorizar com OpenAI: $e');
      return _categorizeFallback(description, availableCategories);
    }
  }

  /// Prompt do sistema para insights financeiros
  String _getSystemPrompt() {
    return '''
Você é um assistente financeiro pessoal especializado e amigável. Suas características:

1. **Personalidade**: Jovem, casual, motivador e empático
2. **Linguagem**: Brasileira, use gírias leves e emojis moderadamente
3. **Estilo**: Dicas práticas, exemplos reais, linguagem acessível
4. **Foco**: Educação financeira, economia doméstica, metas realistas

**Diretrizes:**
- Seja específico e acionável nas dicas
- Use valores em reais (R\$) e contexto brasileiro
- Adapte as sugestões ao perfil do usuário
- Seja encorajador, nunca crítico
- Mantenha respostas entre 100-300 palavras
- Use bullet points para organizar informações
- Inclua sempre uma dica prática no final

**Evite:**
- Linguagem muito técnica ou formal
- Conselhos genéricos sem contexto
- Julgamentos sobre hábitos financeiros
- Recomendações de investimentos específicos
''';
  }

  /// Prompt do sistema para chat (legado - sem contexto financeiro)
  String _getChatSystemPrompt(OnboardingProfileModel? userProfile) {
    return _getChatSystemPromptWithContext(userProfile, null);
  }

  /// Prompt do sistema para chat COM contexto financeiro completo
  /// Inclui metas, gastos atuais, alertas e situação financeira
  String _getChatSystemPromptWithContext(
    OnboardingProfileModel? userProfile,
    FinancialContext? financialContext,
  ) {
    String basePrompt = '''
Você é o assistente financeiro pessoal do usuário. Seja amigável, útil e motivador.

**Seu papel:**
- Responder dúvidas sobre finanças pessoais
- Analisar gastos e padrões financeiros com base nos DADOS REAIS do usuário
- Dar dicas de economia personalizadas
- Alertar sobre metas em risco ou excedidas
- Ajudar com planejamento financeiro
- Motivar bons hábitos financeiros

**Estilo de comunicação:**
- Casual e jovem, mas profissional
- Use emojis moderadamente
- Seja específico e prático - use os valores reais do usuário
- Mantenha respostas concisas (máx 200 palavras)

**Regras importantes:**
- Se o usuário perguntar sobre gastos, USE os dados reais fornecidos
- Se há metas excedidas, ALERTE o usuário sobre isso
- Se há alertas ativos, mencione-os de forma construtiva
- Sempre sugira ações práticas baseadas na situação real
''';

    // Adicionar contexto financeiro REAL se disponível
    if (financialContext != null && financialContext.hasGoals) {
      basePrompt += '''

${financialContext.toPromptContext()}
''';
    } else if (userProfile != null) {
      // Fallback para perfil básico se não houver contexto completo
      final goal = userProfile.getGoal();
      final income = userProfile.getIncome();
      final challenge = userProfile.getBiggestChallenge();
      
      basePrompt += '''

**Perfil do usuário:**
- Objetivo principal: ${goal ?? 'Não informado'}
- Faixa de renda: ${income ?? 'Não informada'}
- Maior desafio: ${challenge ?? 'Não informado'}

(Usuário ainda não configurou metas financeiras detalhadas)
''';
    }

    // Instruções finais
    basePrompt += '''

**Ao responder:**
1. Se o usuário tem metas excedidas, priorize esse alerta
2. Use valores e categorias reais do contexto
3. Sugira ações práticas e específicas
4. Seja encorajador, nunca julgador
''';

    return basePrompt;
  }

  /// Constrói prompt para insights financeiros
  String _buildFinancialInsightPrompt({
    required OnboardingProfileModel userProfile,
    required Map<String, dynamic> expenseData,
    String? specificQuestion,
  }) {
    final goal = userProfile.getGoal();
    final income = userProfile.getIncome();
    final fixedExpenses = userProfile.getFixedExpenses();
    final categories = userProfile.getSpendingCategories();
    final challenge = userProfile.getBiggestChallenge();
    final savingsGoal = userProfile.getSavingsGoal();

    String prompt = '''
**PERFIL DO USUÁRIO:**
- Objetivo: $goal
- Renda: $income
- Gastos fixos: R\$ ${fixedExpenses?.toStringAsFixed(2) ?? 'Não informado'}
- Categorias principais: ${categories.join(', ')}
- Maior desafio: $challenge
- Meta de economia: R\$ ${savingsGoal?.toStringAsFixed(2) ?? 'Não informada'}

**DADOS DE GASTOS:**
${_formatExpenseData(expenseData)}

**SOLICITAÇÃO:**
${specificQuestion ?? 'Gere um insight financeiro personalizado baseado no perfil e dados acima.'}

Responda com uma dica específica, prática e motivadora. Use o nome das categorias e valores reais do usuário.
''';

    return prompt;
  }

  /// Formata dados de gastos para o prompt
  String _formatExpenseData(Map<String, dynamic> expenseData) {
    final buffer = StringBuffer();
    
    if (expenseData.containsKey('totalSpent')) {
      buffer.writeln('- Total gasto: R\$ ${expenseData['totalSpent']}');
    }
    
    if (expenseData.containsKey('categoryBreakdown')) {
      buffer.writeln('- Gastos por categoria:');
      final breakdown = expenseData['categoryBreakdown'] as Map<String, double>;
      breakdown.forEach((category, amount) {
        buffer.writeln('  • $category: R\$ ${amount.toStringAsFixed(2)}');
      });
    }
    
    if (expenseData.containsKey('period')) {
      buffer.writeln('- Período: ${expenseData['period']}');
    }

    return buffer.toString();
  }

  /// Fallback para insights quando OpenAI não está disponível
  String _generateFallbackInsight(OnboardingProfileModel userProfile, Map<String, dynamic> expenseData) {
    final goal = userProfile.getGoal();
    
    if (goal?.contains('economizar') == true) {
      return '💰 **Dica de Economia Personalizada**\n\n'
             'Com base no seu perfil, uma estratégia eficaz seria aplicar a regra 50-30-20: '
             '50% para gastos essenciais, 30% para desejos e 20% para poupança. '
             'Comece com pequenos valores e vá aumentando gradualmente!\n\n'
             '🎯 **Ação prática:** Separe R\$ 50 esta semana em uma conta poupança.';
    }
    
    return '📊 **Insight Financeiro**\n\n'
           'Seus gastos estão organizados! Continue registrando todas as despesas '
           'para ter uma visão clara de onde seu dinheiro está indo. '
           'Isso é o primeiro passo para o controle financeiro.\n\n'
           '💡 **Dica:** Revise seus gastos semanalmente para identificar oportunidades de economia.';
  }

  /// Fallback para chat quando OpenAI não está disponível
  String _generateFallbackChatResponse() {
    return '👋 **Olá! Sou seu assistente financeiro!**\n\n'
           'Estou com dificuldades para processar mensagens abertas no momento, '
           'mas posso te ajudar de outras formas:\n\n'
           '💰 **Registrar gastos** — Basta digitar algo como:\n'
           '• "Gastei 50 reais no mercado"\n'
           '• "Comprei roupa por 150 em 3x"\n'
           '• "Uber 25 reais"\n\n'
           '📊 **Perguntas rápidas** — Use os botões abaixo:\n'
           '• "O que cortar?" — Veja onde economizar\n'
           '• "Gastando demais?" — Análise de gastos\n'
           '• "Delivery?" — Quanto gasta com apps\n\n'
           '🎯 **Pelo app você também pode:**\n'
           '• Ver relatórios detalhados\n'
           '• Configurar metas financeiras\n'
           '• Gerenciar categorias\n\n'
           '💡 _Dica: Use as perguntas rápidas para respostas personalizadas!_';
  }

  /// Categorização local como fallback
  String _categorizeFallback(String description, List<String> categories) {
    final desc = description.toLowerCase();
    
    // Mapeamento simples por palavras-chave
    final keywordMap = {
      'Alimentação': ['comida', 'restaurante', 'supermercado', 'lanche', 'pizza', 'hamburguer', 'café', 'padaria'],
      'Transporte': ['uber', 'gasolina', 'combustível', 'ônibus', 'metro', 'taxi', '99', 'estacionamento'],
      'Saúde': ['farmácia', 'médico', 'hospital', 'remédio', 'consulta', 'dentista'],
      'Lazer': ['cinema', 'show', 'festa', 'bar', 'teatro', 'parque', 'viagem'],
      'Contas': ['luz', 'água', 'internet', 'telefone', 'energia', 'celular', 'netflix'],
    };

    for (final category in categories) {
      final keywords = keywordMap[category] ?? [];
      if (keywords.any((keyword) => desc.contains(keyword))) {
        return category;
      }
    }

    // Se não encontrou, retorna a primeira categoria disponível
    return categories.isNotEmpty ? categories.first : 'Outros';
  }

  /// Verifica status da API
  Future<bool> checkApiStatus() async {
    try {
      if (!await isConfigured()) return false;
      
      final response = await _dio.get('/models', 
        options: Options(receiveTimeout: const Duration(seconds: 10))
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ API OpenAI não disponível: $e');
      return false;
    }
  }

  /// Estima custo de uso da API
  Map<String, dynamic> estimateUsageCost({
    required int messagesPerDay,
    required int insightsPerDay,
  }) {
    // Preços aproximados GPT-4o-mini (por 1M tokens)
    const inputCostPer1M = 0.15; // USD
    const outputCostPer1M = 0.60; // USD
    
    // Estimativa de tokens por operação
    const tokensPerMessage = 200; // input + output
    const tokensPerInsight = 300;
    
    final dailyTokens = (messagesPerDay * tokensPerMessage) + (insightsPerDay * tokensPerInsight);
    final monthlyTokens = dailyTokens * 30;
    
    final monthlyCostUSD = (monthlyTokens / 1000000) * ((inputCostPer1M + outputCostPer1M) / 2);
    final monthlyCostBRL = monthlyCostUSD * 5.0; // Aproximação USD -> BRL
    
    return {
      'daily_tokens': dailyTokens,
      'monthly_tokens': monthlyTokens,
      'monthly_cost_usd': monthlyCostUSD,
      'monthly_cost_brl': monthlyCostBRL,
      'is_economical': monthlyCostBRL < 50.0, // Menos de R$ 50/mês
    };
  }
}
