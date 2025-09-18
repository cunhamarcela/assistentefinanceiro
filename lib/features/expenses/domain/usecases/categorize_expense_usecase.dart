import '../entities/category.dart';
import '../repositories/expense_repository.dart';

class CategorizeExpenseUseCase {
  final ExpenseRepository repository;

  CategorizeExpenseUseCase(this.repository);

  /// Sugere uma categoria baseada na descrição
  Future<String> suggestCategory(String description) async {
    if (description.trim().isEmpty) {
      return 'outros';
    }

    final categories = await repository.getAllCategories();
    final lowerDescription = description.toLowerCase();

    // Procura por correspondências exatas primeiro
    for (final category in categories) {
      if (category.matchesDescription(lowerDescription)) {
        return category.id;
      }
    }

    // Se não encontrou correspondência, retorna "outros"
    return 'outros';
  }

  /// Busca todas as categorias
  Future<List<ExpenseCategory>> getAllCategories() async {
    return repository.getAllCategories();
  }

  /// Busca categoria por ID
  Future<ExpenseCategory?> getCategoryById(String id) async {
    return repository.getCategoryById(id);
  }

  /// Analisa texto e extrai possíveis valores e descrições
  Future<ExpenseAnalysis> analyzeExpenseText(String text) async {
    final analysis = ExpenseAnalysis();
    
    // Regex para encontrar valores monetários
    final moneyRegex = RegExp(r'(\d+(?:[.,]\d{2})?)\s*(?:reais?|r\$|R\$)?', caseSensitive: false);
    final moneyMatch = moneyRegex.firstMatch(text);
    
    if (moneyMatch != null) {
      final valueStr = moneyMatch.group(1)!.replaceAll(',', '.');
      analysis.amount = double.tryParse(valueStr);
    }

    // Remove o valor do texto para extrair a descrição
    String description = text;
    if (moneyMatch != null) {
      description = text.replaceAll(moneyMatch.group(0)!, '').trim();
    }

    // Remove palavras comuns que não agregam à descrição
    final stopWords = ['gastei', 'paguei', 'comprei', 'no', 'na', 'em', 'com', 'de', 'do', 'da'];
    final words = description.split(' ');
    final filteredWords = words.where((word) => 
        word.length > 2 && !stopWords.contains(word.toLowerCase())).toList();
    
    analysis.description = filteredWords.join(' ').trim();
    
    // Se a descrição ficou vazia, usa o texto original
    if (analysis.description.isEmpty) {
      analysis.description = text.replaceAll(moneyMatch?.group(0) ?? '', '').trim();
    }

    // Sugere categoria baseada na descrição
    analysis.suggestedCategoryId = await suggestCategory(analysis.description);

    return analysis;
  }
}

class ExpenseAnalysis {
  double? amount;
  String description = '';
  String suggestedCategoryId = 'outros';

  bool get isValid => amount != null && amount! > 0 && description.isNotEmpty;
}
