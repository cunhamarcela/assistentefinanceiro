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
      content: 'Desculpe, estou temporariamente indisponível. '
               'Verifique sua conexão com a internet e tente novamente. '
               'Enquanto isso, você pode navegar pelos seus gastos e relatórios.',
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
      content: 'Ops! Algo deu errado ao processar sua mensagem. '
               'Tente reformular sua pergunta ou verifique sua conexão.',
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
