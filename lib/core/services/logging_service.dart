import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'crash_reporting_service.dart';

/// Níveis de severidade de log
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Tags das features para organização de logs
enum FeatureTag {
  auth('🔐', 'AUTH'),
  expenses('💰', 'EXPENSES'),
  income('💵', 'INCOME'),
  chat('💬', 'CHAT'),
  goals('🎯', 'GOALS'),
  profile('👤', 'PROFILE'),
  sync('🔄', 'SYNC'),
  database('🗄️', 'DATABASE'),
  network('🌐', 'NETWORK'),
  ui('🖼️', 'UI'),
  navigation('🧭', 'NAVIGATION'),
  startup('🚀', 'STARTUP'),
  analytics('📊', 'ANALYTICS'),
  storage('💾', 'STORAGE'),
  categories('🏷️', 'CATEGORIES'),
  reports('📈', 'REPORTS'),
  onboarding('📚', 'ONBOARDING'),
  monetization('💎', 'MONETIZATION'),
  general('📝', 'GENERAL');

  final String emoji;
  final String tag;
  
  const FeatureTag(this.emoji, this.tag);
}

/// Status de operação para logs estruturados
enum OperationStatus {
  started('⏳'),
  inProgress('🔄'),
  success('✅'),
  failure('❌'),
  warning('⚠️'),
  skipped('⏭️'),
  cached('📦'),
  synced('☁️');

  final String emoji;
  const OperationStatus(this.emoji);
}

/// Classe para métricas de operação
class OperationMetrics {
  final String operationName;
  final DateTime startTime;
  DateTime? endTime;
  OperationStatus status;
  String? errorMessage;
  Map<String, dynamic>? data;

  OperationMetrics({
    required this.operationName,
    required this.startTime,
    this.status = OperationStatus.started,
    this.data,
  });

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);
  
  void complete({OperationStatus? status, Map<String, dynamic>? data}) {
    endTime = DateTime.now();
    if (status != null) this.status = status;
    if (data != null) this.data = {...?this.data, ...data};
  }
  
  void fail(String error) {
    endTime = DateTime.now();
    status = OperationStatus.failure;
    errorMessage = error;
  }
  
  Map<String, dynamic> toJson() => {
    'operation': operationName,
    'duration_ms': duration.inMilliseconds,
    'status': status.name,
    if (errorMessage != null) 'error': errorMessage,
    if (data != null) 'data': data,
  };
}

/// Serviço centralizado de logging estruturado
/// 
/// Features:
/// - Logs estruturados e categorizados por feature
/// - Integração com Firebase Analytics
/// - Diferentes níveis de severidade
/// - Rastreamento de operações com métricas
/// - Logs de sincronização com banco
/// - Logs de fluxo de usuário
class LoggingService {
  static LoggingService? _instance;
  static LoggingService get instance {
    _instance ??= LoggingService._();
    return _instance!;
  }

  LoggingService._();

  FirebaseAnalytics? _analytics;
  final _crashReporting = CrashReportingService.instance;
  bool _isInitialized = false;
  bool _verboseMode = kDebugMode;
  
  // Métricas de operações em andamento
  final Map<String, OperationMetrics> _activeOperations = {};
  
  // Contadores de log por feature (para análise)
  final Map<FeatureTag, int> _logCountByFeature = {};
  final Map<LogLevel, int> _logCountByLevel = {};

  /// Inicializa o serviço de logging
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _analytics = FirebaseAnalytics.instance;
      _isInitialized = true;
      
      log(
        FeatureTag.startup,
        LogLevel.info,
        'LoggingService inicializado',
        data: {'verbose_mode': _verboseMode},
      );
    } catch (e) {
      debugPrint('❌ Erro ao inicializar Logging Service: $e');
    }
  }

  /// Define modo verbose (mais detalhes nos logs)
  void setVerboseMode(bool enabled) {
    _verboseMode = enabled;
  }

  // ==================== LOGS PRINCIPAIS ====================

  /// Log principal com feature tag
  void log(
    FeatureTag feature,
    LogLevel level,
    String message, {
    Map<String, dynamic>? data,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    // Incrementa contadores
    _logCountByFeature[feature] = (_logCountByFeature[feature] ?? 0) + 1;
    _logCountByLevel[level] = (_logCountByLevel[level] ?? 0) + 1;
    
    final timestamp = DateTime.now();
    final levelEmoji = _getEmojiForLevel(level);
    final timestampStr = _formatTimestamp(timestamp);
    
    // Monta mensagem formatada
    final formattedMessage = '$levelEmoji ${feature.emoji} [$timestampStr] [${feature.tag}] $message';
    
    // Console log em modo debug ou para warnings+
    if (kDebugMode || level.index >= LogLevel.warning.index) {
      debugPrint(formattedMessage);
      
      if (_verboseMode && data != null && data.isNotEmpty) {
        debugPrint('   📋 Data: $data');
      }
      
      if (error != null) {
        debugPrint('   ❌ Error: $error');
      }
    }

    // Crashlytics log para warnings e acima
    if (level.index >= LogLevel.warning.index) {
      _crashReporting.log('[${feature.tag}] $message');
      
      if (data != null) {
        data.forEach((key, value) {
          _crashReporting.setCustomKey('${feature.tag.toLowerCase()}_$key', value);
        });
      }
      
      if (error != null && level.index >= LogLevel.error.index) {
        _crashReporting.recordError(
          error,
          stackTrace ?? StackTrace.current,
          reason: '[${feature.tag}] $message',
        );
      }
    }
  }

  /// Log de debug
  void debug(FeatureTag feature, String message, {Map<String, dynamic>? data}) {
    if (_verboseMode) {
      log(feature, LogLevel.debug, message, data: data);
    }
  }

  /// Log informativo
  void info(FeatureTag feature, String message, {Map<String, dynamic>? data}) {
    log(feature, LogLevel.info, message, data: data);
  }

  /// Log de warning
  void warning(FeatureTag feature, String message, {Map<String, dynamic>? data}) {
    log(feature, LogLevel.warning, message, data: data);
  }

  /// Log de erro
  void error(
    FeatureTag feature,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    log(
      feature,
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Log crítico
  void critical(
    FeatureTag feature,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    log(
      feature,
      LogLevel.critical,
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  // ==================== OPERAÇÕES COM MÉTRICAS ====================

  /// Inicia rastreamento de uma operação
  String startOperation(FeatureTag feature, String operationName, {Map<String, dynamic>? data}) {
    final opId = '${feature.tag}_${operationName}_${DateTime.now().millisecondsSinceEpoch}';
    
    _activeOperations[opId] = OperationMetrics(
      operationName: operationName,
      startTime: DateTime.now(),
      data: data,
    );
    
    log(
      feature,
      LogLevel.debug,
      '${OperationStatus.started.emoji} Iniciando: $operationName',
      data: data,
    );
    
    return opId;
  }

  /// Atualiza progresso de uma operação
  void updateOperation(String opId, String progress, {Map<String, dynamic>? data}) {
    final op = _activeOperations[opId];
    if (op == null) return;
    
    if (data != null) {
      op.data = {...?op.data, ...data};
    }
    
    if (_verboseMode) {
      debugPrint('   ${OperationStatus.inProgress.emoji} $progress');
    }
  }

  /// Completa uma operação com sucesso
  void completeOperation(String opId, {String? message, Map<String, dynamic>? data}) {
    final op = _activeOperations[opId];
    if (op == null) return;
    
    op.complete(status: OperationStatus.success, data: data);
    
    // Extrai feature do opId
    final featureStr = opId.split('_').first;
    final feature = FeatureTag.values.firstWhere(
      (f) => f.tag == featureStr,
      orElse: () => FeatureTag.general,
    );
    
    log(
      feature,
      LogLevel.info,
      '${OperationStatus.success.emoji} ${message ?? 'Concluído: ${op.operationName}'} (${op.duration.inMilliseconds}ms)',
      data: op.toJson(),
    );
    
    _activeOperations.remove(opId);
  }

  /// Marca uma operação como falha
  void failOperation(String opId, String errorMessage, {dynamic error, StackTrace? stackTrace}) {
    final op = _activeOperations[opId];
    if (op == null) return;
    
    op.fail(errorMessage);
    
    // Extrai feature do opId
    final featureStr = opId.split('_').first;
    final feature = FeatureTag.values.firstWhere(
      (f) => f.tag == featureStr,
      orElse: () => FeatureTag.general,
    );
    
    this.error(
      feature,
      '${OperationStatus.failure.emoji} Falhou: ${op.operationName} - $errorMessage (${op.duration.inMilliseconds}ms)',
      error: error,
      stackTrace: stackTrace,
      data: op.toJson(),
    );
    
    _activeOperations.remove(opId);
  }

  // ==================== LOGS ESPECÍFICOS DE SINCRONIZAÇÃO ====================

  /// Log de sincronização iniciada
  void syncStarted(String entity, {String? source, int? count}) {
    log(
      FeatureTag.sync,
      LogLevel.info,
      '${OperationStatus.started.emoji} Sincronizando $entity',
      data: {
        'entity': entity,
        if (source != null) 'source': source,
        if (count != null) 'count': count,
      },
    );
  }

  /// Log de sincronização completa
  void syncCompleted(String entity, {int? synced, int? failed, Duration? duration}) {
    log(
      FeatureTag.sync,
      LogLevel.info,
      '${OperationStatus.synced.emoji} $entity sincronizado',
      data: {
        'entity': entity,
        if (synced != null) 'synced': synced,
        if (failed != null) 'failed': failed,
        if (duration != null) 'duration_ms': duration.inMilliseconds,
      },
    );
  }

  /// Log de sincronização falhou
  void syncFailed(String entity, String reason, {dynamic error}) {
    this.error(
      FeatureTag.sync,
      '${OperationStatus.failure.emoji} Falha ao sincronizar $entity: $reason',
      error: error,
      data: {'entity': entity, 'reason': reason},
    );
  }

  /// Log de dados cacheados
  void dataCached(String entity, {int? count, String? source}) {
    log(
      FeatureTag.database,
      LogLevel.debug,
      '${OperationStatus.cached.emoji} $entity carregado do cache',
      data: {
        'entity': entity,
        if (count != null) 'count': count,
        if (source != null) 'source': source,
      },
    );
  }

  // ==================== LOGS DE FLUXO DO USUÁRIO ====================

  /// Log de interação do usuário
  void userAction(String action, {FeatureTag? feature, Map<String, dynamic>? data}) {
    log(
      feature ?? FeatureTag.ui,
      LogLevel.info,
      '👆 Ação: $action',
      data: data,
    );
  }

  /// Log de navegação
  void navigation(String from, String to, {Map<String, dynamic>? params}) {
    log(
      FeatureTag.navigation,
      LogLevel.debug,
      '🧭 $from → $to',
      data: {
        'from': from,
        'to': to,
        if (params != null) 'params': params,
      },
    );
  }

  /// Log de estado de feature
  void featureState(FeatureTag feature, String state, {Map<String, dynamic>? data}) {
    log(
      feature,
      LogLevel.debug,
      '📊 Estado: $state',
      data: data,
    );
  }

  // ==================== LOGS DE DADOS/LÓGICA ====================

  /// Log de dados carregados
  void dataLoaded(FeatureTag feature, String entity, int count, {String? source}) {
    log(
      feature,
      LogLevel.info,
      '📥 $entity carregados: $count itens',
      data: {
        'entity': entity,
        'count': count,
        if (source != null) 'source': source,
      },
    );
  }

  /// Log de dados salvos
  void dataSaved(FeatureTag feature, String entity, {String? id, Map<String, dynamic>? data}) {
    log(
      feature,
      LogLevel.info,
      '💾 $entity salvo',
      data: {
        'entity': entity,
        if (id != null) 'id': id,
        if (data != null) ...data,
      },
    );
  }

  /// Log de dados deletados
  void dataDeleted(FeatureTag feature, String entity, String id) {
    log(
      feature,
      LogLevel.info,
      '🗑️ $entity deletado',
      data: {'entity': entity, 'id': id},
    );
  }

  /// Log de validação
  void validation(FeatureTag feature, String field, bool isValid, {String? reason}) {
    log(
      feature,
      isValid ? LogLevel.debug : LogLevel.warning,
      '${isValid ? '✓' : '✗'} Validação $field: ${isValid ? 'OK' : 'Falhou'}',
      data: {
        'field': field,
        'valid': isValid,
        if (reason != null) 'reason': reason,
      },
    );
  }

  /// Log de cálculo/lógica de negócio
  void businessLogic(FeatureTag feature, String operation, {Map<String, dynamic>? input, dynamic result}) {
    log(
      feature,
      LogLevel.debug,
      '🧮 $operation',
      data: {
        'operation': operation,
        if (input != null) 'input': input,
        if (result != null) 'result': result,
      },
    );
  }

  // ==================== EVENTOS DE ANALYTICS ====================

  /// Log de evento customizado
  Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isInitialized) return;

    try {
      await _analytics?.logEvent(
        name: eventName,
        parameters: parameters?.cast<String, Object>(),
      );
      
      debug(FeatureTag.analytics, 'Evento: $eventName', data: parameters);
    } catch (e) {
      error(FeatureTag.analytics, 'Erro ao registrar evento', error: e);
    }
  }

  /// Log de tela visualizada
  Future<void> logScreenView(String screenName, String screenClass) async {
    if (!_isInitialized) return;

    try {
      await _analytics?.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      
      navigation('', screenName);
    } catch (e) {
      error(FeatureTag.analytics, 'Erro ao registrar tela', error: e);
    }
  }

  /// Log de login
  Future<void> logLogin(String method) async {
    await logEvent('login', parameters: {'method': method});
    info(FeatureTag.auth, '🔑 Login via $method');
  }

  /// Log de sign up
  Future<void> logSignUp(String method) async {
    await logEvent('sign_up', parameters: {'method': method});
    info(FeatureTag.auth, '📝 Cadastro via $method');
  }

  /// Log de gasto criado
  Future<void> logExpenseCreated({
    required double amount,
    required String category,
    required String paymentMethod,
  }) async {
    await logEvent('expense_created', parameters: {
      'amount': amount,
      'category': category,
      'payment_method': paymentMethod,
    });
    
    info(
      FeatureTag.expenses,
      '💸 Despesa criada: R\$ ${amount.toStringAsFixed(2)}',
      data: {'category': category, 'payment_method': paymentMethod},
    );
  }

  /// Log de categoria criada
  Future<void> logCategoryCreated(String categoryName) async {
    await logEvent('category_created', parameters: {
      'category_name': categoryName,
    });
    
    info(FeatureTag.categories, '🏷️ Categoria criada: $categoryName');
  }

  /// Log de meta financeira criada
  Future<void> logGoalCreated({
    required String goalName,
    required double targetAmount,
    required String category,
  }) async {
    await logEvent('goal_created', parameters: {
      'goal_name': goalName,
      'target_amount': targetAmount,
      'category': category,
    });
    
    info(
      FeatureTag.goals,
      '🎯 Meta criada: $goalName',
      data: {'target': targetAmount, 'category': category},
    );
  }

  /// Log de erro de autenticação
  Future<void> logAuthError(String method, String errorCode) async {
    await logEvent('auth_error', parameters: {
      'method': method,
      'error_code': errorCode,
    });
    
    error(
      FeatureTag.auth,
      '🚫 Erro de autenticação',
      data: {'method': method, 'code': errorCode},
    );
  }

  /// Log de erro de sincronização
  Future<void> logSyncError(String operation, String errorType) async {
    await logEvent('sync_error', parameters: {
      'operation': operation,
      'error_type': errorType,
    });
    
    error(
      FeatureTag.sync,
      '🔄 Erro de sincronização',
      data: {'operation': operation, 'type': errorType},
    );
  }

  /// Define propriedade do usuário
  Future<void> setUserProperty(String name, String value) async {
    if (!_isInitialized) return;

    try {
      await _analytics?.setUserProperty(name: name, value: value);
    } catch (e) {
      error(FeatureTag.analytics, 'Erro ao definir propriedade', error: e);
    }
  }

  /// Define ID do usuário
  Future<void> setUserId(String? userId) async {
    if (!_isInitialized) return;

    try {
      await _analytics?.setUserId(id: userId);
      info(FeatureTag.auth, '👤 User ID definido', data: {'user_id': userId ?? 'null'});
    } catch (e) {
      error(FeatureTag.analytics, 'Erro ao definir user ID', error: e);
    }
  }

  // ==================== HELPERS ====================

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}.'
           '${timestamp.millisecond.toString().padLeft(3, '0')}';
  }

  String _getEmojiForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.critical:
        return '🚨';
    }
  }

  // ==================== ESTATÍSTICAS ====================

  /// Obtém contagem de logs por feature
  Map<String, int> getLogCountByFeature() {
    return _logCountByFeature.map((k, v) => MapEntry(k.tag, v));
  }

  /// Obtém contagem de logs por nível
  Map<String, int> getLogCountByLevel() {
    return _logCountByLevel.map((k, v) => MapEntry(k.name, v));
  }

  /// Imprime resumo de logs
  void printSummary() {
    if (!kDebugMode) return;
    
    debugPrint('\n📊 ========== LOG SUMMARY ==========');
    debugPrint('Por Feature:');
    _logCountByFeature.forEach((feature, count) {
      debugPrint('  ${feature.emoji} ${feature.tag}: $count');
    });
    debugPrint('\nPor Nível:');
    _logCountByLevel.forEach((level, count) {
      debugPrint('  ${_getEmojiForLevel(level)} ${level.name}: $count');
    });
    debugPrint('====================================\n');
  }

  // ==================== MÉTODOS LEGADO (COMPATIBILIDADE) ====================

  /// Log de debug (apenas em modo debug) - LEGADO
  void logDebug(String tag, String message, {Map<String, dynamic>? data}) {
    debug(FeatureTag.general, '[$tag] $message', data: data);
  }

  /// Log informativo - LEGADO
  void logInfo(String tag, String message, {Map<String, dynamic>? data}) {
    info(FeatureTag.general, '[$tag] $message', data: data);
  }

  /// Log de warning - LEGADO
  void logWarning(String tag, String message, {Map<String, dynamic>? data}) {
    warning(FeatureTag.general, '[$tag] $message', data: data);
  }

  /// Log de erro - LEGADO
  void logError(
    String tag,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    this.error(
      FeatureTag.general,
      '[$tag] $message',
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Log crítico - LEGADO
  void logCritical(
    String tag,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    critical(
      FeatureTag.general,
      '[$tag] $message',
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }
}
