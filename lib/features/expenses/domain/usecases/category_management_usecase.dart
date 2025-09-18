import '../entities/category.dart';
import '../repositories/expense_repository.dart';

class CategoryManagementUseCase {
  final ExpenseRepository repository;

  CategoryManagementUseCase(this.repository);

  /// Buscar todas as categorias
  Future<List<ExpenseCategory>> getAllCategories() async {
    return await repository.getAllCategories();
  }

  /// Buscar categoria por ID
  Future<ExpenseCategory?> getCategoryById(String id) async {
    return await repository.getCategoryById(id);
  }

  /// Adicionar nova categoria
  Future<void> addCategory({
    required String name,
    required String icon,
    required int colorValue,
    required List<String> keywords,
  }) async {
    // Validações
    if (name.trim().isEmpty) {
      throw ArgumentError('Nome da categoria é obrigatório');
    }

    if (name.length > 30) {
      throw ArgumentError('Nome deve ter no máximo 30 caracteres');
    }

    if (icon.trim().isEmpty) {
      throw ArgumentError('Ícone é obrigatório');
    }

    if (keywords.isEmpty) {
      throw ArgumentError('Pelo menos uma palavra-chave é obrigatória');
    }

    // Verificar se já existe categoria com mesmo nome
    final existingCategories = await repository.getAllCategories();
    final nameExists = existingCategories.any(
      (cat) => cat.name.toLowerCase() == name.trim().toLowerCase(),
    );

    if (nameExists) {
      throw Exception('Já existe uma categoria com este nome');
    }

    // Criar nova categoria
    final category = ExpenseCategory.create(
      name: name.trim(),
      icon: icon,
      colorValue: colorValue,
      keywords: keywords.map((k) => k.trim().toLowerCase()).toList(),
    );

    await repository.addCategory(category);
  }

  /// Atualizar categoria existente
  Future<void> updateCategory({
    required String id,
    required String name,
    required String icon,
    required int colorValue,
    required List<String> keywords,
  }) async {
    // Validações
    if (id.trim().isEmpty) {
      throw ArgumentError('ID da categoria é obrigatório');
    }

    if (name.trim().isEmpty) {
      throw ArgumentError('Nome da categoria é obrigatório');
    }

    if (name.length > 30) {
      throw ArgumentError('Nome deve ter no máximo 30 caracteres');
    }

    if (icon.trim().isEmpty) {
      throw ArgumentError('Ícone é obrigatório');
    }

    if (keywords.isEmpty) {
      throw ArgumentError('Pelo menos uma palavra-chave é obrigatória');
    }

    // Buscar categoria existente
    final existingCategory = await repository.getCategoryById(id);
    if (existingCategory == null) {
      throw Exception('Categoria não encontrada');
    }

    // Verificar se é categoria padrão (não pode ser editada)
    if (existingCategory.isDefault) {
      throw Exception('Categorias padrão não podem ser editadas');
    }

    // Verificar se já existe outra categoria com mesmo nome
    final allCategories = await repository.getAllCategories();
    final nameExists = allCategories.any(
      (cat) => cat.id != id && cat.name.toLowerCase() == name.trim().toLowerCase(),
    );

    if (nameExists) {
      throw Exception('Já existe uma categoria com este nome');
    }

    // Atualizar categoria
    final updatedCategory = existingCategory.copyWith(
      name: name.trim(),
      icon: icon,
      colorValue: colorValue,
      keywords: keywords.map((k) => k.trim().toLowerCase()).toList(),
    );

    await repository.updateCategory(updatedCategory);
  }

  /// Deletar categoria
  Future<void> deleteCategory(String id) async {
    // Validações
    if (id.trim().isEmpty) {
      throw ArgumentError('ID da categoria é obrigatório');
    }

    // Buscar categoria existente
    final category = await repository.getCategoryById(id);
    if (category == null) {
      throw Exception('Categoria não encontrada');
    }

    // Verificar se é categoria padrão (não pode ser deletada)
    if (category.isDefault) {
      throw Exception('Categorias padrão não podem ser deletadas');
    }

    // Verificar se há despesas usando esta categoria
    final expensesWithCategory = await repository.getExpensesByCategory(id);
    if (expensesWithCategory.isNotEmpty) {
      throw Exception(
        'Não é possível deletar categoria que possui ${expensesWithCategory.length} despesa(s). '
        'Mova as despesas para outra categoria primeiro.',
      );
    }

    await repository.deleteCategory(id);
  }

  /// Obter estatísticas da categoria
  Future<CategoryStats> getCategoryStats(String categoryId) async {
    final expenses = await repository.getExpensesByCategory(categoryId);
    final total = await repository.getTotalByCategory(categoryId);

    return CategoryStats(
      categoryId: categoryId,
      expenseCount: expenses.length,
      totalAmount: total,
      lastExpenseDate: expenses.isNotEmpty ? expenses.first.date : null,
    );
  }

  /// Obter categorias mais usadas
  Future<List<CategoryUsage>> getMostUsedCategories({int limit = 5}) async {
    final allCategories = await repository.getAllCategories();
    final categoryUsages = <CategoryUsage>[];

    for (final category in allCategories) {
      final expenses = await repository.getExpensesByCategory(category.id);
      final total = await repository.getTotalByCategory(category.id);

      categoryUsages.add(CategoryUsage(
        category: category,
        expenseCount: expenses.length,
        totalAmount: total,
      ));
    }

    // Ordenar por número de despesas (decrescente)
    categoryUsages.sort((a, b) => b.expenseCount.compareTo(a.expenseCount));

    return categoryUsages.take(limit).toList();
  }

  /// Validar palavras-chave
  List<String> validateKeywords(List<String> keywords) {
    final validKeywords = <String>[];

    for (final keyword in keywords) {
      final trimmed = keyword.trim().toLowerCase();
      if (trimmed.isNotEmpty && trimmed.length >= 2) {
        validKeywords.add(trimmed);
      }
    }

    return validKeywords.toSet().toList(); // Remove duplicatas
  }
}

/// Estatísticas de uma categoria
class CategoryStats {
  final String categoryId;
  final int expenseCount;
  final double totalAmount;
  final DateTime? lastExpenseDate;

  CategoryStats({
    required this.categoryId,
    required this.expenseCount,
    required this.totalAmount,
    this.lastExpenseDate,
  });
}

/// Uso de categoria
class CategoryUsage {
  final ExpenseCategory category;
  final int expenseCount;
  final double totalAmount;

  CategoryUsage({
    required this.category,
    required this.expenseCount,
    required this.totalAmount,
  });
}


