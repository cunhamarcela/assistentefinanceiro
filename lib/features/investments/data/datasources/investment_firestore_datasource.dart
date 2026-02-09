import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/investment_model.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/logging_service.dart';

/// DataSource para gerenciar investimentos no Firestore
class InvestmentFirestoreDataSource extends GetxService {
  static InvestmentFirestoreDataSource get instance => Get.find<InvestmentFirestoreDataSource>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final AuthService _authService;

  static const String _investmentsCollection = 'investments';

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
    AppLogger.debug(FeatureTag.database, 'InvestmentFirestoreDataSource inicializado');
  }

  /// Obter referência da coleção de investimentos do usuário
  CollectionReference get _userInvestmentsCollection {
    final userId = _authService.currentUser?.id;
    if (userId == null) {
      AppLogger.error(FeatureTag.database, 'Usuário não autenticado no Firestore');
      throw Exception('Usuário não autenticado');
    }
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(_investmentsCollection);
  }

  /// Salvar investimento no Firestore
  Future<void> saveInvestment(InvestmentModel investment) async {
    try {
      AppLogger.debug(FeatureTag.network, 'Salvando investimento no Firestore', data: {
        'id': investment.id,
      });
      
      final collection = _userInvestmentsCollection;
      final data = investment.toFirestore();
      
      await collection.doc(investment.id).set(data);
      
      AppLogger.debug(FeatureTag.sync, 'Investimento salvo no Firestore', data: {'id': investment.id});
    } catch (e) {
      AppLogger.error(FeatureTag.network, 'Erro ao salvar investimento no Firestore', error: e);
      rethrow;
    }
  }

  /// Atualizar investimento no Firestore
  Future<void> updateInvestment(InvestmentModel investment) async {
    try {
      final collection = _userInvestmentsCollection;
      final data = investment.toFirestore();
      
      await collection.doc(investment.id).update(data);
      
      AppLogger.debug(FeatureTag.sync, 'Investimento atualizado no Firestore', data: {'id': investment.id});
    } catch (e) {
      AppLogger.error(FeatureTag.network, 'Erro ao atualizar investimento no Firestore', error: e);
      rethrow;
    }
  }

  /// Deletar investimento do Firestore
  Future<void> deleteInvestment(String id) async {
    try {
      final collection = _userInvestmentsCollection;
      await collection.doc(id).delete();
      
      AppLogger.debug(FeatureTag.sync, 'Investimento deletado do Firestore', data: {'id': id});
    } catch (e) {
      AppLogger.error(FeatureTag.network, 'Erro ao deletar investimento do Firestore', error: e);
      rethrow;
    }
  }

  /// Buscar investimento por ID
  Future<InvestmentModel?> getInvestmentById(String id) async {
    try {
      final collection = _userInvestmentsCollection;
      final doc = await collection.doc(id).get();
      
      if (!doc.exists) return null;
      
      return InvestmentModel.fromFirestore(doc.data()! as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error(FeatureTag.network, 'Erro ao buscar investimento no Firestore', error: e);
      return null;
    }
  }

  /// Buscar todos os investimentos
  Future<List<InvestmentModel>> getAllInvestments() async {
    try {
      final collection = _userInvestmentsCollection;
      final snapshot = await collection.orderBy('date', descending: true).get();
      
      return snapshot.docs
          .map((doc) => InvestmentModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error(FeatureTag.network, 'Erro ao buscar investimentos no Firestore', error: e);
      return [];
    }
  }

  /// Buscar investimentos por período
  Future<List<InvestmentModel>> getInvestmentsByDateRange(DateTime start, DateTime end) async {
    try {
      final collection = _userInvestmentsCollection;
      final snapshot = await collection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => InvestmentModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error(FeatureTag.network, 'Erro ao buscar investimentos por período no Firestore', error: e);
      return [];
    }
  }

  /// Buscar investimentos por tipo
  Future<List<InvestmentModel>> getInvestmentsByType(String type) async {
    try {
      final collection = _userInvestmentsCollection;
      final snapshot = await collection
          .where('type', isEqualTo: type)
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => InvestmentModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error(FeatureTag.network, 'Erro ao buscar investimentos por tipo no Firestore', error: e);
      return [];
    }
  }
}

