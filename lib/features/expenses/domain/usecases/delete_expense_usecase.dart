import '../repositories/expense_repository.dart';

class DeleteExpenseUseCase {
  final ExpenseRepository repository;

  DeleteExpenseUseCase(this.repository);

  Future<void> call(String id) async {
    // Validações
    if (id.trim().isEmpty) {
      throw ArgumentError('ID da despesa é obrigatório');
    }

    // Verificar se a despesa existe
    final expense = await repository.getExpenseById(id);
    if (expense == null) {
      throw Exception('Despesa não encontrada');
    }

    // Deletar do repositório
    await repository.deleteExpense(id);
  }
}


