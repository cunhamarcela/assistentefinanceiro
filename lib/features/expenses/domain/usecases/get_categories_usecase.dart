import '../entities/category.dart';
import '../repositories/expense_repository.dart';

/// Use case para buscar todas as categorias
class GetCategoriesUseCase {
  final ExpenseRepository repository;

  GetCategoriesUseCase(this.repository);

  /// Executar busca por todas as categorias
  Future<List<ExpenseCategory>> execute() async {
    try {
      return await repository.getAllCategories();
    } catch (e) {
      print('❌ Erro no GetCategoriesUseCase: $e');
      throw Exception('Erro ao buscar categorias: $e');
    }
  }
}
