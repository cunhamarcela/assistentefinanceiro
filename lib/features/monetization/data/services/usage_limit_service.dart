import 'dart:io' show File, FileMode;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/usage_limit.dart';
import '../../domain/entities/feature_unlock.dart';
import '../models/usage_limit_model.dart';
import '../models/feature_unlock_model.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../../core/services/analytics_service.dart';

// #region agent log
void _debugLogUsage(String hypothesisId, String location, String message, Map<String, dynamic> data) {
  try {
    final logEntry = '{"hypothesisId":"$hypothesisId","location":"$location","message":"$message","data":${data.toString().replaceAll("'", '"')},"timestamp":${DateTime.now().millisecondsSinceEpoch},"sessionId":"debug-usage"}\n';
    File('/Users/marcelacunha/meus_apps/assistente_financeiro/.cursor/debug.log').writeAsStringSync(logEntry, mode: FileMode.append);
  } catch (e) { /* ignore */ }
}
// #endregion

/// Resultado da verificação de uso
class UsageCheckResult {
  final bool canUse;
  final int remaining;
  final int dailyLimit;
  final String message;
  final bool hasUnlock;
  final FeatureUnlock? activeUnlock;

  const UsageCheckResult({
    required this.canUse,
    required this.remaining,
    required this.dailyLimit,
    required this.message,
    this.hasUnlock = false,
    this.activeUnlock,
  });

  factory UsageCheckResult.allowed({
    required int remaining,
    required int dailyLimit,
    FeatureUnlock? unlock,
  }) {
    return UsageCheckResult(
      canUse: true,
      remaining: remaining,
      dailyLimit: dailyLimit,
      message: unlock != null 
          ? 'Acesso desbloqueado! ${unlock.timeRemainingFormatted} restantes.'
          : '$remaining de $dailyLimit usos restantes hoje.',
      hasUnlock: unlock != null,
      activeUnlock: unlock,
    );
  }

  factory UsageCheckResult.denied({
    required int dailyLimit,
    required String reason,
  }) {
    return UsageCheckResult(
      canUse: false,
      remaining: 0,
      dailyLimit: dailyLimit,
      message: reason,
    );
  }
}

/// Serviço para gerenciar limites de uso e desbloqueios
class UsageLimitService extends GetxService {
  static UsageLimitService get instance => Get.find<UsageLimitService>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AuthService? _authService;
  AnalyticsService? _analyticsService;

  // Cache local de limites e desbloqueios
  final RxMap<FeatureType, UsageLimit> _usageLimits = <FeatureType, UsageLimit>{}.obs;
  final RxMap<FeatureType, FeatureUnlock?> _activeUnlocks = <FeatureType, FeatureUnlock?>{}.obs;

  // Estado de carregamento
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      if (Get.isRegistered<AuthService>()) {
        _authService = Get.find<AuthService>();
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ AuthService não disponível: $e');
      }
    }
    
    // Inicializa analytics
    try {
      _analyticsService = AnalyticsService.instance;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ AnalyticsService não disponível: $e');
      }
    }
  }

  /// Obtém o ID do usuário atual
  String? get _currentUserId => _authService?.currentUser?.id;

  /// Referência para a coleção de limites de uso do usuário
  CollectionReference<Map<String, dynamic>>? get _usageLimitsRef {
    final userId = _currentUserId;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection('ai_usage');
  }

  /// Referência para a coleção de desbloqueios do usuário
  CollectionReference<Map<String, dynamic>>? get _unlocksRef {
    final userId = _currentUserId;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection('feature_unlocks');
  }

  /// Carrega todos os limites e desbloqueios do usuário
  Future<void> loadUserData() async {
    final userId = _currentUserId;
    // #region agent log
    _debugLogUsage('H4', 'usage_limit_service.dart:loadUserData:entry', 'Iniciando carregamento de dados', {'userId': userId ?? 'null', 'hasAuthService': _authService != null});
    // #endregion
    
    if (userId == null) {
      // #region agent log
      _debugLogUsage('H4', 'usage_limit_service.dart:loadUserData:no_user', 'Usuario nao autenticado', {'reason': 'userId is null'});
      // #endregion
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Carrega limites de uso
      await _loadUsageLimits();

      // Carrega desbloqueios ativos
      await _loadActiveUnlocks();

      // #region agent log
      _debugLogUsage('H4', 'usage_limit_service.dart:loadUserData:success', 'Dados carregados com sucesso', {'limitsCount': _usageLimits.length, 'unlocksCount': _activeUnlocks.values.where((u) => u != null).length, 'limitKeys': _usageLimits.keys.map((k) => k.name).toList().toString()});
      // #endregion

      if (kDebugMode) {
        print('✅ UsageLimitService: dados carregados');
        print('   Limites: ${_usageLimits.length}');
        print('   Desbloqueios ativos: ${_activeUnlocks.values.where((u) => u != null).length}');
      }
    } catch (e) {
      // #region agent log
      _debugLogUsage('H4', 'usage_limit_service.dart:loadUserData:error', 'Erro ao carregar dados', {'error': e.toString()});
      // #endregion
      errorMessage.value = 'Erro ao carregar dados de uso: $e';
      if (kDebugMode) {
        print('❌ Erro ao carregar dados de uso: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Carrega limites de uso do Firestore
  Future<void> _loadUsageLimits() async {
    final ref = _usageLimitsRef;
    if (ref == null) return;

    final snapshot = await ref.get();
    
    for (final doc in snapshot.docs) {
      try {
        final model = UsageLimitModel.fromFirestore(doc.data());
        _usageLimits[model.featureType] = model.toEntity();
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Erro ao parsear limite: $e');
        }
      }
    }
  }

  /// Carrega desbloqueios ativos do Firestore
  Future<void> _loadActiveUnlocks() async {
    final ref = _unlocksRef;
    if (ref == null) return;

    final now = DateTime.now();
    final snapshot = await ref
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
        .get();

    // Limpa desbloqueios expirados
    _activeUnlocks.clear();

    for (final doc in snapshot.docs) {
      try {
        final model = FeatureUnlockModel.fromFirestore(doc.data());
        final unlock = model.toEntity();
        
        if (unlock.isActive) {
          _activeUnlocks[unlock.featureType] = unlock;
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Erro ao parsear desbloqueio: $e');
        }
      }
    }
  }

  /// Verifica se o usuário pode usar uma feature
  Future<UsageCheckResult> checkUsage(FeatureType featureType) async {
    // #region agent log
    _debugLogUsage('H4', 'usage_limit_service.dart:checkUsage:entry', 'checkUsage chamado', {'featureType': featureType.name, 'activeUnlocksKeys': _activeUnlocks.keys.map((k) => k.name).toList().toString()});
    // #endregion
    
    final userId = _currentUserId;
    if (userId == null) {
      // #region agent log
      _debugLogUsage('H4', 'usage_limit_service.dart:checkUsage:noUser', 'userId null - denied', {});
      // #endregion
      return UsageCheckResult.denied(
        dailyLimit: featureType.defaultDailyLimit,
        reason: 'Usuário não autenticado',
      );
    }

    // Verifica se há desbloqueio ativo
    final unlock = _activeUnlocks[featureType];
    // #region agent log
    _debugLogUsage('H4', 'usage_limit_service.dart:checkUsage:unlockCheck', 'Verificando unlock no cache', {'unlockNull': unlock == null, 'unlockIsActive': unlock?.isActive, 'unlockExpiresAt': unlock?.expiresAt.toIso8601String()});
    // #endregion
    
    if (unlock != null && unlock.isActive) {
      // #region agent log
      _debugLogUsage('H4', 'usage_limit_service.dart:checkUsage:hasActiveUnlock', 'TEM UNLOCK ATIVO - retornando allowed com 999', {'unlockId': unlock.id});
      // #endregion
      return UsageCheckResult.allowed(
        remaining: 999, // Ilimitado durante desbloqueio
        dailyLimit: featureType.defaultDailyLimit,
        unlock: unlock,
      );
    }

    // Obtém ou cria limite de uso
    var limit = _usageLimits[featureType];
    if (limit == null) {
      limit = await _getOrCreateLimit(featureType);
    }

    // Verifica se precisa resetar (novo dia)
    if (limit.needsReset) {
      limit = limit.resetDaily();
      await _saveLimit(limit);
      _usageLimits[featureType] = limit;
    }

    // Verifica se pode usar
    if (limit.canUse) {
      // Rastreia aviso de limite se próximo do limite
      if (limit.isNearLimit || limit.isLastUse) {
        _analyticsService?.trackLimitWarningShown(
          featureType: featureType.name,
          remaining: limit.remainingToday,
        );
      }
      
      return UsageCheckResult.allowed(
        remaining: limit.remainingToday,
        dailyLimit: limit.dailyLimit,
      );
    } else {
      // Rastreia limite atingido
      _analyticsService?.trackLimitReached(
        featureType: featureType.name,
        dailyLimit: limit.dailyLimit,
        sessionCount: _analyticsService?.sessionCount,
      );
      
      return UsageCheckResult.denied(
        dailyLimit: limit.dailyLimit,
        reason: 'Limite diário atingido. Assista um anúncio para desbloquear mais!',
      );
    }
  }

  /// Registra o uso de uma feature
  Future<bool> recordUsage(FeatureType featureType) async {
    // #region agent log
    _debugLogUsage('H2', 'usage_limit_service.dart:recordUsage:entry', 'recordUsage chamado', {'featureType': featureType.name, 'currentCacheLimit': _usageLimits[featureType]?.usedToday});
    // #endregion
    
    final checkResult = await checkUsage(featureType);
    
    // #region agent log
    _debugLogUsage('H5', 'usage_limit_service.dart:recordUsage:checkResult', 'checkUsage resultado', {'canUse': checkResult.canUse, 'hasUnlock': checkResult.hasUnlock, 'remaining': checkResult.remaining});
    // #endregion
    
    if (!checkResult.canUse) {
      // #region agent log
      _debugLogUsage('H5', 'usage_limit_service.dart:recordUsage:cannotUse', 'checkUsage retornou canUse=false', {'reason': checkResult.message});
      // #endregion
      return false;
    }

    // Se tem desbloqueio ativo, não precisa decrementar
    if (checkResult.hasUnlock) {
      // #region agent log
      _debugLogUsage('H5', 'usage_limit_service.dart:recordUsage:hasUnlock', 'Tem desbloqueio ativo - não decrementa', {});
      // #endregion
      return true;
    }

    try {
      var limit = _usageLimits[featureType];
      // #region agent log
      _debugLogUsage('H3', 'usage_limit_service.dart:recordUsage:beforeIncrement', 'Antes de incrementar', {'limitNull': limit == null, 'usedBefore': limit?.usedToday, 'remainingBefore': limit?.remainingToday});
      // #endregion
      
      if (limit == null) {
        limit = await _getOrCreateLimit(featureType);
        // #region agent log
        _debugLogUsage('H3', 'usage_limit_service.dart:recordUsage:createdLimit', 'Limite criado/obtido', {'usedToday': limit.usedToday, 'dailyLimit': limit.dailyLimit});
        // #endregion
      }

      // Incrementa o uso
      limit = limit.incrementUsage();
      // #region agent log
      _debugLogUsage('H3', 'usage_limit_service.dart:recordUsage:afterIncrement', 'Após incrementar', {'usedAfter': limit.usedToday, 'remainingAfter': limit.remainingToday});
      // #endregion
      
      // IMPORTANTE: Atualiza cache ANTES de tentar salvar no Firestore
      // Assim o limite local está correto mesmo se Firestore estiver offline
      _usageLimits[featureType] = limit;
      
      // #region agent log
      _debugLogUsage('H3', 'usage_limit_service.dart:recordUsage:cacheUpdated', 'Cache local atualizado', {'cacheUsed': _usageLimits[featureType]?.usedToday});
      // #endregion
      
      // Tenta salvar no Firestore (com timeout, não bloqueia se offline)
      await _saveLimit(limit);
      
      // #region agent log
      _debugLogUsage('H3', 'usage_limit_service.dart:recordUsage:saved', 'Processo de salvar concluído', {'finalUsed': limit.usedToday, 'cacheUsed': _usageLimits[featureType]?.usedToday});
      // #endregion

      if (kDebugMode) {
        print('📊 Uso registrado: ${featureType.name} - ${limit.usedToday}/${limit.dailyLimit}');
      }

      return true;
    } catch (e) {
      // #region agent log
      _debugLogUsage('H2', 'usage_limit_service.dart:recordUsage:error', 'Erro ao registrar uso', {'error': e.toString()});
      // #endregion
      if (kDebugMode) {
        print('❌ Erro ao registrar uso: $e');
      }
      return false;
    }
  }

  /// Obtém ou cria um limite de uso
  Future<UsageLimit> _getOrCreateLimit(FeatureType featureType) async {
    final userId = _currentUserId;
    // #region agent log
    _debugLogUsage('H3', 'usage_limit_service.dart:_getOrCreateLimit:entry', 'Obtendo/criando limite', {'featureType': featureType.name, 'userId': userId ?? 'null'});
    // #endregion
    
    if (userId == null) {
      // #region agent log
      _debugLogUsage('H3', 'usage_limit_service.dart:_getOrCreateLimit:noUser', 'Usuário null - criando limite vazio', {});
      // #endregion
      return UsageLimit.create(userId: '', featureType: featureType);
    }

    // Tenta buscar do Firestore
    final ref = _usageLimitsRef;
    // #region agent log
    _debugLogUsage('H3', 'usage_limit_service.dart:_getOrCreateLimit:refCheck', 'Verificando ref do Firestore', {'refNull': ref == null});
    // #endregion
    
    if (ref != null) {
      try {
        final doc = await ref.doc(featureType.name).get();
        if (doc.exists && doc.data() != null) {
          final model = UsageLimitModel.fromFirestore(doc.data()!);
          // #region agent log
          _debugLogUsage('H3', 'usage_limit_service.dart:_getOrCreateLimit:found', 'Limite encontrado no Firestore', {'usedToday': model.usedToday});
          // #endregion
          return model.toEntity();
        }
      } catch (e) {
        // #region agent log
        _debugLogUsage('H3', 'usage_limit_service.dart:_getOrCreateLimit:firestoreError', 'Erro ao buscar do Firestore', {'error': e.toString()});
        // #endregion
      }
    }

    // Cria novo limite
    // #region agent log
    _debugLogUsage('H3', 'usage_limit_service.dart:_getOrCreateLimit:creating', 'Criando novo limite', {'userId': userId});
    // #endregion
    final newLimit = UsageLimit.create(userId: userId, featureType: featureType);
    await _saveLimit(newLimit);
    return newLimit;
  }

  /// Salva um limite no Firestore (com timeout para não travar o app)
  Future<void> _saveLimit(UsageLimit limit) async {
    final ref = _usageLimitsRef;
    // #region agent log
    _debugLogUsage('H3', 'usage_limit_service.dart:_saveLimit:entry', 'Salvando limite', {'refNull': ref == null, 'usedToday': limit.usedToday, 'featureType': limit.featureType.name});
    // #endregion
    
    if (ref == null) {
      // #region agent log
      _debugLogUsage('H3', 'usage_limit_service.dart:_saveLimit:refNull', 'Ref é null - NÃO SALVA NO FIRESTORE', {});
      // #endregion
      return;
    }

    try {
      final model = UsageLimitModel.fromEntity(limit);
      // Adiciona timeout de 2 segundos para não travar o app se Firestore estiver indisponível
      await ref.doc(limit.featureType.name).set(model.toFirestore()).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          // #region agent log
          _debugLogUsage('H3', 'usage_limit_service.dart:_saveLimit:timeout', 'Timeout ao salvar no Firestore', {'usedToday': limit.usedToday});
          // #endregion
          if (kDebugMode) {
            print('⏱️ Timeout ao salvar limite no Firestore - continuando offline');
          }
        },
      );
      // #region agent log
      _debugLogUsage('H3', 'usage_limit_service.dart:_saveLimit:success', 'Salvo no Firestore com sucesso', {'usedToday': limit.usedToday});
      // #endregion
    } catch (e) {
      // #region agent log
      _debugLogUsage('H3', 'usage_limit_service.dart:_saveLimit:error', 'Erro ao salvar no Firestore', {'error': e.toString()});
      // #endregion
      if (kDebugMode) {
        print('⚠️ Erro ao salvar limite no Firestore: $e');
      }
    }
  }

  /// Registra um desbloqueio por Rewarded Ad
  Future<FeatureUnlock?> unlockFeatureFromAd({
    required FeatureType featureType,
    required String adUnitId,
    int durationHours = 24,
  }) async {
    // #region agent log
    _debugLogUsage('H1', 'usage_limit_service.dart:unlockFeatureFromAd:entry', 'unlockFeatureFromAd CHAMADO', {'featureType': featureType.name, 'adUnitId': adUnitId, 'durationHours': durationHours});
    // #endregion
    
    final userId = _currentUserId;
    if (userId == null) {
      // #region agent log
      _debugLogUsage('H1', 'usage_limit_service.dart:unlockFeatureFromAd:noUser', 'userId é NULL - retornando null', {});
      // #endregion
      return null;
    }

    try {
      // #region agent log
      _debugLogUsage('H1', 'usage_limit_service.dart:unlockFeatureFromAd:creatingUnlock', 'Criando objeto FeatureUnlock', {'userId': userId});
      // #endregion
      
      final unlock = FeatureUnlock.fromRewardedAd(
        userId: userId,
        featureType: featureType,
        adUnitId: adUnitId,
        durationHours: durationHours,
      );
      
      // #region agent log
      _debugLogUsage('H1', 'usage_limit_service.dart:unlockFeatureFromAd:unlockCreated', 'Unlock criado', {'unlockId': unlock.id, 'expiresAt': unlock.expiresAt.toIso8601String(), 'isActive': unlock.isActive});
      // #endregion

      // Salva no Firestore
      final ref = _unlocksRef;
      // #region agent log
      _debugLogUsage('H1', 'usage_limit_service.dart:unlockFeatureFromAd:savingFirestore', 'Salvando no Firestore', {'refNull': ref == null});
      // #endregion
      
      if (ref != null) {
        final model = FeatureUnlockModel.fromEntity(unlock);
        await ref.doc(unlock.id).set(model.toFirestore());
        // #region agent log
        _debugLogUsage('H1', 'usage_limit_service.dart:unlockFeatureFromAd:firestoreSaved', 'Salvo no Firestore com sucesso', {});
        // #endregion
      }

      // Atualiza cache local
      _activeUnlocks[featureType] = unlock;
      // #region agent log
      _debugLogUsage('H1', 'usage_limit_service.dart:unlockFeatureFromAd:cacheUpdated', 'Cache _activeUnlocks atualizado', {'featureType': featureType.name, 'cacheHasUnlock': _activeUnlocks[featureType] != null, 'cacheUnlockIsActive': _activeUnlocks[featureType]?.isActive});
      // #endregion

      if (kDebugMode) {
        print('🎬 Feature desbloqueada: ${featureType.name} por ${durationHours}h');
      }

      return unlock;
    } catch (e) {
      // #region agent log
      _debugLogUsage('H1', 'usage_limit_service.dart:unlockFeatureFromAd:error', 'ERRO ao desbloquear', {'error': e.toString()});
      // #endregion
      if (kDebugMode) {
        print('❌ Erro ao desbloquear feature: $e');
      }
      return null;
    }
  }

  /// Registra um desbloqueio trial
  Future<FeatureUnlock?> unlockFeatureTrial({
    required FeatureType featureType,
    int durationHours = 168, // 7 dias
  }) async {
    final userId = _currentUserId;
    if (userId == null) return null;

    try {
      final unlock = FeatureUnlock.trial(
        userId: userId,
        featureType: featureType,
        durationHours: durationHours,
      );

      // Salva no Firestore
      final ref = _unlocksRef;
      if (ref != null) {
        final model = FeatureUnlockModel.fromEntity(unlock);
        await ref.doc(unlock.id).set(model.toFirestore());
      }

      // Atualiza cache local
      _activeUnlocks[featureType] = unlock;
      
      // Rastreia desbloqueio trial no analytics
      _analyticsService?.trackFeatureUnlock(
        featureType: featureType.name,
        unlockSource: 'trial',
        durationHours: durationHours,
      );

      if (kDebugMode) {
        print('🎁 Trial ativado: ${featureType.name} por ${durationHours}h');
      }

      return unlock;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao ativar trial: $e');
      }
      return null;
    }
  }

  /// Verifica se há desbloqueio ativo para uma feature
  bool hasActiveUnlock(FeatureType featureType) {
    final unlock = _activeUnlocks[featureType];
    return unlock != null && unlock.isActive;
  }

  /// Obtém o desbloqueio ativo para uma feature
  FeatureUnlock? getActiveUnlock(FeatureType featureType) {
    final unlock = _activeUnlocks[featureType];
    if (unlock != null && unlock.isActive) {
      return unlock;
    }
    return null;
  }

  /// Obtém o limite atual de uma feature
  UsageLimit? getLimit(FeatureType featureType) {
    return _usageLimits[featureType];
  }

  /// Obtém estatísticas de uso
  Map<String, dynamic> getUsageStats() {
    final stats = <String, dynamic>{};
    
    for (final entry in _usageLimits.entries) {
      final limit = entry.value;
      final unlock = _activeUnlocks[entry.key];
      
      stats[entry.key.name] = {
        'dailyLimit': limit.dailyLimit,
        'usedToday': limit.usedToday,
        'remaining': limit.remainingToday,
        'hasUnlock': unlock != null && unlock.isActive,
        'unlockExpiresIn': unlock?.timeRemainingFormatted,
      };
    }
    
    return stats;
  }

  /// Limpa dados locais (para logout)
  void clearLocalData() {
    _usageLimits.clear();
    _activeUnlocks.clear();
  }
}
