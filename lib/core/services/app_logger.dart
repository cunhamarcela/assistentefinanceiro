import 'logging_service.dart';

/// Helper estático para acesso rápido ao LoggingService
/// 
/// Uso:
/// ```dart
/// // Log simples
/// AppLogger.info(FeatureTag.expenses, 'Despesa criada');
/// 
/// // Log com dados
/// AppLogger.debug(FeatureTag.auth, 'Token validado', data: {'expires_in': 3600});
/// 
/// // Operação com métricas
/// final opId = AppLogger.startOp(FeatureTag.sync, 'sync_expenses');
/// try {
///   await syncExpenses();
///   AppLogger.completeOp(opId, message: '50 despesas sincronizadas');
/// } catch (e) {
///   AppLogger.failOp(opId, 'Erro de conexão', error: e);
/// }
/// ```
class AppLogger {
  static LoggingService get _logger => LoggingService.instance;

  // ==================== LOGS BÁSICOS ====================

  /// Log de debug (apenas em modo verbose)
  static void debug(FeatureTag feature, String message, {Map<String, dynamic>? data}) {
    _logger.debug(feature, message, data: data);
  }

  /// Log informativo
  static void info(FeatureTag feature, String message, {Map<String, dynamic>? data}) {
    _logger.info(feature, message, data: data);
  }

  /// Log de warning
  static void warning(FeatureTag feature, String message, {Map<String, dynamic>? data}) {
    _logger.warning(feature, message, data: data);
  }

  /// Log de erro
  static void error(
    FeatureTag feature,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _logger.error(feature, message, error: error, stackTrace: stackTrace, data: data);
  }

  /// Log crítico
  static void critical(
    FeatureTag feature,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _logger.critical(feature, message, error: error, stackTrace: stackTrace, data: data);
  }

  // ==================== OPERAÇÕES COM MÉTRICAS ====================

  /// Inicia operação e retorna ID para rastreamento
  static String startOp(FeatureTag feature, String operation, {Map<String, dynamic>? data}) {
    return _logger.startOperation(feature, operation, data: data);
  }

  /// Atualiza progresso de operação
  static void updateOp(String opId, String progress, {Map<String, dynamic>? data}) {
    _logger.updateOperation(opId, progress, data: data);
  }

  /// Completa operação com sucesso
  static void completeOp(String opId, {String? message, Map<String, dynamic>? data}) {
    _logger.completeOperation(opId, message: message, data: data);
  }

  /// Falha operação
  static void failOp(String opId, String error, {dynamic exception, StackTrace? stackTrace}) {
    _logger.failOperation(opId, error, error: exception, stackTrace: stackTrace);
  }

  // ==================== SINCRONIZAÇÃO ====================

  /// Log de início de sincronização
  static void syncStart(String entity, {String? source, int? count}) {
    _logger.syncStarted(entity, source: source, count: count);
  }

  /// Log de sincronização completa
  static void syncComplete(String entity, {int? synced, int? failed, Duration? duration}) {
    _logger.syncCompleted(entity, synced: synced, failed: failed, duration: duration);
  }

  /// Log de sincronização falhou
  static void syncFail(String entity, String reason, {dynamic error}) {
    _logger.syncFailed(entity, reason, error: error);
  }

  /// Log de dados carregados do cache
  static void cached(String entity, {int? count, String? source}) {
    _logger.dataCached(entity, count: count, source: source);
  }

  // ==================== FLUXO DO USUÁRIO ====================

  /// Log de ação do usuário
  static void action(String action, {FeatureTag? feature, Map<String, dynamic>? data}) {
    _logger.userAction(action, feature: feature, data: data);
  }

  /// Log de navegação
  static void navigate(String from, String to, {Map<String, dynamic>? params}) {
    _logger.navigation(from, to, params: params);
  }

  /// Log de estado de feature
  static void state(FeatureTag feature, String state, {Map<String, dynamic>? data}) {
    _logger.featureState(feature, state, data: data);
  }

  // ==================== DADOS ====================

  /// Log de dados carregados
  static void loaded(FeatureTag feature, String entity, int count, {String? source}) {
    _logger.dataLoaded(feature, entity, count, source: source);
  }

  /// Log de dados salvos
  static void saved(FeatureTag feature, String entity, {String? id, Map<String, dynamic>? data}) {
    _logger.dataSaved(feature, entity, id: id, data: data);
  }

  /// Log de dados deletados
  static void deleted(FeatureTag feature, String entity, String id) {
    _logger.dataDeleted(feature, entity, id);
  }

  /// Log de validação
  static void validate(FeatureTag feature, String field, bool isValid, {String? reason}) {
    _logger.validation(feature, field, isValid, reason: reason);
  }

  /// Log de lógica de negócio
  static void logic(FeatureTag feature, String operation, {Map<String, dynamic>? input, dynamic result}) {
    _logger.businessLogic(feature, operation, input: input, result: result);
  }

  // ==================== ANALYTICS ====================

  /// Registra evento de analytics
  static Future<void> event(String name, {Map<String, dynamic>? params}) async {
    await _logger.logEvent(name, parameters: params);
  }

  /// Registra visualização de tela
  static Future<void> screen(String screenName, String screenClass) async {
    await _logger.logScreenView(screenName, screenClass);
  }

  // ==================== HELPERS ESPECÍFICOS ====================

  /// Log de autenticação - login
  static void authLogin(String method) {
    info(FeatureTag.auth, '🔑 Login iniciado via $method');
  }

  /// Log de autenticação - sucesso
  static void authSuccess(String method, {String? userId}) {
    info(FeatureTag.auth, '✅ Autenticado via $method', data: {'user_id': userId});
    _logger.logLogin(method);
  }

  /// Log de autenticação - erro
  static void authError(String method, String code, {dynamic error}) {
    _logger.error(
      FeatureTag.auth,
      '❌ Falha na autenticação via $method',
      error: error,
      data: {'method': method, 'code': code},
    );
    _logger.logAuthError(method, code);
  }

  /// Log de autenticação - logout
  static void authLogout({String? reason}) {
    info(FeatureTag.auth, '🚪 Logout', data: reason != null ? {'reason': reason} : null);
  }

  /// Log de despesa criada
  static void expenseCreated(double amount, String description, String category, String paymentMethod) {
    _logger.logExpenseCreated(
      amount: amount,
      category: category,
      paymentMethod: paymentMethod,
    );
  }

  /// Log de despesa atualizada
  static void expenseUpdated(String id, double amount) {
    saved(FeatureTag.expenses, 'despesa', id: id, data: {'amount': amount, 'action': 'update'});
  }

  /// Log de despesa deletada
  static void expenseDeleted(String id) {
    deleted(FeatureTag.expenses, 'despesa', id);
  }

  /// Log de categoria criada
  static void categoryCreated(String name, {String? id}) {
    _logger.logCategoryCreated(name);
  }

  /// Log de meta criada
  static void goalCreated(String name, double target, String category) {
    _logger.logGoalCreated(goalName: name, targetAmount: target, category: category);
  }

  /// Log de receita criada
  static void incomeCreated(double amount, String type) {
    saved(FeatureTag.income, 'receita', data: {'amount': amount, 'type': type});
  }

  /// Log de mensagem de chat
  static void chatMessage(String role, int length, {bool? hasInsight}) {
    debug(FeatureTag.chat, 'Mensagem $role', data: {
      'role': role,
      'length': length,
      if (hasInsight != null) 'has_insight': hasInsight,
    });
  }

  /// Log de resposta IA
  static void chatResponse({int? duration, bool? hasError}) {
    if (hasError == true) {
      warning(FeatureTag.chat, '⚠️ Resposta IA com erro');
    } else {
      info(FeatureTag.chat, '🤖 Resposta IA gerada', data: {
        if (duration != null) 'duration_ms': duration,
      });
    }
  }

  // ==================== UTILITÁRIOS ====================

  /// Define modo verbose (mais detalhes)
  static void setVerbose(bool enabled) {
    _logger.setVerboseMode(enabled);
  }

  /// Define user ID para analytics
  static Future<void> setUserId(String? userId) async {
    await _logger.setUserId(userId);
  }

  /// Define propriedade do usuário
  static Future<void> setUserProperty(String name, String value) async {
    await _logger.setUserProperty(name, value);
  }

  /// Imprime resumo de logs (debug only)
  static void printSummary() {
    _logger.printSummary();
  }

  /// Obtém estatísticas de logs
  static Map<String, dynamic> getStats() {
    return {
      'by_feature': _logger.getLogCountByFeature(),
      'by_level': _logger.getLogCountByLevel(),
    };
  }
}

// ==================== EXTENSÕES ÚTEIS ====================

/// Extensão para facilitar log em controllers
extension LoggableController on Object {
  /// Nome da classe para logs
  String get logTag => runtimeType.toString();
  
  /// Log rápido de debug
  void logDebug(String message, {Map<String, dynamic>? data}) {
    AppLogger.debug(FeatureTag.general, '[$logTag] $message', data: data);
  }
  
  /// Log rápido de info
  void logInfo(String message, {Map<String, dynamic>? data}) {
    AppLogger.info(FeatureTag.general, '[$logTag] $message', data: data);
  }
  
  /// Log rápido de erro
  void logError(String message, {dynamic error, Map<String, dynamic>? data}) {
    AppLogger.error(FeatureTag.general, '[$logTag] $message', error: error, data: data);
  }
}




