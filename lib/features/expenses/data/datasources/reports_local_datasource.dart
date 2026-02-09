import 'package:collection/collection.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:get/get.dart';
import '../../domain/entities/insight_report.dart';
import '../../domain/entities/category.dart';
import '../../../auth/data/services/auth_service.dart';
import '../datasources/expense_local_datasource.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';

/// Interface para data source local de relatórios
abstract class ReportsLocalDataSource {
  Future<InsightReport> generateCategorySpendingReport({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<InsightReport> generateSpendingTrendReport({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<InsightReport> generateMonthlyComparisonReport({
    required String userId,
    required int monthsToCompare,
  });
  Future<Map<String, dynamic>> calculatePeriodStats({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<List<ChartPoint>> calculateCategoryChartData({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<List<ChartPoint>> calculateTrendChartData({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required String groupBy,
  });
  Future<List<ChartPoint>> calculateComparisonChartData({
    required String userId,
    required List<DateTime> periods,
    required String groupBy,
  });
  Future<void> saveReport(InsightReport report);
  Future<InsightReport?> getReport(String reportId);
  Future<List<InsightReport>> getUserReports(String userId);
  Future<void> deleteReport(String reportId);
}

/// Implementação do data source local usando SQLite
class ReportsLocalDataSourceImpl implements ReportsLocalDataSource {
  final ExpenseLocalDataSource _expenseDataSource;
  
  ReportsLocalDataSourceImpl({required ExpenseLocalDataSource expenseDataSource})
      : _expenseDataSource = expenseDataSource;
  
  static Database? _database;
  static const String _databaseName = 'reports.db';
  static const int _databaseVersion = 1;
  static const String _reportsTable = 'reports';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_reportsTable (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        periodStart INTEGER NOT NULL,
        periodEnd INTEGER NOT NULL,
        chartData TEXT NOT NULL,
        summary TEXT NOT NULL,
        recommendations TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_reports_userId ON $_reportsTable (userId)');
    await db.execute('CREATE INDEX idx_reports_createdAt ON $_reportsTable (createdAt DESC)');
  }

  /// Obter userId atual
  String get _currentUserId {
    try {
      final authService = Get.find<AuthService>();
      final userId = authService.currentUser?.id;
      if (userId == null || userId.isEmpty) {
        throw Exception('Usuário não autenticado');
      }
      return userId;
    } catch (e) {
      print('❌ Erro ao obter userId nos relatórios: $e');
      rethrow;
    }
  }

  @override
  Future<InsightReport> generateCategorySpendingReport({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Buscar despesas do período
      final expenses = await _getExpensesForPeriod(userId, startDate, endDate);
      final categories = await _getCategories(userId);
      
      // Calcular dados por categoria
      final categoryTotals = <String, double>{};
      final categoryNames = <String, String>{};
      
      for (final expense in expenses) {
        final category = _findCategoryById(expense.categoryId, categories);
        final categoryName = category?.name ?? _getCategoryNameFromId(expense.categoryId);
        
        categoryTotals[expense.categoryId] = 
            (categoryTotals[expense.categoryId] ?? 0.0) + expense.amount;
        categoryNames[expense.categoryId] = categoryName;
      }

      // Criar pontos do gráfico
      final chartData = categoryTotals.entries.map((entry) {
        return ChartPoint(
          label: categoryNames[entry.key] ?? 'Outros',
          value: entry.value,
        );
      }).toList();

      // Ordenar por valor (maior primeiro)
      chartData.sort((a, b) => b.value.compareTo(a.value));

      // Calcular estatísticas
      final totalAmount = expenses.fold<double>(0, (sum, e) => sum + e.amount);
      final transactionCount = expenses.length;
      final daysDifference = endDate.difference(startDate).inDays + 1;
      final dailyAverage = daysDifference > 0 ? totalAmount / daysDifference : 0.0;

      final summary = {
        'total_amount': totalAmount,
        'transaction_count': transactionCount,
        'daily_average': dailyAverage,
        'period_days': daysDifference,
        'top_category': chartData.isNotEmpty ? chartData.first.label : null,
        'top_category_amount': chartData.isNotEmpty ? chartData.first.value : 0.0,
        'categories_count': chartData.length,
      };

      return InsightReport.categorySpending(
        periodStart: startDate,
        periodEnd: endDate,
        chartData: chartData,
        summary: summary,
        userId: userId,
      );
    } catch (e) {
      print('❌ Erro ao gerar relatório de categorias: $e');
      throw Exception('Erro ao gerar relatório de categorias: $e');
    }
  }

  @override
  Future<InsightReport> generateSpendingTrendReport({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final expenses = await _getExpensesForPeriod(userId, startDate, endDate);
      
      // Agrupar por dia/semana dependendo do período
      final daysDifference = endDate.difference(startDate).inDays;
      final groupBy = daysDifference > 30 ? 'week' : 'day';
      
      final trendData = <String, double>{};
      
      for (final expense in expenses) {
        String key;
        if (groupBy == 'week') {
          final weekStart = expense.date.subtract(Duration(days: expense.date.weekday - 1));
          key = '${weekStart.day}/${weekStart.month}';
        } else {
          key = '${expense.date.day}/${expense.date.month}';
        }
        
        trendData[key] = (trendData[key] ?? 0.0) + expense.amount;
      }

      // Criar pontos do gráfico ordenados por data
      final chartData = trendData.entries.map((entry) {
        return ChartPoint(
          label: entry.key,
          value: entry.value,
        );
      }).toList();

      // Calcular estatísticas
      final totalAmount = expenses.fold<double>(0, (sum, e) => sum + e.amount);
      final transactionCount = expenses.length;
      final dailyAverage = daysDifference > 0 ? totalAmount / daysDifference : 0.0;

      // Calcular tendência (simples: comparar primeira e última semana/dia)
      double trend = 0.0;
      if (chartData.length >= 2) {
        trend = chartData.last.value - chartData.first.value;
      }

      final summary = {
        'total_amount': totalAmount,
        'transaction_count': transactionCount,
        'daily_average': dailyAverage,
        'trend': trend,
        'trend_percentage': chartData.isNotEmpty && chartData.first.value > 0 
            ? (trend / chartData.first.value) * 100 
            : 0.0,
        'group_by': groupBy,
      };

      return InsightReport.spendingTrend(
        periodStart: startDate,
        periodEnd: endDate,
        chartData: chartData,
        summary: summary,
        userId: userId,
      );
    } catch (e) {
      print('❌ Erro ao gerar relatório de tendência: $e');
      throw Exception('Erro ao gerar relatório de tendência: $e');
    }
  }

  @override
  Future<InsightReport> generateMonthlyComparisonReport({
    required String userId,
    required int monthsToCompare,
  }) async {
    try {
      final now = DateTime.now();
      final chartData = <ChartPoint>[];
      final monthlyTotals = <String, double>{};

      for (int i = monthsToCompare - 1; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final startOfMonth = DateTime(monthDate.year, monthDate.month, 1);
        final endOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);
        
        final expenses = await _getExpensesForPeriod(userId, startOfMonth, endOfMonth);
        final monthTotal = expenses.fold<double>(0, (sum, e) => sum + e.amount);
        
        final monthLabel = _getMonthLabel(monthDate);
        monthlyTotals[monthLabel] = monthTotal;
        
        chartData.add(ChartPoint(
          label: monthLabel,
          value: monthTotal,
        ));
      }

      // Calcular estatísticas
      final totalAmount = monthlyTotals.values.fold<double>(0, (sum, amount) => sum + amount);
      final averageMonthly = monthsToCompare > 0 ? totalAmount / monthsToCompare : 0.0;
      final maxMonth = chartData.isNotEmpty 
          ? chartData.reduce((a, b) => a.value > b.value ? a : b)
          : null;
      final minMonth = chartData.isNotEmpty 
          ? chartData.reduce((a, b) => a.value < b.value ? a : b)
          : null;

      final summary = {
        'total_amount': totalAmount,
        'average_monthly': averageMonthly,
        'months_compared': monthsToCompare,
        'max_month': maxMonth?.label,
        'max_month_amount': maxMonth?.value ?? 0.0,
        'min_month': minMonth?.label,
        'min_month_amount': minMonth?.value ?? 0.0,
      };

      final startDate = DateTime(now.year, now.month - monthsToCompare + 1, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      return InsightReport.monthlyComparison(
        periodStart: startDate,
        periodEnd: endDate,
        chartData: chartData,
        summary: summary,
        userId: userId,
      );
    } catch (e) {
      print('❌ Erro ao gerar relatório de comparação: $e');
      throw Exception('Erro ao gerar relatório de comparação: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> calculatePeriodStats({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final expenses = await _getExpensesForPeriod(userId, startDate, endDate);
      
      final totalAmount = expenses.fold<double>(0, (sum, e) => sum + e.amount);
      final transactionCount = expenses.length;
      final daysDifference = endDate.difference(startDate).inDays + 1;
      final dailyAverage = daysDifference > 0 ? totalAmount / daysDifference : 0.0;

      // Calcular por categoria
      final categoryTotals = <String, double>{};
      for (final expense in expenses) {
        categoryTotals[expense.categoryId] = 
            (categoryTotals[expense.categoryId] ?? 0.0) + expense.amount;
      }

      final topCategoryId = categoryTotals.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      return {
        'total_amount': totalAmount,
        'transaction_count': transactionCount,
        'daily_average': dailyAverage,
        'period_days': daysDifference,
        'top_category_id': topCategoryId,
        'top_category_amount': categoryTotals[topCategoryId] ?? 0.0,
        'categories_count': categoryTotals.length,
      };
    } catch (e) {
      print('❌ Erro ao calcular estatísticas do período: $e');
      return {};
    }
  }

  @override
  Future<List<ChartPoint>> calculateCategoryChartData({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final report = await generateCategorySpendingReport(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
      return report.chartData;
    } catch (e) {
      print('❌ Erro ao calcular dados do gráfico de categorias: $e');
      return [];
    }
  }

  @override
  Future<List<ChartPoint>> calculateTrendChartData({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required String groupBy,
  }) async {
    try {
      final report = await generateSpendingTrendReport(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
      return report.chartData;
    } catch (e) {
      print('❌ Erro ao calcular dados do gráfico de tendência: $e');
      return [];
    }
  }

  @override
  Future<List<ChartPoint>> calculateComparisonChartData({
    required String userId,
    required List<DateTime> periods,
    required String groupBy,
  }) async {
    try {
      final report = await generateMonthlyComparisonReport(
        userId: userId,
        monthsToCompare: periods.length,
      );
      return report.chartData;
    } catch (e) {
      print('❌ Erro ao calcular dados do gráfico de comparação: $e');
      return [];
    }
  }

  @override
  Future<void> saveReport(InsightReport report) async {
    try {
      final db = await database;
      
      await db.insert(
        _reportsTable,
        {
          'id': report.id,
          'userId': report.userId ?? _currentUserId,
          'title': report.title,
          'description': report.description,
          'type': report.type.name,
          'createdAt': report.createdAt.millisecondsSinceEpoch,
          'periodStart': report.periodStart.millisecondsSinceEpoch,
          'periodEnd': report.periodEnd.millisecondsSinceEpoch,
          'chartData': _encodeChartData(report.chartData),
          'summary': _encodeJson(report.summary),
          'recommendations': _encodeRecommendations(report.recommendations),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('✅ Relatório salvo: ${report.id}');
    } catch (e) {
      print('❌ Erro ao salvar relatório: $e');
      throw Exception('Erro ao salvar relatório: $e');
    }
  }

  @override
  Future<InsightReport?> getReport(String reportId) async {
    try {
      final db = await database;
      
      final result = await db.query(
        _reportsTable,
        where: 'id = ?',
        whereArgs: [reportId],
      );

      if (result.isEmpty) return null;

      return _parseReportFromDb(result.first);
    } catch (e) {
      print('❌ Erro ao buscar relatório: $e');
      return null;
    }
  }

  @override
  Future<List<InsightReport>> getUserReports(String userId) async {
    try {
      final db = await database;
      
      final result = await db.query(
        _reportsTable,
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'createdAt DESC',
      );

      return result.map((data) => _parseReportFromDb(data)).toList();
    } catch (e) {
      print('❌ Erro ao buscar relatórios do usuário: $e');
      return [];
    }
  }

  @override
  Future<void> deleteReport(String reportId) async {
    try {
      final db = await database;
      
      await db.delete(
        _reportsTable,
        where: 'id = ?',
        whereArgs: [reportId],
      );

      print('✅ Relatório deletado: $reportId');
    } catch (e) {
      print('❌ Erro ao deletar relatório: $e');
      throw Exception('Erro ao deletar relatório: $e');
    }
  }

  // Métodos auxiliares
  Future<List<ExpenseModel>> _getExpensesForPeriod(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      print('📊 [Reports] Buscando despesas do período:');
      print('   - UserId: $userId');
      print('   - StartDate: $startDate (${startDate.millisecondsSinceEpoch})');
      print('   - EndDate: $endDate (${endDate.millisecondsSinceEpoch})');
      
      final db = await _expenseDataSource.database;
      
      final result = await db.query(
        'expenses',
        where: 'userId = ? AND date >= ? AND date <= ?',
        whereArgs: [
          userId,
          startDate.millisecondsSinceEpoch,
          endDate.millisecondsSinceEpoch,
        ],
        orderBy: 'date ASC',
      );

      print('📊 [Reports] Despesas encontradas: ${result.length}');
      if (result.isNotEmpty) {
        for (var i = 0; i < result.length && i < 3; i++) {
          final expense = result[i];
          print('   - Despesa $i: ${expense['description']} - R\$ ${expense['amount']} - Date: ${expense['date']}');
        }
      }

      final expenses = result.map((data) => ExpenseModel.fromSQLite(data)).toList();
      return expenses;
    } catch (e) {
      print('❌ Erro ao buscar despesas do período: $e');
      return [];
    }
  }

  Future<List<CategoryModel>> _getCategories(String userId) async {
    try {
      final db = await _expenseDataSource.database;
      
      final result = await db.query(
        'categories',
        where: 'userId = ?',
        whereArgs: [userId],
      );

      return result.map((data) => CategoryModel.fromSQLite(data)).toList();
    } catch (e) {
      print('❌ Erro ao buscar categorias: $e');
      return [];
    }
  }

  String _getMonthLabel(DateTime date) {
    const months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return months[date.month - 1];
  }

  InsightReport _parseReportFromDb(Map<String, dynamic> data) {
    return InsightReport(
      id: data['id'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      type: _parseReportType(data['type'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
      periodStart: DateTime.fromMillisecondsSinceEpoch(data['periodStart'] as int),
      periodEnd: DateTime.fromMillisecondsSinceEpoch(data['periodEnd'] as int),
      chartData: _decodeChartData(data['chartData'] as String),
      summary: _decodeJson(data['summary'] as String),
      recommendations: _decodeRecommendations(data['recommendations'] as String),
      userId: data['userId'] as String?,
    );
  }

  InsightReportType _parseReportType(String type) {
    switch (type) {
      case 'categorySpending':
        return InsightReportType.categorySpending;
      case 'spendingTrend':
        return InsightReportType.spendingTrend;
      case 'monthlyComparison':
        return InsightReportType.monthlyComparison;
      case 'weeklyAnalysis':
        return InsightReportType.weeklyAnalysis;
      case 'budgetProgress':
        return InsightReportType.budgetProgress;
      default:
        return InsightReportType.categorySpending;
    }
  }

  // Métodos de serialização
  String _encodeChartData(List<ChartPoint> data) {
    return data.map((point) => '${point.label}:${point.value}').join('|');
  }

  List<ChartPoint> _decodeChartData(String data) {
    if (data.isEmpty) return [];
    
    return data.split('|').map((item) {
      final parts = item.split(':');
      return ChartPoint(
        label: parts[0],
        value: double.tryParse(parts[1]) ?? 0.0,
      );
    }).toList();
  }

  String _encodeJson(Map<String, dynamic> data) {
    try {
      // Converter para string JSON simples
      final entries = data.entries.map((e) => '${e.key}:${e.value}').join(',');
      return entries;
    } catch (e) {
      print('❌ Erro ao codificar JSON: $e');
      return '';
    }
  }

  Map<String, dynamic> _decodeJson(String data) {
    try {
      if (data.isEmpty) return {};
      
      final result = <String, dynamic>{};
      final entries = data.split(',');
      
      for (final entry in entries) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          final key = parts[0];
          final valueStr = parts[1];
          
          // Tentar converter para double, senão manter como string
          final value = double.tryParse(valueStr) ?? valueStr;
          result[key] = value;
        }
      }
      
      return result;
    } catch (e) {
      print('❌ Erro ao decodificar JSON: $e');
      return {};
    }
  }

  String _encodeRecommendations(List<InsightRecommendation> recommendations) {
    try {
      return recommendations.map((rec) => 
        '${rec.title}|${rec.description}|${rec.priority.name}|${rec.actionText ?? ''}'
      ).join('###');
    } catch (e) {
      print('❌ Erro ao codificar recomendações: $e');
      return '';
    }
  }

  List<InsightRecommendation> _decodeRecommendations(String data) {
    try {
      if (data.isEmpty) return [];
      
      return data.split('###').map((item) {
        final parts = item.split('|');
        if (parts.length >= 3) {
          return InsightRecommendation(
            id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
            title: parts[0],
            description: parts[1],
            priority: _parseRecommendationPriority(parts[2]),
            actionText: parts.length > 3 && parts[3].isNotEmpty ? parts[3] : null,
          );
        }
        return null;
      }).whereType<InsightRecommendation>().toList();
    } catch (e) {
      print('❌ Erro ao decodificar recomendações: $e');
      return [];
    }
  }

  InsightRecommendationPriority _parseRecommendationPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return InsightRecommendationPriority.high;
      case 'medium':
        return InsightRecommendationPriority.medium;
      case 'low':
        return InsightRecommendationPriority.low;
      default:
        return InsightRecommendationPriority.medium;
    }
  }
  
  /// Busca categoria por ID com fallback para IDs sem sufixo do usuário
  ExpenseCategory? _findCategoryById(String categoryId, List<ExpenseCategory> categories) {
    if (categoryId.isEmpty || categories.isEmpty) return null;
    
    // 1. Tentar match exato
    final exactMatch = categories.firstWhereOrNull((cat) => cat.id == categoryId);
    if (exactMatch != null) return exactMatch;
    
    // 2. Tentar match onde o ID da categoria começa com o categoryId buscado
    final startsWithMatch = categories.firstWhereOrNull(
      (cat) => cat.id.startsWith('${categoryId}_')
    );
    if (startsWithMatch != null) return startsWithMatch;
    
    // 3. Tentar match onde o categoryId começa com o ID base da categoria
    final reverseMatch = categories.firstWhereOrNull(
      (cat) => categoryId.startsWith('${cat.id}_')
    );
    if (reverseMatch != null) return reverseMatch;
    
    // 4. Extrair ID base e tentar match
    final baseId = _extractBaseCategoryId(categoryId);
    if (baseId != categoryId) {
      return categories.firstWhereOrNull(
        (cat) => cat.id == baseId || 
                 cat.id.startsWith('${baseId}_') ||
                 _extractBaseCategoryId(cat.id) == baseId
      );
    }
    
    return null;
  }
  
  /// Extrai o ID base de uma categoria removendo o sufixo do usuário
  String _extractBaseCategoryId(String categoryId) {
    final defaultIds = [
      'alimentacao', 'transporte', 'saude', 'contas', 'lazer',
      'casa', 'educacao', 'roupas', 'tecnologia', 'pets', 'outros', 'investimentos'
    ];
    
    for (final baseId in defaultIds) {
      if (categoryId == baseId || categoryId.startsWith('${baseId}_')) {
        return baseId;
      }
    }
    return categoryId;
  }
  
  /// Obtém o nome da categoria a partir do ID base
  String _getCategoryNameFromId(String categoryId) {
    final baseId = _extractBaseCategoryId(categoryId);
    
    final categoryNames = {
      'alimentacao': 'Alimentação',
      'transporte': 'Transporte',
      'saude': 'Saúde',
      'contas': 'Contas',
      'lazer': 'Lazer',
      'casa': 'Casa',
      'educacao': 'Educação',
      'roupas': 'Roupas e Beleza',
      'tecnologia': 'Tecnologia',
      'pets': 'Pets',
      'outros': 'Outros',
      'investimentos': 'Investimentos',
    };
    
    return categoryNames[baseId] ?? 'Outros';
  }
}
