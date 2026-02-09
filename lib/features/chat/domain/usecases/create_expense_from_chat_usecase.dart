import 'package:get/get.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/entities/category.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../data/services/expense_parser_service.dart';

/// Resultado da criação de despesa via chat
class CreateExpenseFromChatResult {
  final bool success;
  final Expense? expense;
  final ExpenseParseResult parseResult;
  final String message;
  final bool needsConfirmation;
  final String? confirmationId;

  const CreateExpenseFromChatResult({
    required this.success,
    this.expense,
    required this.parseResult,
    required this.message,
    this.needsConfirmation = false,
    this.confirmationId,
  });

  factory CreateExpenseFromChatResult.needsConfirmation({
    required ExpenseParseResult parseResult,
    required String confirmationId,
  }) {
    return CreateExpenseFromChatResult(
      success: false,
      parseResult: parseResult,
      message: parseResult.summaryMessage + '\n\nConfirmar esse gasto?',
      needsConfirmation: true,
      confirmationId: confirmationId,
    );
  }

  factory CreateExpenseFromChatResult.created({
    required Expense expense,
    required ExpenseParseResult parseResult,
  }) {
    return CreateExpenseFromChatResult(
      success: true,
      expense: expense,
      parseResult: parseResult,
      message: '✅ Gasto registrado com sucesso!\n\n'
               '• ${expense.description}\n'
               '• Valor: R\$ ${expense.amount.toStringAsFixed(2)}\n'
               '• Data: ${_formatDate(expense.date)}',
    );
  }

  factory CreateExpenseFromChatResult.failed({
    required ExpenseParseResult parseResult,
    required String errorMessage,
  }) {
    return CreateExpenseFromChatResult(
      success: false,
      parseResult: parseResult,
      message: '❌ Não foi possível registrar o gasto.\n\n$errorMessage',
    );
  }

  factory CreateExpenseFromChatResult.notExpenseRequest() {
    return CreateExpenseFromChatResult(
      success: false,
      parseResult: ExpenseParseResult.empty(),
      message: '',
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Caso de uso para criar despesas a partir de mensagens do chat
class CreateExpenseFromChatUseCase {
  final ExpenseRepository _expenseRepository;
  final ExpenseParserService _parserService;

  // Cache de confirmações pendentes
  final Map<String, ExpenseParseResult> _pendingConfirmations = {};

  CreateExpenseFromChatUseCase({
    required ExpenseRepository expenseRepository,
    required ExpenseParserService parserService,
  })  : _expenseRepository = expenseRepository,
        _parserService = parserService;

  /// Processa uma mensagem do chat e tenta criar uma despesa
  Future<CreateExpenseFromChatResult> call({
    required String message,
    required List<ExpenseCategory> categories,
    String? defaultCategoryId,
    bool autoConfirm = false,
  }) async {
    try {
      // Atualiza categorias no parser
      _parserService.updateCategories(categories);

      // Faz o parsing da mensagem
      final parseResult = await _parserService.parseMessage(message);

      // Se não é um pedido de registro de gasto, retorna vazio
      if (!parseResult.isExpenseRequest) {
        return CreateExpenseFromChatResult.notExpenseRequest();
      }

      // Se não conseguiu extrair dados válidos
      if (!parseResult.isValid) {
        return CreateExpenseFromChatResult.failed(
          parseResult: parseResult,
          errorMessage: parseResult.errorMessage ?? 
              'Não foi possível identificar os dados do gasto. '
              'Por favor, informe o valor e uma descrição.',
        );
      }

      // Se precisa de confirmação e não é auto-confirm
      if (parseResult.needsConfirmation && !autoConfirm) {
        final confirmationId = DateTime.now().millisecondsSinceEpoch.toString();
        _pendingConfirmations[confirmationId] = parseResult;
        
        return CreateExpenseFromChatResult.needsConfirmation(
          parseResult: parseResult,
          confirmationId: confirmationId,
        );
      }

      // Cria a despesa
      final expense = await _createExpense(
        parseResult: parseResult,
        categories: categories,
        defaultCategoryId: defaultCategoryId,
      );

      return CreateExpenseFromChatResult.created(
        expense: expense,
        parseResult: parseResult,
      );
    } catch (e) {
      return CreateExpenseFromChatResult.failed(
        parseResult: ExpenseParseResult.empty(),
        errorMessage: 'Erro ao processar: $e',
      );
    }
  }

  /// Confirma uma despesa pendente
  Future<CreateExpenseFromChatResult> confirmPending({
    required String confirmationId,
    required List<ExpenseCategory> categories,
    String? defaultCategoryId,
  }) async {
    final parseResult = _pendingConfirmations[confirmationId];
    if (parseResult == null) {
      return CreateExpenseFromChatResult.failed(
        parseResult: ExpenseParseResult.empty(),
        errorMessage: 'Confirmação expirada. Por favor, tente novamente.',
      );
    }

    try {
      final expense = await _createExpense(
        parseResult: parseResult,
        categories: categories,
        defaultCategoryId: defaultCategoryId,
      );

      _pendingConfirmations.remove(confirmationId);

      return CreateExpenseFromChatResult.created(
        expense: expense,
        parseResult: parseResult,
      );
    } catch (e) {
      return CreateExpenseFromChatResult.failed(
        parseResult: parseResult,
        errorMessage: 'Erro ao criar despesa: $e',
      );
    }
  }

  /// Cancela uma confirmação pendente
  void cancelPending(String confirmationId) {
    _pendingConfirmations.remove(confirmationId);
  }

  /// Cria a despesa no repositório
  Future<Expense> _createExpense({
    required ExpenseParseResult parseResult,
    required List<ExpenseCategory> categories,
    String? defaultCategoryId,
  }) async {
    // Determina a categoria
    String categoryId;
    if (parseResult.categoryId != null) {
      categoryId = parseResult.categoryId!;
    } else if (parseResult.categoryName != null) {
      final matchedCategory = categories.firstWhereOrNull(
        (c) => c.name.toLowerCase() == parseResult.categoryName!.toLowerCase(),
      );
      categoryId = matchedCategory?.id ?? defaultCategoryId ?? _getDefaultCategoryId(categories);
    } else {
      categoryId = defaultCategoryId ?? _getDefaultCategoryId(categories);
    }

    // Cria o modelo de despesa
    final expenseModel = ExpenseModel.create(
      amount: parseResult.amount!,
      description: parseResult.description ?? 'Gasto registrado via chat',
      categoryId: categoryId,
      date: parseResult.date ?? DateTime.now(),
      notes: parseResult.notes,
      paymentType: parseResult.paymentType ?? PaymentType.cash,
      source: ExpenseSource.aiAssistant,
      aiParsedData: parseResult.rawParsedData,
      aiConfidence: parseResult.confidence,
    );

    // Salva no repositório
    await _expenseRepository.addExpense(expenseModel);

    return expenseModel.toEntity();
  }

  /// Obtém ID da categoria padrão "Outros"
  String _getDefaultCategoryId(List<ExpenseCategory> categories) {
    final othersCategory = categories.firstWhereOrNull(
      (c) => c.name.toLowerCase() == 'outros' || c.name.toLowerCase() == 'other',
    );
    return othersCategory?.id ?? categories.first.id;
  }

  /// Verifica se uma mensagem parece ser um pedido de registro de gasto
  bool looksLikeExpenseRequest(String message) {
    final lowerMessage = message.toLowerCase();
    final keywords = [
      'gastei', 'comprei', 'paguei', 'registrar', 'adicionar',
      'anotar', 'lançar', 'gasto', 'despesa', 'custou', 'foi', 'deu',
    ];
    return keywords.any((kw) => lowerMessage.contains(kw));
  }
}

