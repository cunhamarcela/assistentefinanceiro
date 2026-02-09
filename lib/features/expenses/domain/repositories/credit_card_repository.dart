import '../entities/credit_card.dart';

/// Repository abstrato para cartões de crédito
abstract class CreditCardRepository {
  /// Adiciona um novo cartão de crédito
  Future<void> addCard(CreditCard card);

  /// Obtém todos os cartões
  Future<List<CreditCard>> getAllCards();

  /// Obtém apenas cartões ativos
  Future<List<CreditCard>> getActiveCards();

  /// Obtém um cartão por ID
  Future<CreditCard?> getCardById(String id);

  /// Atualiza um cartão
  Future<void> updateCard(CreditCard card);

  /// Deleta um cartão (soft delete)
  Future<void> deleteCard(String id);

  /// Deleta permanentemente um cartão
  Future<void> permanentlyDeleteCard(String id);

  /// Stream de cartões ativos (para atualizações em tempo real)
  Stream<List<CreditCard>> watchActiveCards();

  /// Stream de todos os cartões
  Stream<List<CreditCard>> watchAllCards();
}

