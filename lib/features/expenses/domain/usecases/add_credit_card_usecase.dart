import '../entities/credit_card.dart';
import '../repositories/credit_card_repository.dart';

/// Caso de uso para adicionar um cartão de crédito
class AddCreditCardUseCase {
  final CreditCardRepository _repository;

  AddCreditCardUseCase(this._repository);

  Future<void> call({
    required String name,
    required String lastFourDigits,
    required int closingDay,
    required int dueDay,
    double? limit,
    String? flag,
    String? color,
  }) async {
    print('💳 [UseCase] Iniciando validações...');
    
    // Validações
    if (name.trim().isEmpty) {
      throw Exception('Nome do cartão não pode ser vazio');
    }

    if (lastFourDigits.length != 4) {
      throw Exception('Os últimos 4 dígitos devem ter exatamente 4 caracteres');
    }

    if (closingDay < 1 || closingDay > 31) {
      throw Exception('Dia de fechamento deve estar entre 1 e 31');
    }

    if (dueDay < 1 || dueDay > 31) {
      throw Exception('Dia de vencimento deve estar entre 1 e 31');
    }

    if (limit != null && limit < 0) {
      throw Exception('Limite não pode ser negativo');
    }

    print('💳 [UseCase] Validações OK, criando cartão...');
    
    // Cria o cartão
    final card = CreditCard.create(
      name: name.trim(),
      lastFourDigits: lastFourDigits,
      closingDay: closingDay,
      dueDay: dueDay,
      limit: limit,
      flag: flag,
      color: color,
    );

    print('💳 [UseCase] Cartão criado: ${card.id}, salvando no repositório...');
    
    // Salva no repositório
    await _repository.addCard(card);
    
    print('💳 [UseCase] ✅ Cartão salvo com sucesso!');
  }
}

