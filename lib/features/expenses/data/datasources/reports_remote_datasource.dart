import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../domain/entities/insight_report.dart';
import '../../../auth/data/services/auth_service.dart';

/// Interface para data source remoto de relatórios
abstract class ReportsRemoteDataSource {
  Future<void> syncReport(InsightReport report);
  Future<InsightReport?> getReport(String reportId);
  Future<List<InsightReport>> getUserReports(String userId);
  Future<void> deleteReport(String reportId);
  Future<List<InsightRecommendation>> analyzeSpendingPatterns({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<Map<String, dynamic>> compareWithPreviousPeriod({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<Map<String, dynamic>> calculateSpendingProjections({
    required String userId,
    required int daysToProject,
  });
  Future<List<Map<String, dynamic>>> getRealTimeInsights(String userId);
}

/// Implementação do data source remoto usando Firestore
class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      print('❌ Erro ao obter userId nos relatórios remotos: $e');
      rethrow;
    }
  }

  /// Coleção de relatórios do usuário
  CollectionReference get _reportsCollection =>
      _firestore.collection('users').doc(_currentUserId).collection('reports');

  /// Coleção de insights do usuário
  CollectionReference get _insightsCollection =>
      _firestore.collection('users').doc(_currentUserId).collection('insights');

  @override
  Future<void> syncReport(InsightReport report) async {
    try {
      await _reportsCollection.doc(report.id).set({
        'title': report.title,
        'description': report.description,
        'type': report.type.name,
        'created_at': FieldValue.serverTimestamp(),
        'period_start': Timestamp.fromDate(report.periodStart),
        'period_end': Timestamp.fromDate(report.periodEnd),
        'chart_data': _encodeChartData(report.chartData),
        'summary': report.summary,
        'recommendations': _encodeRecommendations(report.recommendations),
        'user_id': report.userId ?? _currentUserId,
      });

      print('✅ Relatório sincronizado com Firestore: ${report.id}');
    } catch (e) {
      print('❌ Erro ao sincronizar relatório: $e');
      throw Exception('Erro ao sincronizar relatório: $e');
    }
  }

  @override
  Future<InsightReport?> getReport(String reportId) async {
    try {
      final doc = await _reportsCollection.doc(reportId).get();
      
      if (!doc.exists) return null;

      return _parseReportFromFirestore(doc.data() as Map<String, dynamic>, reportId);
    } catch (e) {
      print('❌ Erro ao buscar relatório no Firestore: $e');
      return null;
    }
  }

  @override
  Future<List<InsightReport>> getUserReports(String userId) async {
    try {
      final query = await _reportsCollection
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      return query.docs.map((doc) {
        return _parseReportFromFirestore(
          doc.data() as Map<String, dynamic>, 
          doc.id,
        );
      }).toList();
    } catch (e) {
      print('❌ Erro ao buscar relatórios do usuário no Firestore: $e');
      return [];
    }
  }

  @override
  Future<void> deleteReport(String reportId) async {
    try {
      await _reportsCollection.doc(reportId).delete();
      print('✅ Relatório deletado do Firestore: $reportId');
    } catch (e) {
      print('❌ Erro ao deletar relatório do Firestore: $e');
      throw Exception('Erro ao deletar relatório: $e');
    }
  }

  @override
  Future<List<InsightRecommendation>> analyzeSpendingPatterns({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Simular análise de padrões de gastos
      await Future.delayed(const Duration(milliseconds: 800));

      final recommendations = <InsightRecommendation>[];

      // Recomendação baseada em categoria dominante
      recommendations.add(InsightRecommendation(
        id: 'pattern_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Padrão de Gastos Identificado',
        description: 'Seus gastos com alimentação representam 40% do total. '
                    'Considere planejar refeições para reduzir custos.',
        priority: InsightRecommendationPriority.medium,
        actionText: 'Ver Dicas de Economia',
        actionData: {'category': 'alimentacao', 'percentage': 40},
      ));

      // Recomendação baseada em tendência
      recommendations.add(InsightRecommendation(
        id: 'trend_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Tendência de Aumento',
        description: 'Seus gastos aumentaram 15% em relação ao mês anterior. '
                    'Revise suas despesas não essenciais.',
        priority: InsightRecommendationPriority.high,
        actionText: 'Criar Meta de Economia',
        actionData: {'increase_percentage': 15},
      ));

      // Recomendação baseada em sazonalidade
      recommendations.add(InsightRecommendation(
        id: 'seasonal_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Oportunidade Sazonal',
        description: 'Este é um bom momento para revisar assinaturas e serviços. '
                    'Muitas empresas oferecem descontos no final do ano.',
        priority: InsightRecommendationPriority.low,
        actionText: 'Ver Assinaturas',
        actionData: {'season': 'end_of_year'},
      ));

      return recommendations;
    } catch (e) {
      print('❌ Erro ao analisar padrões de gastos: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> compareWithPreviousPeriod({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Simular comparação com período anterior
      await Future.delayed(const Duration(milliseconds: 600));

      final periodDays = endDate.difference(startDate).inDays;
      final previousStart = startDate.subtract(Duration(days: periodDays));
      final previousEnd = startDate.subtract(const Duration(days: 1));

      // Dados simulados
      final currentTotal = 2500.0;
      final previousTotal = 2200.0;
      final difference = currentTotal - previousTotal;
      final percentageChange = (difference / previousTotal) * 100;

      return {
        'current_period': {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'total_amount': currentTotal,
          'transaction_count': 45,
        },
        'previous_period': {
          'start_date': previousStart.toIso8601String(),
          'end_date': previousEnd.toIso8601String(),
          'total_amount': previousTotal,
          'transaction_count': 38,
        },
        'comparison': {
          'absolute_difference': difference,
          'percentage_change': percentageChange,
          'trend': difference > 0 ? 'increase' : 'decrease',
          'is_significant': percentageChange.abs() > 10,
        },
        'insights': [
          if (percentageChange > 15)
            'Aumento significativo nos gastos. Revise categorias não essenciais.',
          if (percentageChange < -15)
            'Ótima redução nos gastos! Continue assim.',
          if (percentageChange.abs() < 5)
            'Gastos estáveis em relação ao período anterior.',
        ],
      };
    } catch (e) {
      print('❌ Erro ao comparar com período anterior: $e');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> calculateSpendingProjections({
    required String userId,
    required int daysToProject,
  }) async {
    try {
      // Simular cálculo de projeções
      await Future.delayed(const Duration(milliseconds: 700));

      // Dados simulados baseados em tendência histórica
      final dailyAverage = 85.0;
      final projectedTotal = dailyAverage * daysToProject;
      final confidence = 0.75; // 75% de confiança

      return {
        'projection_period_days': daysToProject,
        'daily_average': dailyAverage,
        'projected_total': projectedTotal,
        'confidence_level': confidence,
        'projection_range': {
          'min': projectedTotal * 0.8,
          'max': projectedTotal * 1.2,
        },
        'category_projections': {
          'alimentacao': projectedTotal * 0.35,
          'transporte': projectedTotal * 0.25,
          'lazer': projectedTotal * 0.20,
          'saude': projectedTotal * 0.10,
          'outros': projectedTotal * 0.10,
        },
        'recommendations': [
          'Baseado no seu histórico, você pode gastar cerca de R\$ ${projectedTotal.toStringAsFixed(2)} nos próximos $daysToProject dias.',
          'Para economizar, foque em reduzir gastos com alimentação e transporte.',
          'Considere definir um limite diário de R\$ ${(dailyAverage * 0.9).toStringAsFixed(2)} para ficar abaixo da média.',
        ],
      };
    } catch (e) {
      print('❌ Erro ao calcular projeções: $e');
      return {};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRealTimeInsights(String userId) async {
    try {
      // Simular insights em tempo real
      await Future.delayed(const Duration(milliseconds: 400));

      final now = DateTime.now();
      final insights = <Map<String, dynamic>>[];

      // Insight de gasto do dia
      insights.add({
        'id': 'daily_spending_${now.millisecondsSinceEpoch}',
        'type': 'daily_spending',
        'title': 'Gastos de Hoje',
        'message': 'Você já gastou R\$ 120,00 hoje. Sua média diária é R\$ 85,00.',
        'priority': 'medium',
        'action': 'view_today_expenses',
        'data': {
          'today_amount': 120.0,
          'daily_average': 85.0,
          'percentage_above_average': 41.2,
        },
      });

      // Insight de categoria em alta
      insights.add({
        'id': 'category_alert_${now.millisecondsSinceEpoch}',
        'type': 'category_alert',
        'title': 'Alimentação em Alta',
        'message': 'Seus gastos com alimentação aumentaram 25% esta semana.',
        'priority': 'high',
        'action': 'view_category_details',
        'data': {
          'category': 'alimentacao',
          'increase_percentage': 25.0,
          'current_amount': 450.0,
          'previous_amount': 360.0,
        },
      });

      // Insight de meta
      insights.add({
        'id': 'goal_progress_${now.millisecondsSinceEpoch}',
        'type': 'goal_progress',
        'title': 'Meta Mensal',
        'message': 'Você está 80% dentro da sua meta mensal. Parabéns!',
        'priority': 'low',
        'action': 'view_goals',
        'data': {
          'goal_name': 'Orçamento Mensal',
          'progress_percentage': 80.0,
          'spent_amount': 2000.0,
          'goal_amount': 2500.0,
        },
      });

      return insights;
    } catch (e) {
      print('❌ Erro ao buscar insights em tempo real: $e');
      return [];
    }
  }

  // Métodos auxiliares
  InsightReport _parseReportFromFirestore(Map<String, dynamic> data, String id) {
    return InsightReport(
      id: id,
      title: data['title'] as String,
      description: data['description'] as String,
      type: _parseReportType(data['type'] as String),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      periodStart: (data['period_start'] as Timestamp).toDate(),
      periodEnd: (data['period_end'] as Timestamp).toDate(),
      chartData: _decodeChartData(data['chart_data'] as List<dynamic>? ?? []),
      summary: Map<String, dynamic>.from(data['summary'] as Map? ?? {}),
      recommendations: _decodeRecommendations(data['recommendations'] as List<dynamic>? ?? []),
      userId: data['user_id'] as String?,
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

  List<dynamic> _encodeChartData(List<ChartPoint> data) {
    return data.map((point) => {
      'label': point.label,
      'value': point.value,
      'color': point.color,
      'metadata': point.metadata,
    }).toList();
  }

  List<ChartPoint> _decodeChartData(List<dynamic> data) {
    return data.map((item) {
      final map = item as Map<String, dynamic>;
      return ChartPoint(
        label: map['label'] as String,
        value: (map['value'] as num).toDouble(),
        color: map['color'] as String?,
        metadata: map['metadata'] as Map<String, dynamic>?,
      );
    }).toList();
  }

  List<dynamic> _encodeRecommendations(List<InsightRecommendation> recommendations) {
    return recommendations.map((rec) => {
      'id': rec.id,
      'title': rec.title,
      'description': rec.description,
      'priority': rec.priority.name,
      'action_text': rec.actionText,
      'action_data': rec.actionData,
    }).toList();
  }

  List<InsightRecommendation> _decodeRecommendations(List<dynamic> data) {
    return data.map((item) {
      final map = item as Map<String, dynamic>;
      return InsightRecommendation(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        priority: _parseRecommendationPriority(map['priority'] as String),
        actionText: map['action_text'] as String?,
        actionData: map['action_data'] as Map<String, dynamic>?,
      );
    }).toList();
  }

  InsightRecommendationPriority _parseRecommendationPriority(String priority) {
    switch (priority) {
      case 'low':
        return InsightRecommendationPriority.low;
      case 'medium':
        return InsightRecommendationPriority.medium;
      case 'high':
        return InsightRecommendationPriority.high;
      case 'critical':
        return InsightRecommendationPriority.critical;
      default:
        return InsightRecommendationPriority.medium;
    }
  }
}
