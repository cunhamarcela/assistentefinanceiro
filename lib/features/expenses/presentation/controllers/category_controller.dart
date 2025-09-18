import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/category.dart';
import '../../domain/usecases/category_management_usecase.dart';

class CategoryController extends GetxController {
  final CategoryManagementUseCase categoryManagementUseCase;

  CategoryController({required this.categoryManagementUseCase});

  // Estados observáveis
  final RxList<ExpenseCategory> categories = <ExpenseCategory>[].obs;
  final RxList<CategoryUsage> categoryUsages = <CategoryUsage>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;

  // Filtros
  final RxString searchQuery = ''.obs;
  final RxBool showOnlyCustom = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
    loadCategoryUsages();
  }

  /// Carrega todas as categorias
  Future<void> loadCategories() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await categoryManagementUseCase.getAllCategories();
      categories.value = result;
    } catch (e) {
      errorMessage.value = 'Erro ao carregar categorias: $e';
      Get.snackbar(
        'Erro',
        'Erro ao carregar categorias: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Carrega estatísticas de uso das categorias
  Future<void> loadCategoryUsages() async {
    try {
      final result = await categoryManagementUseCase.getMostUsedCategories();
      categoryUsages.value = result;
    } catch (e) {
      print('Erro ao carregar estatísticas de categorias: $e');
    }
  }

  /// Adiciona nova categoria
  Future<void> addCategory({
    required String name,
    required String icon,
    required Color color,
    required List<String> keywords,
  }) async {
    try {
      print('🏷️ [CategoryController] Iniciando adição de categoria: $name');
      isSaving.value = true;
      errorMessage.value = '';

      final validKeywords = categoryManagementUseCase.validateKeywords(keywords);
      if (validKeywords.isEmpty) {
        throw ArgumentError('Pelo menos uma palavra-chave válida é obrigatória');
      }

      await categoryManagementUseCase.addCategory(
        name: name,
        icon: icon,
        colorValue: color.value,
        keywords: validKeywords,
      );
      print('🏷️ [CategoryController] Categoria salva com sucesso');

      print('🏷️ [CategoryController] Voltando para tela anterior imediatamente');
      // Volta para tela anterior IMEDIATAMENTE
      Get.back();

      // Mostra snackbar após voltar
      Get.snackbar(
        'Sucesso',
        'Categoria "$name" criada com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      print('🏷️ [CategoryController] Iniciando reload em background');
      // Recarrega dados em background (sem bloquear a UI)
      _reloadCategoriesInBackground();
    } catch (e) {
      print('❌ [CategoryController] Erro ao adicionar categoria: $e');
      errorMessage.value = e.toString();
      Get.snackbar(
        'Erro',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      print('🏷️ [CategoryController] Finalizando (isSaving = false)');
      isSaving.value = false;
    }
  }

  /// Recarrega categorias em background sem bloquear a UI
  void _reloadCategoriesInBackground() {
    print('🔄 [CategoryController] Iniciando reload rápido em background...');
    
    // Executa em background com timeout reduzido para ser mais rápido
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        print('🔄 [CategoryController] Carregando categorias em background...');
        await loadCategories().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('⚠️ [CategoryController] Timeout ao carregar categorias');
          },
        );
        print('🔄 [CategoryController] ✅ Categorias recarregadas em background');
      } catch (e) {
        print('⚠️ [CategoryController] Erro ao recarregar categorias: $e');
      }

      // Carregar estatísticas em paralelo (não sequencial)
      Future.delayed(Duration.zero, () async {
        try {
          print('🔄 [CategoryController] Carregando estatísticas em background...');
          await loadCategoryUsages().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('⚠️ [CategoryController] Timeout ao carregar estatísticas');
            },
          );
          print('🔄 [CategoryController] ✅ Estatísticas recarregadas em background');
        } catch (e) {
          print('⚠️ [CategoryController] Erro ao recarregar estatísticas: $e');
        }
      });
      
      print('🔄 [CategoryController] ✅ Reload em background iniciado');
    });
  }

  /// Atualiza categoria existente
  Future<void> updateCategory({
    required String id,
    required String name,
    required String icon,
    required Color color,
    required List<String> keywords,
  }) async {
    try {
      print('🏷️ [CategoryController] Iniciando atualização de categoria: $name');
      isSaving.value = true;
      errorMessage.value = '';

      final validKeywords = categoryManagementUseCase.validateKeywords(keywords);
      if (validKeywords.isEmpty) {
        throw ArgumentError('Pelo menos uma palavra-chave válida é obrigatória');
      }

      await categoryManagementUseCase.updateCategory(
        id: id,
        name: name,
        icon: icon,
        colorValue: color.value,
        keywords: validKeywords,
      );
      print('🏷️ [CategoryController] Categoria atualizada com sucesso');

      print('🏷️ [CategoryController] Voltando para tela anterior imediatamente');
      // Volta para tela anterior IMEDIATAMENTE
      Get.back();

      // Mostra snackbar após voltar
      Get.snackbar(
        'Sucesso',
        'Categoria "$name" atualizada com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      print('🏷️ [CategoryController] Iniciando reload em background');
      // Recarrega dados em background (sem bloquear a UI)
      _reloadCategoriesInBackground();
    } catch (e) {
      print('❌ [CategoryController] Erro ao atualizar categoria: $e');
      errorMessage.value = e.toString();
      Get.snackbar(
        'Erro',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      print('🏷️ [CategoryController] Finalizando (isSaving = false)');
      isSaving.value = false;
    }
  }

  /// Deleta categoria
  Future<void> deleteCategory(ExpenseCategory category) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await categoryManagementUseCase.deleteCategory(category.id);

      // Recarrega dados
      await Future.wait([
        loadCategories(),
        loadCategoryUsages(),
      ]);

      Get.snackbar(
        'Sucesso',
        'Categoria "${category.name}" excluída com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Erro',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Confirma exclusão de categoria
  Future<void> confirmDeleteCategory(ExpenseCategory category) async {
    if (category.isDefault) {
      Get.snackbar(
        'Aviso',
        'Categorias padrão não podem ser excluídas',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Deseja realmente excluir a categoria "${category.name}"?\n\n'
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (result == true) {
      await deleteCategory(category);
    }
  }

  /// Busca categoria por ID
  ExpenseCategory? getCategoryById(String id) {
    try {
      return categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obter estatísticas de uma categoria
  Future<CategoryStats?> getCategoryStats(String categoryId) async {
    try {
      return await categoryManagementUseCase.getCategoryStats(categoryId);
    } catch (e) {
      print('Erro ao obter estatísticas da categoria: $e');
      return null;
    }
  }

  /// Filtrar categorias
  List<ExpenseCategory> get filteredCategories {
    var filtered = categories.toList();

    // Filtro por busca
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((category) {
        return category.name.toLowerCase().contains(query) ||
               category.keywords.any((keyword) => keyword.contains(query));
      }).toList();
    }

    // Filtro por tipo (apenas personalizadas)
    if (showOnlyCustom.value) {
      filtered = filtered.where((category) => !category.isDefault).toList();
    }

    return filtered;
  }

  /// Limpar filtros
  void clearFilters() {
    searchQuery.value = '';
    showOnlyCustom.value = false;
  }

  /// Refresh dos dados
  Future<void> refreshData() async {
    await Future.wait([
      loadCategories(),
      loadCategoryUsages(),
    ]);
  }

  /// Validar palavras-chave
  List<String> validateKeywords(List<String> keywords) {
    return categoryManagementUseCase.validateKeywords(keywords);
  }
}


