import '../repositories/expense_repository.dart';

class UpdateExpenseUseCase {
  final ExpenseRepository repository;

  UpdateExpenseUseCase(this.repository);

  Future<void> call({
    required String id,
    required double amount,
    required String description,
    required String categoryId,
    required DateTime date,
    String? notes,
  }) async {
    // Validações
    if (id.trim().isEmpty) {
      throw ArgumentError('ID da despesa é obrigatório');
    }

    if (amount <= 0) {
      throw ArgumentError('O valor deve ser maior que zero');
    }
    
    if (description.trim().isEmpty) {
      throw ArgumentError('A descrição não pode estar vazia');
    }
    
    if (description.length > 100) {
      throw ArgumentError('A descrição deve ter no máximo 100 caracteres');
    }

    if (categoryId.trim().isEmpty) {
      throw ArgumentError('Categoria é obrigatória');
    }

    // Buscar despesa existente
    final existingExpense = await repository.getExpenseById(id);
    if (existingExpense == null) {
      throw Exception('Despesa não encontrada');
    }

    // Criar despesa atualizada
    final updatedExpense = existingExpense.copyWith(
      amount: amount,
      description: description.trim(),
      categoryId: categoryId,
      date: date,
      notes: notes?.trim(),
      updatedAt: DateTime.now(),
    );

    // Atualizar no repositório
    await repository.updateExpense(updatedExpense);
  }
}
