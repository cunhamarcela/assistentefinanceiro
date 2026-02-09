import '../../domain/entities/expense.dart';
import '../../domain/entities/installment_info.dart';

/// Serviço para gerenciar parcelamento de despesas
class InstallmentService {
  /// Cria múltiplas despesas a partir de uma compra parcelada
  /// 
  /// [expense] - A despesa original com informações de parcelamento
  /// Retorna uma lista de despesas, uma para cada parcela
  static List<Expense> createInstallmentExpenses(Expense expense) {
    if (!expense.isInstallment) {
      // Se não é parcelada, retorna apenas a despesa original
      return [expense];
    }

    final installmentInfo = expense.installmentInfo!;
    final expenses = <Expense>[];

    // Criar uma despesa para cada parcela
    for (int i = 1; i <= installmentInfo.totalInstallments; i++) {
      // Calcular a data da parcela (mês + i-1)
      final installmentDate = DateTime(
        expense.date.year,
        expense.date.month + (i - 1),
        expense.date.day,
      );

      // Criar a parcela
      final installment = expense.copyWith(
        id: '${expense.id}_installment_$i',
        date: installmentDate,
        amount: installmentInfo.installmentAmount,
        description: '${expense.description} (${i}/${installmentInfo.totalInstallments})',
        installmentInfo: InstallmentInfo(
          currentInstallment: i,
          totalInstallments: installmentInfo.totalInstallments,
          totalAmount: installmentInfo.totalAmount,
          installmentAmount: installmentInfo.installmentAmount,
          interestRate: installmentInfo.interestRate,
          parentExpenseId: expense.id, // Referência à despesa original
        ),
      );

      expenses.add(installment);
    }

    return expenses;
  }

  /// Calcula o valor de cada parcela com base no total e número de parcelas
  /// 
  /// [totalAmount] - Valor total da compra
  /// [totalInstallments] - Número de parcelas
  /// [interestRate] - Taxa de juros (opcional, padrão 0)
  /// Retorna o valor de cada parcela
  static double calculateInstallmentAmount({
    required double totalAmount,
    required int totalInstallments,
    double interestRate = 0,
  }) {
    if (totalInstallments <= 1) {
      return totalAmount;
    }

    if (interestRate == 0) {
      // Sem juros, divide igualmente
      return totalAmount / totalInstallments;
    }

    // Com juros, usa a fórmula de juros compostos
    // PMT = PV * (i * (1 + i)^n) / ((1 + i)^n - 1)
    final i = interestRate / 100; // Taxa de juros mensal
    final n = totalInstallments.toDouble();
    
    final installmentAmount = totalAmount * 
        (i * pow(1 + i, n)) / 
        (pow(1 + i, n) - 1);

    return double.parse(installmentAmount.toStringAsFixed(2));
  }

  /// Calcula o total de juros pagos
  static double calculateTotalInterest({
    required double totalAmount,
    required double installmentAmount,
    required int totalInstallments,
  }) {
    final totalPaid = installmentAmount * totalInstallments;
    return totalPaid - totalAmount;
  }

  /// Verifica se uma data de parcela já passou
  static bool isInstallmentDue(DateTime installmentDate) {
    final now = DateTime.now();
    return installmentDate.isBefore(DateTime(now.year, now.month, now.day + 1));
  }

  /// Retorna as parcelas que vencem em um determinado mês
  static List<Expense> getInstallmentsForMonth(
    List<Expense> allExpenses,
    int year,
    int month,
  ) {
    return allExpenses.where((expense) {
      return expense.isInstallmentPart &&
             expense.date.year == year &&
             expense.date.month == month;
    }).toList();
  }

  /// Calcula o total de parcelas para um mês específico
  static double calculateMonthlyInstallmentsTotal(
    List<Expense> allExpenses,
    int year,
    int month,
  ) {
    final monthInstallments = getInstallmentsForMonth(allExpenses, year, month);
    return monthInstallments.fold(0, (sum, expense) => sum + expense.amount);
  }

  /// Agrupa despesas parceladas pela despesa original
  static Map<String, List<Expense>> groupByParentExpense(List<Expense> expenses) {
    final grouped = <String, List<Expense>>{};

    for (final expense in expenses) {
      if (expense.isInstallmentPart) {
        final parentId = expense.installmentInfo!.parentExpenseId!;
        grouped.putIfAbsent(parentId, () => []);
        grouped[parentId]!.add(expense);
      }
    }

    return grouped;
  }

  /// Calcula quanto falta pagar de uma compra parcelada
  static double calculateRemainingAmount(
    List<Expense> installments,
    DateTime currentDate,
  ) {
    final remainingInstallments = installments.where((expense) {
      return expense.date.isAfter(currentDate);
    });

    return remainingInstallments.fold(0, (sum, expense) => sum + expense.amount);
  }

  /// Retorna informações resumidas sobre as parcelas de um cartão
  static Map<String, dynamic> getCreditCardInstallmentsSummary(
    List<Expense> allExpenses,
    String creditCardId,
    int year,
    int month,
  ) {
    final cardInstallments = allExpenses.where((expense) {
      return expense.creditCardId == creditCardId &&
             expense.isInstallment &&
             expense.date.year == year &&
             expense.date.month == month;
    }).toList();

    final total = cardInstallments.fold(0.0, (sum, expense) => sum + expense.amount);
    final count = cardInstallments.length;

    return {
      'total': total,
      'count': count,
      'installments': cardInstallments,
    };
  }
}

/// Função auxiliar para calcular potência (pow)
double pow(double base, double exponent) {
  if (exponent == 0) return 1;
  if (exponent == 1) return base;
  
  double result = 1;
  for (int i = 0; i < exponent.toInt(); i++) {
    result *= base;
  }
  return result;
}

