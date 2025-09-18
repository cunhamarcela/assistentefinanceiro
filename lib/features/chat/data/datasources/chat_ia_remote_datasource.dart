import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/financial_insight.dart';
import '../../../auth/data/services/auth_service.dart';

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

/// Implementação do data source remoto usando Firestore e IA simulada
class ChatIaRemoteDataSourceImpl implements ChatIaRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      // Simular delay de processamento da IA
      await Future.delayed(const Duration(milliseconds: 1500));

      final lastUserMessage = conversationHistory
          .where((m) => m.isUser)
          .lastOrNull;

      if (lastUserMessage == null) {
        throw Exception('Nenhuma mensagem do usuário encontrada');
      }

      final userMessage = lastUserMessage.content.toLowerCase();
      String response;
      Map<String, dynamic> metadata = {
        'type': 'ai_response',
        'has_insight': false,
        'processing_time_ms': 1500,
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
      insights.add(FinancialInsight.excessiveSpending(
        amount: 1200.0,
        category: 'Alimentação',
        averageAmount: 800.0,
        period: 'este mês',
      ));

      // Insight de oportunidade de economia
      insights.add(FinancialInsight.savingsOpportunity(
        category: 'Transporte',
        potentialSavings: 150.0,
        suggestion: 'Considere usar transporte público ou carona compartilhada.',
      ));

      // Insight de progresso de meta
      insights.add(FinancialInsight.goalProgress(
        goalName: 'Reserva de Emergência',
        currentAmount: 2500.0,
        targetAmount: 5000.0,
        isOnTrack: true,
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
        'expires_at': insight.expiresAt != null 
            ? Timestamp.fromDate(insight.expiresAt!)
            : null,
        'tags': insight.tags,
        'action_text': insight.actionText,
        'action_route': insight.actionRoute,
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
    final responses = [
      'Olá! 👋 Sou seu assistente financeiro inteligente.\n\n'
      'Posso ajudar você com:\n'
      '• Análise de gastos e relatórios\n'
      '• Dicas de economia personalizadas\n'
      '• Organização de categorias\n'
      '• Definição e acompanhamento de metas\n\n'
      'Como posso ajudar você hoje?',
      
      'Estou aqui para tornar sua vida financeira mais organizada! 💰\n\n'
      'Algumas coisas que posso fazer:\n'
      '📊 Criar relatórios visuais dos seus gastos\n'
      '💡 Dar dicas de economia baseadas no seu perfil\n'
      '🎯 Ajudar a definir e acompanhar metas\n\n'
      'O que você gostaria de saber sobre suas finanças?',
    ];
    
    return responses[DateTime.now().millisecond % responses.length];
  }
}
