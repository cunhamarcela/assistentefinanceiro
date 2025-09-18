import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class AddExpenseUseCase {
  final ExpenseRepository repository;

  AddExpenseUseCase(this.repository);

  Future<void> call({
    required double amount,
    required String description,
    String? categoryId,
    DateTime? date,
    String? notes,
  }) async {
    // Validações
    if (amount <= 0) {
      throw ArgumentError('O valor deve ser maior que zero');
    }
    
    if (description.trim().isEmpty) {
      throw ArgumentError('A descrição não pode estar vazia');
    }
    
    if (description.length > 100) {
      throw ArgumentError('A descrição deve ter no máximo 100 caracteres');
    }

    // Se não foi fornecida uma categoria, sugere uma automaticamente
    String finalCategoryId = categoryId ?? await repository.suggestCategory(description);
    
    // Se ainda não tiver categoria, usa "outros"
    if (finalCategoryId.isEmpty) {
      finalCategoryId = 'outros';
    }

    // Cria a despesa
    final expense = Expense.create(
      amount: amount,
      description: description.trim(),
      categoryId: finalCategoryId,
      date: date,
      notes: notes?.trim(),
    );

    // Salva no repositório
    await repository.addExpense(expense);
  }
}
