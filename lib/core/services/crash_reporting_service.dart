import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Serviço centralizado para crash reporting e error tracking
/// 
/// Features:
/// - Captura automática de crashes
/// - Log de erros não fatais
/// - Identificação de usuários
/// - Stack traces detalhados
/// - Logs customizados
class CrashReportingService {
  static CrashReportingService? _instance;
  static CrashReportingService get instance {
    _instance ??= CrashReportingService._();
    return _instance!;
  }

  CrashReportingService._();

  FirebaseCrashlytics? _crashlytics;
  bool _isInitialized = false;

  /// Inicializa o Firebase Crashlytics
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _crashlytics = FirebaseCrashlytics.instance;

      // Configurar captura automática de erros do Flutter
      FlutterError.onError = (FlutterErrorDetails details) {
        _crashlytics?.recordFlutterError(details);
        
        // Em desenvolvimento, também mostrar no console
        if (kDebugMode) {
          FlutterError.dumpErrorToConsole(details);
        }
      };

      // Capturar erros assíncronos não tratados
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics?.recordError(error, stack, fatal: true);
        return true;
      };

      // Habilitar coleta em produção, desabilitar em debug
      await _crashlytics?.setCrashlyticsCollectionEnabled(!kDebugMode);

      _isInitialized = true;
      log('🛡️ Crash Reporting inicializado com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar Crash Reporting: $e');
    }
  }

  /// Define o ID do usuário para tracking
  Future<void> setUserId(String? userId) async {
    if (!_isInitialized) return;
    
    try {
      await _crashlytics?.setUserIdentifier(userId ?? 'anonymous');
    } catch (e) {
      debugPrint('Erro ao definir user ID: $e');
    }
  }

  /// Define informações customizadas do usuário
  Future<void> setUserInfo({
    required String? email,
    required String? name,
    String? plan,
  }) async {
    if (!_isInitialized) return;

    try {
      await _crashlytics?.setCustomKey('user_email', email ?? 'N/A');
      await _crashlytics?.setCustomKey('user_name', name ?? 'N/A');
      await _crashlytics?.setCustomKey('user_plan', plan ?? 'free');
    } catch (e) {
      debugPrint('Erro ao definir informações do usuário: $e');
    }
  }

  /// Registra um erro não fatal
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object>? information,
    bool fatal = false,
  }) async {
    if (!_isInitialized) {
      debugPrint('❌ Erro (não rastreado): $exception');
      return;
    }

    try {
      await _crashlytics?.recordError(
        exception,
        stackTrace,
        reason: reason,
        information: information ?? [],
        fatal: fatal,
      );

      // Log em desenvolvimento
      if (kDebugMode) {
        debugPrint('🐛 Erro registrado: $exception');
        if (reason != null) debugPrint('   Razão: $reason');
      }
    } catch (e) {
      debugPrint('Erro ao registrar erro: $e');
    }
  }

  /// Adiciona log customizado ao crash report
  void log(String message) {
    if (!_isInitialized) return;
    
    try {
      _crashlytics?.log(message);
      
      // Também mostrar em desenvolvimento
      if (kDebugMode) {
        debugPrint('📝 [Crashlytics] $message');
      }
    } catch (e) {
      debugPrint('Erro ao adicionar log: $e');
    }
  }

  /// Define chave customizada para contexto adicional
  Future<void> setCustomKey(String key, dynamic value) async {
    if (!_isInitialized) return;

    try {
      await _crashlytics?.setCustomKey(key, value);
    } catch (e) {
      debugPrint('Erro ao definir custom key: $e');
    }
  }

  /// Registra erro de autenticação
  Future<void> recordAuthError(
    dynamic exception,
    StackTrace stackTrace, {
    required String authMethod,
  }) async {
    await setCustomKey('auth_method', authMethod);
    await recordError(
      exception,
      stackTrace,
      reason: 'Authentication error: $authMethod',
      fatal: false,
    );
  }

  /// Registra erro de banco de dados
  Future<void> recordDatabaseError(
    dynamic exception,
    StackTrace stackTrace, {
    required String operation,
    String? collection,
  }) async {
    await setCustomKey('db_operation', operation);
    if (collection != null) {
      await setCustomKey('db_collection', collection);
    }
    await recordError(
      exception,
      stackTrace,
      reason: 'Database error: $operation',
      fatal: false,
    );
  }

  /// Registra erro de API/Network
  Future<void> recordNetworkError(
    dynamic exception,
    StackTrace stackTrace, {
    required String endpoint,
    int? statusCode,
  }) async {
    await setCustomKey('api_endpoint', endpoint);
    if (statusCode != null) {
      await setCustomKey('api_status_code', statusCode);
    }
    await recordError(
      exception,
      stackTrace,
      reason: 'Network error: $endpoint',
      fatal: false,
    );
  }

  /// Testa o crash reporting (apenas em desenvolvimento)
  void testCrash() {
    if (kDebugMode) {
      log('🧪 Testando crash reporting...');
      throw Exception('Test crash from CrashReportingService');
    }
  }

  /// Força envio de relatórios pendentes
  Future<void> sendUnsentReports() async {
    if (!_isInitialized) return;
    
    try {
      await _crashlytics?.sendUnsentReports();
      log('📤 Relatórios não enviados foram enviados');
    } catch (e) {
      debugPrint('Erro ao enviar relatórios: $e');
    }
  }

  /// Verifica se há relatórios não enviados
  Future<bool> checkForUnsentReports() async {
    if (!_isInitialized) return false;
    
    try {
      return await _crashlytics?.checkForUnsentReports() ?? false;
    } catch (e) {
      debugPrint('Erro ao verificar relatórios: $e');
      return false;
    }
  }
}
