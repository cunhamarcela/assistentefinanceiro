import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

/// Use case para gerar resposta do assistente IA
class GenerateAssistantReplyUseCase {
  final ChatRepository repository;

  GenerateAssistantReplyUseCase(this.repository);

  /// Gera uma resposta do assistente baseada no histórico da conversa
  Future<ChatMessage> call({
    required List<ChatMessage> conversationHistory,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Valida se há mensagens na conversa
      if (conversationHistory.isEmpty) {
        throw Exception('Histórico de conversa não pode estar vazio');
      }

      // Verifica se o serviço de IA está disponível
      final isAvailable = await repository.isAiServiceAvailable();
      if (!isAvailable) {
        return _createOfflineResponse();
      }

      // Gera resposta usando o repositório
      final response = await repository.generateAssistantReply(
        conversationHistory: conversationHistory,
        context: context,
      );

      return response;
    } catch (e) {
      // Em caso de erro, retorna uma resposta de fallback
      return _createErrorResponse(e.toString());
    }
  }

  /// Cria uma resposta offline padrão
  ChatMessage _createOfflineResponse() {
    return ChatMessage.assistant(
      content: '📡 **Sem conexão com a internet**\n\n'
               'Não consegui conectar ao servidor, mas você ainda pode:\n\n'
               '📝 **Registrar gastos** — Digite algo como:\n'
               '• "Gastei 50 no mercado"\n'
               '• "Uber 25 reais"\n\n'
               '📊 **Navegar pelo app:**\n'
               '• Ver seus gastos registrados\n'
               '• Consultar relatórios salvos\n'
               '• Gerenciar categorias\n\n'
               '🔄 _Verifique sua conexão e tente novamente._',
      metadata: {
        'type': 'offline_response',
        'has_insight': false,
      },
      status: ChatMessageStatus.sent,
    );
  }

  /// Cria uma resposta de erro
  ChatMessage _createErrorResponse(String error) {
    return ChatMessage.assistant(
      content: '😅 **Ops! Algo deu errado...**\n\n'
               'Mas não se preocupe! Você ainda pode:\n\n'
               '💰 **Registrar gastos:**\n'
               '• "Gastei 50 reais no mercado"\n'
               '• "Comprei roupa por 150"\n\n'
               '📊 **Usar perguntas rápidas:**\n'
               '• "O que cortar?" — Onde economizar\n'
               '• "Gastando demais?" — Análise de gastos\n\n'
               '🔄 _Se o problema persistir, tente reiniciar o app._',
      metadata: {
        'type': 'error_response',
        'error': error,
        'has_insight': false,
      },
      status: ChatMessageStatus.error,
      errorMessage: error,
    );
  }
}

