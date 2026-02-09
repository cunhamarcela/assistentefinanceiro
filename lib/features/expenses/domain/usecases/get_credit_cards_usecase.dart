import '../entities/credit_card.dart';
import '../repositories/credit_card_repository.dart';

/// Caso de uso para obter cartões de crédito
class GetCreditCardsUseCase {
  final CreditCardRepository _repository;

  GetCreditCardsUseCase(this._repository);

  /// Obtém todos os cartões
  Future<List<CreditCard>> getAllCards() async {
    return await _repository.getAllCards();
  }

  /// Obtém apenas cartões ativos
  Future<List<CreditCard>> getActiveCards() async {
    return await _repository.getActiveCards();
  }

  /// Obtém um cartão específico por ID
  Future<CreditCard?> getCardById(String id) async {
    return await _repository.getCardById(id);
  }

  /// Stream de cartões ativos (para atualizações em tempo real)
  Stream<List<CreditCard>> watchActiveCards() {
    return _repository.watchActiveCards();
  }

  /// Stream de todos os cartões
  Stream<List<CreditCard>> watchAllCards() {
    return _repository.watchAllCards();
  }
}

