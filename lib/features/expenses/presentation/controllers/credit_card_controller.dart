import 'package:get/get.dart';
import '../../domain/entities/credit_card.dart';
import '../../domain/usecases/add_credit_card_usecase.dart';
import '../../domain/usecases/delete_credit_card_usecase.dart';
import '../../domain/usecases/get_credit_cards_usecase.dart';
import '../../domain/usecases/update_credit_card_usecase.dart';

/// Controller para gerenciar cartões de crédito
class CreditCardController extends GetxController {
  final AddCreditCardUseCase _addCreditCardUseCase;
  final GetCreditCardsUseCase _getCreditCardsUseCase;
  final UpdateCreditCardUseCase _updateCreditCardUseCase;
  final DeleteCreditCardUseCase _deleteCreditCardUseCase;

  CreditCardController(
    this._addCreditCardUseCase,
    this._getCreditCardsUseCase,
    this._updateCreditCardUseCase,
    this._deleteCreditCardUseCase,
  );

  // Estado
  final creditCards = <CreditCard>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadCreditCards();
  }

  /// Carrega todos os cartões ativos
  Future<void> loadCreditCards() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final cards = await _getCreditCardsUseCase.getActiveCards();
      creditCards.value = cards;
    } catch (e) {
      errorMessage.value = 'Erro ao carregar cartões: $e';
      Get.snackbar(
        'Erro',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Adiciona um novo cartão
  Future<void> addCreditCard({
    required String name,
    required String lastFourDigits,
    required int closingDay,
    required int dueDay,
    double? limit,
    String? flag,
    String? color,
  }) async {
    try {
      print('💳 [CreditCardController] Iniciando adição de cartão...');
      isLoading.value = true;
      errorMessage.value = '';

      print('💳 [CreditCardController] Chamando use case...');
      await _addCreditCardUseCase(
        name: name,
        lastFourDigits: lastFourDigits,
        closingDay: closingDay,
        dueDay: dueDay,
        limit: limit,
        flag: flag,
        color: color,
      );

      print('💳 [CreditCardController] Cartão adicionado com sucesso!');
      
      // IMPORTANTE: Fechar a tela ANTES de recarregar a lista
      // Isso evita problemas de navegação causados por rebuilds
      print('💳 [CreditCardController] Voltando para tela anterior...');
      Get.back(); // Fecha o formulário PRIMEIRO
      print('💳 [CreditCardController] Get.back() executado!');
      
      // Mostra snackbar após fechar
      Get.snackbar(
        'Sucesso',
        'Cartão adicionado com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      // Recarrega a lista em background (a tela já fechou)
      print('💳 [CreditCardController] Recarregando lista em background...');
      loadCreditCards(); // Sem await - não bloqueia
      print('💳 [CreditCardController] ✅ Operação concluída!');
    } catch (e, stackTrace) {
      print('❌ [CreditCardController] Erro ao adicionar cartão: $e');
      print('❌ [CreditCardController] Stack trace: $stackTrace');
      errorMessage.value = 'Erro ao adicionar cartão: $e';
      Get.snackbar(
        'Erro',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Atualiza um cartão existente
  Future<void> updateCreditCard({
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
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _updateCreditCardUseCase(
        id: id,
        name: name,
        lastFourDigits: lastFourDigits,
        closingDay: closingDay,
        dueDay: dueDay,
        limit: limit,
        flag: flag,
        color: color,
        isActive: isActive,
      );

      await loadCreditCards();

      Get.snackbar(
        'Sucesso',
        'Cartão atualizado com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
      );

      Get.back(); // Fecha o formulário
    } catch (e) {
      errorMessage.value = 'Erro ao atualizar cartão: $e';
      Get.snackbar(
        'Erro',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Deleta um cartão (soft delete)
  Future<void> deleteCreditCard(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _deleteCreditCardUseCase(id);
      await loadCreditCards();

      Get.snackbar(
        'Sucesso',
        'Cartão removido com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      errorMessage.value = 'Erro ao deletar cartão: $e';
      Get.snackbar(
        'Erro',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Deleta permanentemente um cartão
  Future<void> permanentlyDeleteCreditCard(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _deleteCreditCardUseCase.permanently(id);
      await loadCreditCards();

      Get.snackbar(
        'Sucesso',
        'Cartão deletado permanentemente!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      errorMessage.value = 'Erro ao deletar permanentemente cartão: $e';
      Get.snackbar(
        'Erro',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Busca um cartão por ID
  CreditCard? getCardById(String id) {
    try {
      return creditCards.firstWhere((card) => card.id == id);
    } catch (e) {
      return null;
    }
  }
}

