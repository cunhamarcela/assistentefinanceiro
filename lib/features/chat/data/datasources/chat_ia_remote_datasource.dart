import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../domain/entities/chat_message.dart';
import '../../../expenses/domain/entities/financial_insight.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../onboarding/data/services/onboarding_service.dart';
import '../../../../core/services/openai_service.dart';

/// Interface para data source remoto do chat IA
abstract class ChatIaRemoteDataSource {
  Future<ChatMessage> generateAssistantReply({
    required List<ChatMessage> conversationHistory,
    Map<String, dynamic>? context,
  });
  Future<Map<String, dynamic>> analyzeUserMessage(String message);
  Future<List<FinancialInsight>> generateFinancialInsights({
    required String userId,
    int? limitDays,
  });
  Future<bool> isAiServiceAvailable();
  Future<Map<String, dynamic>> getChatSettings(String userId);
  Future<void> updateChatSettings(String userId, Map<String, dynamic> settings);
}

/// Implementação do data source remoto usando Firestore e OpenAI
class ChatIaRemoteDataSourceImpl implements ChatIaRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final OpenAIService _openAIService;
  late final OnboardingService _onboardingService;

  ChatIaRemoteDataSourceImpl() {
    _openAIService = Get.find<OpenAIService>();
    _onboardingService = Get.find<OnboardingService>();
  }

  /// Obter userId atual
  String get _currentUserId {
    try {
      final authService = Get.find<AuthService>();
      final userId = authService.currentUser?.id;
      if (userId == null || userId.isEmpty) {
        throw Exception('Usuário não autenticado');
      }
      return userId;
    } catch (e) {
      print('❌ Erro ao obter userId no chat remote: $e');
      rethrow;
    }
  }

  /// Coleção de configurações do chat
  CollectionReference get _chatSettingsCollection =>
      _firestore.collection('users').doc(_currentUserId).collection('chat_settings');

  /// Coleção de insights
  CollectionReference get _insightsCollection =>
      _firestore.collection('users').doc(_currentUserId).collection('insights');

  @override
  Future<ChatMessage> generateAssistantReply({
    required List<ChatMessage> conversationHistory,
    Map<String, dynamic>? context,
  }) async {
    try {
      final startTime = DateTime.now();
      
      // Tentar usar OpenAI primeiro
      if (await _openAIService.isConfigured()) {
        try {
          final userProfile = await _onboardingService.getOnboardingProfile();
          
          // Converter histórico para formato OpenAI
          final messages = conversationHistory.map((msg) => {
            'role': msg.isUser ? 'user' : 'assistant',
            'content': msg.content,
          }).toList();
          
          final aiResponse = await _openAIService.generateChatResponse(
            conversationHistory: messages,
            userProfile: userProfile,
            context: context,
          );
          
          final processingTime = DateTime.now().difference(startTime).inMilliseconds;
          
          return ChatMessage.assistant(
            content: aiResponse,
            metadata: {
              'type': 'openai_response',
              'has_insight': true,
              'processing_time_ms': processingTime,
              'model': 'gpt-4o-mini',
              'personalized': userProfile != null,
            },
            status: ChatMessageStatus.sent,
          );
        } catch (e) {
          print('⚠️ Erro com OpenAI, usando fallback: $e');
        }
      }
      
      // Fallback para respostas locais
      return await _generateLocalResponse(conversationHistory, context);
      
    } catch (e) {
      print('❌ Erro ao gerar resposta do assistente: $e');
      
      return ChatMessage.assistant(
        content: 'Desculpe, ocorreu um erro ao processar sua mensagem. '
                'Tente reformular sua pergunta ou verifique sua conexão.',
        metadata: {
          'type': 'error_response',
          'error': e.toString(),
          'has_insight': false,
        },
        status: ChatMessageStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Gera resposta local como fallback
  Future<ChatMessage> _generateLocalResponse(
    List<ChatMessage> conversationHistory,
    Map<String, dynamic>? context,
  ) async {
    // Simular delay de processamento
    await Future.delayed(const Duration(milliseconds: 800));

    final lastUserMessage = conversationHistory
        .where((m) => m.isUser)
        .lastOrNull;

    if (lastUserMessage == null) {
      throw Exception('Nenhuma mensagem do usuário encontrada');
    }

    final userMessage = lastUserMessage.content.toLowerCase();
    String response;
    Map<String, dynamic> metadata = {
      'type': 'local_response',
      'has_insight': false,
      'processing_time_ms': 800,
    };

    // Análise de intenção baseada em palavras-chave
    if (_containsKeywords(userMessage, ['gasto', 'gastos', 'despesa', 'despesas', 'gastei'])) {
      response = _generateExpenseResponse(userMessage);
      metadata['intent'] = 'expense_analysis';
      metadata['has_insight'] = true;
      metadata['insight_type'] = 'expense_summary';
    } else if (_containsKeywords(userMessage, ['relatório', 'relatorio', 'gráfico', 'grafico', 'análise', 'analise'])) {
      response = _generateReportResponse(userMessage);
      metadata['intent'] = 'report_request';
      metadata['has_insight'] = true;
      metadata['insight_type'] = 'report_generation';
    } else if (_containsKeywords(userMessage, ['economia', 'economizar', 'poupar', 'dica', 'dicas'])) {
      response = _generateSavingsResponse(userMessage);
      metadata['intent'] = 'savings_advice';
      metadata['has_insight'] = true;
      metadata['insight_type'] = 'savings_opportunity';
    } else if (_containsKeywords(userMessage, ['categoria', 'categorias', 'classificar', 'organizar'])) {
      response = _generateCategoryResponse(userMessage);
      metadata['intent'] = 'category_management';
    } else if (_containsKeywords(userMessage, ['meta', 'metas', 'objetivo', 'objetivos', 'orçamento', 'orcamento'])) {
      response = _generateGoalResponse(userMessage);
      metadata['intent'] = 'goal_management';
      metadata['has_insight'] = true;
      metadata['insight_type'] = 'goal_progress';
    } else {
      response = _generateGeneralResponse(userMessage);
      metadata['intent'] = 'general_conversation';
    }

    return ChatMessage.assistant(
      content: response,
      metadata: metadata,
      status: ChatMessageStatus.sent,
    );
  }

  @override
  Future<Map<String, dynamic>> analyzeUserMessage(String message) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final lowerMessage = message.toLowerCase();
      final analysis = <String, dynamic>{
        'message': message,
        'intent': 'unknown',
        'confidence': 0.0,
        'entities': <String>[],
        'keywords': <String>[],
        'sentiment': 'neutral',
      };

      // Análise de intenção
      if (_containsKeywords(lowerMessage, ['gasto', 'gastos', 'despesa', 'despesas'])) {
        analysis['intent'] = 'expense_inquiry';
        analysis['confidence'] = 0.85;
        analysis['keywords'] = ['gastos', 'despesas'];
      } else if (_containsKeywords(lowerMessage, ['relatório', 'gráfico', 'análise'])) {
        analysis['intent'] = 'report_request';
        analysis['confidence'] = 0.90;
        analysis['keywords'] = ['relatório', 'análise'];
      } else if (_containsKeywords(lowerMessage, ['economia', 'economizar', 'dica'])) {
        analysis['intent'] = 'savings_advice';
        analysis['confidence'] = 0.80;
        analysis['keywords'] = ['economia', 'dicas'];
      }

      // Análise de sentimento básica
      if (_containsKeywords(lowerMessage, ['obrigado', 'obrigada', 'valeu', 'legal', 'ótimo', 'bom'])) {
        analysis['sentiment'] = 'positive';
      } else if (_containsKeywords(lowerMessage, ['problema', 'erro', 'ruim', 'difícil', 'complicado'])) {
        analysis['sentiment'] = 'negative';
      }

      return analysis;
    } catch (e) {
      print('❌ Erro ao analisar mensagem: $e');
      return {
        'message': message,
        'intent': 'unknown',
        'confidence': 0.0,
        'error': e.toString(),
      };
    }
  }

  @override
  Future<List<FinancialInsight>> generateFinancialInsights({
    required String userId,
    int? limitDays,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 1000));

      final insights = <FinancialInsight>[];
      final now = DateTime.now();

      // Insight de gastos excessivos (simulado)
      insights.add(FinancialInsight(
        id: 'excessive_spending_demo',
        type: FinancialInsightType.budgetExceeded,
        priority: FinancialInsightPriority.high,
        title: 'Gasto Excessivo em Alimentação',
        description: 'Você gastou R\$ 1.200,00 em alimentação este mês, R\$ 400,00 acima da média de R\$ 800,00.',
        data: {
          'amount': 1200.0,
          'category': 'Alimentação',
          'average': 800.0,
          'period': 'este mês',
        },
        actionSuggestions: ['Revisar Gastos', 'Criar Orçamento'],
        createdAt: now,
        isRead: false,
      ));

      // Insight de oportunidade de economia
      insights.add(FinancialInsight(
        id: 'savings_opportunity_demo',
        type: FinancialInsightType.savingsOpportunity,
        priority: FinancialInsightPriority.medium,
        title: 'Oportunidade de Economia em Transporte',
        description: 'Considere usar transporte público ou carona compartilhada. Você poderia economizar até R\$ 150,00.',
        data: {
          'category': 'Transporte',
          'potential_savings': 150.0,
        },
        actionSuggestions: ['Ver Alternativas', 'Calcular Economia'],
        createdAt: now,
        isRead: false,
      ));

      // Insight de progresso de meta
      insights.add(FinancialInsight(
        id: 'goal_progress_demo',
        type: FinancialInsightType.goalProgress,
        priority: FinancialInsightPriority.low,
        title: 'Progresso da Reserva de Emergência',
        description: 'Você já tem R\$ 2.500,00 dos R\$ 5.000,00 da sua meta. Está no caminho certo!',
        data: {
          'goal_name': 'Reserva de Emergência',
          'current': 2500.0,
          'target': 5000.0,
          'progress': 50.0,
          'on_track': true,
        },
        actionSuggestions: ['Ver Progresso', 'Ajustar Meta'],
        createdAt: now,
        isRead: false,
      ));

      // Salvar insights no Firestore para histórico
      for (final insight in insights) {
        await _saveInsightToFirestore(insight);
      }

      return insights;
    } catch (e) {
      print('❌ Erro ao gerar insights financeiros: $e');
      return [];
    }
  }

  @override
  Future<bool> isAiServiceAvailable() async {
    try {
      // Simular verificação de disponibilidade do serviço
      await Future.delayed(const Duration(milliseconds: 200));
      return true; // Em produção, verificar status real da API
    } catch (e) {
      print('❌ Erro ao verificar disponibilidade da IA: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getChatSettings(String userId) async {
    try {
      final doc = await _chatSettingsCollection.doc('preferences').get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }

      // Configurações padrão
      final defaultSettings = {
        'ai_enabled': true,
        'auto_insights': true,
        'response_style': 'friendly',
        'language': 'pt_BR',
        'notifications': true,
        'data_sharing': false,
        'created_at': FieldValue.serverTimestamp(),
      };

      await _chatSettingsCollection.doc('preferences').set(defaultSettings);
      return defaultSettings;
    } catch (e) {
      print('❌ Erro ao buscar configurações do chat: $e');
      return {
        'ai_enabled': true,
        'auto_insights': true,
        'response_style': 'friendly',
      };
    }
  }

  @override
  Future<void> updateChatSettings(String userId, Map<String, dynamic> settings) async {
    try {
      settings['updated_at'] = FieldValue.serverTimestamp();
      
      await _chatSettingsCollection.doc('preferences').set(
        settings,
        SetOptions(merge: true),
      );

      print('✅ Configurações do chat atualizadas');
    } catch (e) {
      print('❌ Erro ao atualizar configurações do chat: $e');
      throw Exception('Erro ao atualizar configurações: $e');
    }
  }

  /// Salva insight no Firestore
  Future<void> _saveInsightToFirestore(FinancialInsight insight) async {
    try {
      await _insightsCollection.doc(insight.id).set({
        'title': insight.title,
        'description': insight.description,
        'type': insight.type.name,
        'priority': insight.priority.name,
        'data': insight.data,
        'created_at': FieldValue.serverTimestamp(),
        'expires_at': null,
        'tags': [],
        'action_text': insight.actionSuggestions.isNotEmpty ? insight.actionSuggestions.first : null,
        'action_route': null,
      });
    } catch (e) {
      print('⚠️ Erro ao salvar insight no Firestore: $e');
      // Não propagar erro para não quebrar o fluxo principal
    }
  }

  /// Verifica se o texto contém palavras-chave
  bool _containsKeywords(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Gera resposta sobre gastos
  String _generateExpenseResponse(String userMessage) {
    final responses = [
      'Vou analisar seus gastos para você! 📊\n\n'
      'Com base nos seus dados, vejo que você gastou mais em algumas categorias este mês. '
      'Posso criar um relatório detalhado para você visualizar melhor onde seu dinheiro está indo.\n\n'
      '💡 Dica: Que tal definir um limite mensal para as categorias que mais consomem seu orçamento?',
      
      'Analisando seus gastos recentes... 💰\n\n'
      'Identifiquei alguns padrões interessantes nos seus hábitos de consumo. '
      'Seus maiores gastos estão concentrados em alimentação e transporte.\n\n'
      '📈 Quer que eu crie um gráfico para você visualizar a distribuição dos seus gastos?',
      
      'Seus gastos estão organizados por categoria! 🏷️\n\n'
      'Posso ver que você tem um bom controle das suas finanças. '
      'Para uma análise mais detalhada, posso gerar relatórios personalizados.\n\n'
      '🎯 Gostaria de definir metas de gastos para o próximo mês?',
    ];
    
    return responses[DateTime.now().millisecond % responses.length];
  }

  /// Gera resposta sobre relatórios
  String _generateReportResponse(String userMessage) {
    return 'Vou criar um relatório visual para você! 📊\n\n'
           'Posso gerar diferentes tipos de análises:\n\n'
           '• 🥧 **Gastos por Categoria** - Veja onde você mais gasta\n'
           '• 📈 **Tendência Temporal** - Como seus gastos evoluem\n'
           '• 📊 **Comparação Mensal** - Compare diferentes períodos\n\n'
           'Qual tipo de relatório você gostaria de ver primeiro?\n\n'
           '💡 Todos os relatórios incluem insights personalizados e dicas de economia!';
  }

  /// Gera resposta sobre economia
  String _generateSavingsResponse(String userMessage) {
    final tips = [
      '💡 **Dicas de Economia Personalizadas:**\n\n'
      '1. **Alimentação**: Planeje suas refeições e faça lista de compras\n'
      '2. **Transporte**: Use apps de carona ou transporte público\n'
      '3. **Assinaturas**: Revise serviços que você não usa frequentemente\n\n'
      '🎯 Com pequenas mudanças, você pode economizar até R\$ 300/mês!',
      
      '🌟 **Estratégias de Economia:**\n\n'
      '• **Regra 50/30/20**: 50% necessidades, 30% desejos, 20% poupança\n'
      '• **Desafio 52 semanas**: Poupe um valor crescente a cada semana\n'
      '• **Método envelope**: Separe dinheiro por categoria\n\n'
      '📈 Quer que eu ajude você a criar um plano de economia personalizado?',
    ];
    
    return tips[DateTime.now().millisecond % tips.length];
  }

  /// Gera resposta sobre categorias
  String _generateCategoryResponse(String userMessage) {
    return '🏷️ **Gerenciamento de Categorias**\n\n'
           'Suas categorias estão bem organizadas! Aqui estão algumas dicas:\n\n'
           '• **Alimentação**: Separe casa vs. restaurantes\n'
           '• **Transporte**: Divida combustível, manutenção e transporte público\n'
           '• **Lazer**: Categorize por tipo de atividade\n\n'
           '🎨 Você pode personalizar cores e ícones para facilitar a identificação.\n\n'
           '❓ Precisa de ajuda para criar uma nova categoria ou reorganizar as existentes?';
  }

  /// Gera resposta sobre metas
  String _generateGoalResponse(String userMessage) {
    return '🎯 **Suas Metas Financeiras**\n\n'
           'Definir metas é fundamental para o sucesso financeiro! Vejo que você está no caminho certo.\n\n'
           '📊 **Status das suas metas:**\n'
           '• Reserva de Emergência: 50% concluída\n'
           '• Economia Mensal: No prazo\n\n'
           '🚀 **Próximos passos:**\n'
           '1. Mantenha a disciplina atual\n'
           '2. Considere aumentar 10% na poupança\n'
           '3. Defina uma nova meta de longo prazo\n\n'
           '💪 Você está indo muito bem! Continue assim!';
  }

  /// Gera resposta geral
  String _generateGeneralResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase().trim();
    
    // Respostas para saudações comuns
    if (_containsKeywords(lowerMessage, ['oi', 'olá', 'ola', 'hey', 'ei', 'eae', 'eai', 'bom dia', 'boa tarde', 'boa noite', 'hello', 'hi'])) {
      return '👋 **Olá! Que bom te ver por aqui!**\n\n'
             'Sou seu assistente financeiro pessoal. Veja o que posso fazer:\n\n'
             '💰 **Registrar gastos por texto:**\n'
             '• "Gastei 50 no mercado"\n'
             '• "Almocei por 35 reais"\n'
             '• "Uber 22 reais"\n\n'
             '📊 **Analisar suas finanças:**\n'
             '• "Quanto gastei este mês?"\n'
             '• "Onde estou gastando demais?"\n'
             '• "Quanto posso gastar por dia?"\n\n'
             '💡 **Dicas personalizadas:**\n'
             '• "O que posso cortar?"\n'
             '• "Dicas de economia"\n\n'
             '⬇️ _Use os botões de **Perguntas rápidas** abaixo para começar!_';
    }
    
    // Respostas para agradecimentos
    if (_containsKeywords(lowerMessage, ['obrigado', 'obrigada', 'valeu', 'thanks', 'vlw', 'tmj', 'brigadão', 'brigada'])) {
      return '😊 **De nada! Fico feliz em ajudar!**\n\n'
             'Se precisar de mais alguma coisa, é só chamar:\n\n'
             '• Registre um gasto: "Gastei X em Y"\n'
             '• Peça uma análise: "Como estou indo?"\n'
             '• Use as **perguntas rápidas** abaixo ⬇️';
    }
    
    // Respostas para "tudo bem", "como vai", etc.
    if (_containsKeywords(lowerMessage, ['tudo bem', 'como vai', 'tudo certo', 'beleza', 'de boa', 'suave'])) {
      return '😄 **Tudo ótimo! E com você?**\n\n'
             'Estou aqui pronto para te ajudar com suas finanças!\n\n'
             '💡 **Experimente perguntar:**\n'
             '• "Como estou indo este mês?"\n'
             '• "Quanto gastei com alimentação?"\n'
             '• "O que posso cortar?"\n\n'
             '📝 **Ou registre um gasto:**\n'
             '• "Gastei 50 reais no supermercado"';
    }
    
    // Resposta padrão para mensagens não reconhecidas
    final responses = [
      '🤔 **Não entendi bem sua mensagem...**\n\n'
      'Mas não se preocupe! Veja o que posso fazer:\n\n'
      '💰 **Registrar gastos** — Digite algo como:\n'
      '• "Gastei 50 no mercado"\n'
      '• "Paguei 100 de luz"\n'
      '• "Almoço 30 reais"\n\n'
      '📊 **Analisar finanças** — Pergunte:\n'
      '• "Quanto gastei este mês?"\n'
      '• "Onde estou gastando demais?"\n'
      '• "Como estou indo?"\n\n'
      '⬇️ _Ou use os botões de **Perguntas rápidas** abaixo!_',
      
      '🧐 **Hmm, não consegui processar isso...**\n\n'
      'Mas posso te ajudar de várias formas!\n\n'
      '📝 **Para registrar gastos:**\n'
      '• "Comprei roupa por 150 reais"\n'
      '• "Uber 25 reais"\n'
      '• "Netflix 55 reais"\n\n'
      '📈 **Para análises:**\n'
      '• "Estou gastando demais?"\n'
      '• "O que posso cortar?"\n'
      '• "Quanto posso gastar por dia?"\n\n'
      '💡 _Dica: Use as **perguntas rápidas** para respostas personalizadas!_',
    ];
    
    return responses[DateTime.now().millisecond % responses.length];
  }
}
