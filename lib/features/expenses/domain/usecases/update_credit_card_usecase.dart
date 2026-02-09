import '../repositories/credit_card_repository.dart';

/// Caso de uso para atualizar um cartão de crédito
class UpdateCreditCardUseCase {
  final CreditCardRepository _repository;

  UpdateCreditCardUseCase(this._repository);

  Future<void> call({
    required String id,
    String? name,
    String? lastFourDigits,
    int? closingDay,
    int? dueDay,
    double? limit,
    String? flag,
    String? color,
    bool? isActive,
  }) async {
    // Busca o cartão existente
    final existingCard = await _repository.getCardById(id);
    if (existingCard == null) {
      throw Exception('Cartão não encontrado');
    }

    // Validações
    if (name != null && name.trim().isEmpty) {
      throw Exception('Nome do cartão não pode ser vazio');
    }

    if (lastFourDigits != null && lastFourDigits.length != 4) {
      throw Exception('Os últimos 4 dígitos devem ter exatamente 4 caracteres');
    }

    if (closingDay != null && (closingDay < 1 || closingDay > 31)) {
      throw Exception('Dia de fechamento deve estar entre 1 e 31');
    }

    if (dueDay != null && (dueDay < 1 || dueDay > 31)) {
      throw Exception('Dia de vencimento deve estar entre 1 e 31');
    }

    if (limit != null && limit < 0) {
      throw Exception('Limite não pode ser negativo');
    }

    // Atualiza o cartão
    final updatedCard = existingCard.copyWith(
      name: name?.trim(),
      lastFourDigits: lastFourDigits,
      closingDay: closingDay,
      dueDay: dueDay,
      limit: limit,
      flag: flag,
      color: color,
      isActive: isActive,
    );

    // Salva no repositório
    await _repository.updateCard(updatedCard);
  }
}

