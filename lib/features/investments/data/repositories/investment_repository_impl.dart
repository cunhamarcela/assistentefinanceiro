import '../../domain/entities/investment.dart';
import '../../domain/repositories/investment_repository.dart';
import '../datasources/investment_local_datasource.dart';
import '../datasources/investment_firestore_datasource.dart';
import '../models/investment_model.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/logging_service.dart';

/// Repositório híbrido que sincroniza dados entre SQLite local e Firestore
class InvestmentRepositoryImpl implements InvestmentRepository {
  final InvestmentLocalDataSource localDataSource;
  final InvestmentFirestoreDataSource firestoreDataSource;
  final AuthService _authService;

  InvestmentRepositoryImpl({
    required this.localDataSource,
    required this.firestoreDataSource,
    required AuthService authService,
  }) : _authService = authService;

  String get _userId => _authService.currentUser?.id ?? '';

  @override
  Future<void> addInvestment(Investment investment) async {
    final opId = AppLogger.startOp(FeatureTag.expenses, 'add_investment_repo', data: {
      'description': investment.description,
      'amount': investment.amount,
    });
    
    final investmentModel = InvestmentModel.fromEntity(investment, _userId);
    
    try {
      // Salvar localmente primeiro (para funcionar offline)
      AppLogger.debug(FeatureTag.database, 'Salvando investimento localmente');
      await localDataSource.insertInvestment(investmentModel);
      
      AppLogger.saved(FeatureTag.expenses, 'investimento', id: investment.id, data: {
        'source': 'local',
        'amount': investment.amount,
      });
      
      AppLogger.completeOp(opId, message: 'Investimento salvo localmente');
      
      // Salvar no Firestore em background (não bloquear retorno)
      _saveToFirestoreInBackground(investmentModel);
      
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao adicionar investimento', exception: e);
      throw Exception('Erro ao adicionar investimento: $e');
    }
  }

  void _saveToFirestoreInBackground(InvestmentModel investmentModel) {
    Future.delayed(Duration.zero, () async {
      AppLogger.syncStart('investimento', source: 'firestore');
      
      try {
        await firestoreDataSource.saveInvestment(investmentModel);
        AppLogger.syncComplete('investimento', synced: 1);
      } catch (e) {
        AppLogger.syncFail('investimento', 'Firestore indisponível', error: e);
      }
    });
  }

  @override
  Future<void> updateInvestment(Investment investment) async {
    final opId = AppLogger.startOp(FeatureTag.expenses, 'update_investment_repo', data: {
      'id': investment.id,
      'description': investment.description,
    });
    
    final investmentModel = InvestmentModel.fromEntity(investment, _userId);
    
    try {
      await localDataSource.updateInvestment(investmentModel);
      AppLogger.saved(FeatureTag.expenses, 'investimento', id: investment.id, data: {
        'action': 'update',
        'source': 'local',
      });
      
      _updateToFirestoreInBackground(investmentModel);
      AppLogger.completeOp(opId, message: 'Investimento atualizado');
      
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao atualizar investimento', exception: e);
      throw Exception('Erro ao atualizar investimento: $e');
    }
  }

  void _updateToFirestoreInBackground(InvestmentModel investmentModel) {
    Future.delayed(Duration.zero, () async {
      AppLogger.syncStart('investimento_update', source: 'firestore');
      
      try {
        await firestoreDataSource.updateInvestment(investmentModel);
        AppLogger.syncComplete('investimento_update', synced: 1);
      } catch (e) {
        AppLogger.syncFail('investimento_update', 'Firestore indisponível', error: e);
      }
    });
  }

  @override
  Future<void> deleteInvestment(String id) async {
    final opId = AppLogger.startOp(FeatureTag.expenses, 'delete_investment_repo', data: {'id': id});
    
    try {
      await localDataSource.deleteInvestment(id);
      AppLogger.deleted(FeatureTag.expenses, 'investimento', id);
      
      _deleteFromFirestoreInBackground(id);
      AppLogger.completeOp(opId, message: 'Investimento deletado');
      
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao deletar investimento', exception: e);
      throw Exception('Erro ao deletar investimento: $e');
    }
  }
  
  void _deleteFromFirestoreInBackground(String investmentId) {
    Future.delayed(Duration.zero, () async {
      AppLogger.syncStart('investimento_delete', source: 'firestore');
      
      try {
        await firestoreDataSource.deleteInvestment(investmentId);
        AppLogger.syncComplete('investimento_delete', synced: 1);
      } catch (e) {
        AppLogger.syncFail('investimento_delete', 'Firestore indisponível', error: e);
      }
    });
  }

  @override
  Future<Investment?> getInvestmentById(String id) async {
    try {
      final model = await localDataSource.getInvestmentById(id);
      return model?.toEntity();
    } catch (e) {
      AppLogger.error(FeatureTag.database, 'Erro ao buscar investimento', error: e);
      return null;
    }
  }

  @override
  Future<List<Investment>> getAllInvestments() async {
    try {
      final models = await localDataSource.getAllInvestments();
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      AppLogger.error(FeatureTag.database, 'Erro ao buscar investimentos', error: e);
      return [];
    }
  }

  @override
  Future<List<Investment>> getInvestmentsByDateRange(DateTime start, DateTime end) async {
    try {
      final models = await localDataSource.getInvestmentsByDateRange(start, end);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      AppLogger.error(FeatureTag.database, 'Erro ao buscar investimentos por período', error: e);
      return [];
    }
  }

  @override
  Future<List<Investment>> getInvestmentsByType(InvestmentType type) async {
    try {
      final models = await localDataSource.getInvestmentsByType(type.name);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      AppLogger.error(FeatureTag.database, 'Erro ao buscar investimentos por tipo', error: e);
      return [];
    }
  }

  @override
  Future<List<Investment>> getCurrentMonthInvestments() async {
    try {
      final models = await localDataSource.getCurrentMonthInvestments();
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      AppLogger.error(FeatureTag.database, 'Erro ao buscar investimentos do mês', error: e);
      return [];
    }
  }

  @override
  Future<double> getTotalByDateRange(DateTime start, DateTime end) async {
    try {
      return await localDataSource.getTotalByDateRange(start, end);
    } catch (e) {
      AppLogger.error(FeatureTag.database, 'Erro ao calcular total por período', error: e);
      return 0.0;
    }
  }

  @override
  Future<double> getTotalByType(InvestmentType type) async {
    try {
      return await localDataSource.getTotalByType(type.name);
    } catch (e) {
      AppLogger.error(FeatureTag.database, 'Erro ao calcular total por tipo', error: e);
      return 0.0;
    }
  }

  @override
  Future<List<Investment>> searchInvestments(String query) async {
    try {
      final models = await localDataSource.searchInvestments(query);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      AppLogger.error(FeatureTag.database, 'Erro ao buscar investimentos', error: e);
      return [];
    }
  }
}

