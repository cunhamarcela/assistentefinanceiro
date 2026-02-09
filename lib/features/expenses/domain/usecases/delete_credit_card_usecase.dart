import '../repositories/credit_card_repository.dart';

/// Caso de uso para deletar um cartão de crédito
class DeleteCreditCardUseCase {
  final CreditCardRepository _repository;

  DeleteCreditCardUseCase(this._repository);

  /// Deleta um cartão (soft delete - marca como inativo)
  Future<void> call(String id) async {
    final card = await _repository.getCardById(id);
    if (card == null) {
      throw Exception('Cartão não encontrado');
    }

    await _repository.deleteCard(id);
  }

  /// Deleta permanentemente um cartão
  Future<void> permanently(String id) async {
    final card = await _repository.getCardById(id);
    if (card == null) {
      throw Exception('Cartão não encontrado');
    }

    // Verifica se há despesas vinculadas a este cartão
    // TODO: Implementar verificação de despesas vinculadas
    // Por enquanto, permite a exclusão

    await _repository.permanentlyDeleteCard(id);
  }
}

