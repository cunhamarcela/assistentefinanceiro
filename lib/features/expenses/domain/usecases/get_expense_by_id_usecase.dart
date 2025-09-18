import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class GetExpenseByIdUseCase {
  final ExpenseRepository repository;

  GetExpenseByIdUseCase(this.repository);

  Future<Expense?> call(String id) async {
    // Validações
    if (id.trim().isEmpty) {
      throw ArgumentError('ID da despesa é obrigatório');
    }

    // Buscar despesa no repositório
    return await repository.getExpenseById(id);
  }
}


