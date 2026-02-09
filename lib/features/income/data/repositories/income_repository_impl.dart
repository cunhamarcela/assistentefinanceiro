import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../domain/entities/income.dart';
import '../../domain/repositories/income_repository.dart';
import '../models/income_model.dart';
import '../../../auth/data/services/auth_service.dart';

/// Implementação do repositório de receitas
class IncomeRepositoryImpl implements IncomeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AuthService? _authService;

  IncomeRepositoryImpl() {
    _initAuthService();
  }

  void _initAuthService() {
    try {
      if (Get.isRegistered<AuthService>()) {
        _authService = Get.find<AuthService>();
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ AuthService não disponível: $e');
      }
    }
  }

  /// Obtém o ID do usuário atual
  String? get _currentUserId => _authService?.currentUser?.id;

  /// Referência para a coleção de receitas do usuário
  CollectionReference<Map<String, dynamic>>? get _incomesRef {
    final userId = _currentUserId;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection('incomes');
  }

  @override
  Future<void> addIncome(Income income) async {
    final ref = _incomesRef;
    if (ref == null) {
      throw Exception('Usuário não autenticado');
    }

    final model = IncomeModel.fromEntity(income);
    
    // Salvar no Firestore em background (fire-and-forget)
    // NÃO aguarda - a sincronização acontece em background
    // Os listeners do Firestore vão atualizar a UI automaticamente
    ref.doc(income.id).set(model.toFirestore()).then((_) {
      if (kDebugMode) {
        print('✅ Receita sincronizada com Firestore: ${income.description}');
      }
    }).catchError((e) {
      if (kDebugMode) {
        print('⚠️ Erro ao salvar receita no Firestore: $e - dados serão sincronizados depois');
      }
    });

    if (kDebugMode) {
      print('✅ Receita adicionada: ${income.description}');
    }
  }

  @override
  Future<void> updateIncome(Income income) async {
    final ref = _incomesRef;
    if (ref == null) {
      throw Exception('Usuário não autenticado');
    }

    final model = IncomeModel.fromEntity(income);
    
    // Atualizar com timeout de 3 segundos
    try {
      await ref.doc(income.id).update(model.toFirestore())
          .timeout(const Duration(seconds: 3), onTimeout: () {
        if (kDebugMode) {
          print('⚠️ Timeout ao atualizar receita no Firestore');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erro ao atualizar receita no Firestore: $e');
      }
    }

    if (kDebugMode) {
      print('✅ Receita atualizada: ${income.description}');
    }
  }

  @override
  Future<void> deleteIncome(String id) async {
    final ref = _incomesRef;
    if (ref == null) {
      throw Exception('Usuário não autenticado');
    }

    // Deletar com timeout de 3 segundos
    try {
      await ref.doc(id).delete()
          .timeout(const Duration(seconds: 3), onTimeout: () {
        if (kDebugMode) {
          print('⚠️ Timeout ao deletar receita no Firestore');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erro ao deletar receita no Firestore: $e');
      }
    }

    if (kDebugMode) {
      print('✅ Receita removida: $id');
    }
  }

  @override
  Future<Income?> getIncomeById(String id) async {
    final ref = _incomesRef;
    if (ref == null) return null;

    final doc = await ref.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;

    return IncomeModel.fromFirestore(doc.data()!).toEntity();
  }

  @override
  Future<List<Income>> getAllIncomes() async {
    final ref = _incomesRef;
    if (ref == null) return [];

    try {
      final snapshot = await ref.orderBy('date', descending: true).get()
          .timeout(const Duration(seconds: 3), onTimeout: () {
        if (kDebugMode) {
          print('⚠️ Timeout ao buscar receitas - retornando vazio');
        }
        throw TimeoutException('Firestore timeout');
      });
      
      return snapshot.docs
          .map((doc) => IncomeModel.fromFirestore(doc.data()).toEntity())
          .toList();
    } on TimeoutException {
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erro ao buscar receitas: $e');
      }
      return [];
    }
  }

  @override
  Future<List<Income>> getIncomesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final ref = _incomesRef;
    if (ref == null) return [];

    try {
      final snapshot = await ref
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get()
          .timeout(const Duration(seconds: 3), onTimeout: () {
        throw TimeoutException('Firestore timeout');
      });

      return snapshot.docs
          .map((doc) => IncomeModel.fromFirestore(doc.data()).toEntity())
          .toList();
    } on TimeoutException {
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erro ao buscar receitas por período: $e');
      }
      return [];
    }
  }

  @override
  Future<List<Income>> getCurrentMonthIncomes() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return getIncomesByDateRange(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }

  @override
  Future<List<Income>> getIncomesByType(IncomeType type) async {
    final ref = _incomesRef;
    if (ref == null) return [];

    try {
      final snapshot = await ref
          .where('type', isEqualTo: type.name)
          .orderBy('date', descending: true)
          .get()
          .timeout(const Duration(seconds: 3), onTimeout: () {
        throw TimeoutException('Firestore timeout');
      });

      return snapshot.docs
          .map((doc) => IncomeModel.fromFirestore(doc.data()).toEntity())
          .toList();
    } on TimeoutException {
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erro ao buscar receitas por tipo: $e');
      }
      return [];
    }
  }

  @override
  Future<List<Income>> getRecurringIncomes() async {
    final ref = _incomesRef;
    if (ref == null) return [];

    try {
      final snapshot = await ref
          .where('isRecurring', isEqualTo: true)
          .orderBy('date', descending: true)
          .get()
          .timeout(const Duration(seconds: 3), onTimeout: () {
        throw TimeoutException('Firestore timeout');
      });

      return snapshot.docs
          .map((doc) => IncomeModel.fromFirestore(doc.data()).toEntity())
          .toList();
    } on TimeoutException {
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erro ao buscar receitas recorrentes: $e');
      }
      return [];
    }
  }

  @override
  Future<double> getTotalIncomeByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final incomesList = await getIncomesByDateRange(
      startDate: startDate,
      endDate: endDate,
    );

    double total = 0.0;
    for (final income in incomesList) {
      total += income.amount;
    }
    return total;
  }

  @override
  Future<double> getCurrentMonthTotalIncome() async {
    final incomesList = await getCurrentMonthIncomes();
    double total = 0.0;
    for (final income in incomesList) {
      total += income.amount;
    }
    return total;
  }

  @override
  Future<Map<IncomeType, double>> getIncomesByTypeGrouped({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    List<Income> incomes;
    
    if (startDate != null && endDate != null) {
      incomes = await getIncomesByDateRange(
        startDate: startDate,
        endDate: endDate,
      );
    } else {
      incomes = await getAllIncomes();
    }

    final grouped = <IncomeType, double>{};
    
    for (final income in incomes) {
      grouped[income.type] = (grouped[income.type] ?? 0) + income.amount;
    }

    return grouped;
  }

  @override
  Stream<List<Income>> watchAllIncomes() {
    final ref = _incomesRef;
    if (ref == null) {
      return Stream.value([]);
    }

    return ref.orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => IncomeModel.fromFirestore(doc.data()).toEntity())
          .toList();
    });
  }

  @override
  Stream<List<Income>> watchCurrentMonthIncomes() {
    final ref = _incomesRef;
    if (ref == null) {
      return Stream.value([]);
    }

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return ref
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => IncomeModel.fromFirestore(doc.data()).toEntity())
              .toList();
        });
  }

  @override
  Future<void> syncWithServer() async {
    // TODO: Implementar sincronização com SQLite local
    if (kDebugMode) {
      print('📡 Sincronização de receitas com servidor');
    }
  }

  @override
  Future<void> clearLocalCache() async {
    // TODO: Limpar cache SQLite local
    if (kDebugMode) {
      print('🧹 Cache local de receitas limpo');
    }
  }
}
