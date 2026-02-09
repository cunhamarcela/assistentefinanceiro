import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get/get.dart';
import '../storage/storage_service.dart';

/// Serviço de analytics integrado com Firebase Analytics
/// 
/// Este serviço envia eventos diretamente para o Firebase Analytics,
/// permitindo rastreamento de monetização, engajamento e retenção.
class AnalyticsService extends GetxService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();
  
  AnalyticsService._();

  late final FirebaseAnalytics _analytics;
  StorageService? _localStorage;
  bool _isInitialized = false;
  
  // Chaves para first-time events
  static const String _keyFirstChatMessage = 'analytics_first_chat_message';
  static const String _keyFirstReportView = 'analytics_first_report_view';
  static const String _keyFirstAdShown = 'analytics_first_ad_shown';
  static const String _keyFirstLimitReached = 'analytics_first_limit_reached';
  static const String _keyInstallDate = 'analytics_install_date';
  static const String _keyTotalAdsWatched = 'analytics_total_ads_watched';
  static const String _keySessionCount = 'analytics_session_count';

  /// Inicializa o serviço de analytics
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _analytics = FirebaseAnalytics.instance;
      
      // Tenta obter StorageService se disponível
      try {
        if (Get.isRegistered<StorageService>()) {
          _localStorage = Get.find<StorageService>();
        } else {
          _localStorage = StorageService.instance;
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ StorageService não disponível para analytics: $e');
        }
      }
      
      _isInitialized = true;
      
      // Registra data de instalação se primeira vez
      await _trackInstallDateIfNeeded();
      
      // Incrementa contador de sessões
      await _incrementSessionCount();
      
      // Define user properties iniciais
      await _setInitialUserProperties();
      
      if (kDebugMode) {
        print('📊 AnalyticsService inicializado com Firebase Analytics');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao inicializar AnalyticsService: $e');
      }
    }
  }

  // ==================== USER PROPERTIES ====================

  /// Define user properties iniciais
  Future<void> _setInitialUserProperties() async {
    try {
      // Tipo de usuário (pode ser atualizado depois)
      await setUserProperty(name: 'user_type', value: 'free');
      
      // Total de ads assistidos
      final totalAds = _localStorage?.getInt(_keyTotalAdsWatched) ?? 0;
      await setUserProperty(name: 'total_ads_watched', value: totalAds.toString());
      
      // Dias desde instalação
      final installDateStr = _localStorage?.getString(_keyInstallDate);
      if (installDateStr != null) {
        final installDate = DateTime.tryParse(installDateStr);
        if (installDate != null) {
          final daysSinceInstall = DateTime.now().difference(installDate).inDays;
          await setUserProperty(name: 'days_since_install', value: daysSinceInstall.toString());
        }
      }
      
      // Contador de sessões
      final sessionCount = _localStorage?.getInt(_keySessionCount) ?? 0;
      await setUserProperty(name: 'session_count', value: sessionCount.toString());
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erro ao definir user properties: $e');
      }
    }
  }

  /// Define uma user property customizada
  Future<void> setUserProperty({required String name, required String? value}) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      if (kDebugMode) {
        print('📊 User property definida: $name = $value');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erro ao definir user property $name: $e');
      }
    }
  }

  /// Define o ID do usuário para analytics
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
      if (kDebugMode) {
        print('📊 User ID definido: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erro ao definir user ID: $e');
      }
    }
  }

  /// Atualiza tipo de usuário (free/premium)
  Future<void> setUserType(String userType) async {
    await setUserProperty(name: 'user_type', value: userType);
  }

  // ==================== FIRST-TIME TRACKING ====================

  /// Registra data de instalação se primeira vez
  Future<void> _trackInstallDateIfNeeded() async {
    try {
      final existingDate = _localStorage?.getString(_keyInstallDate);
      if (existingDate == null) {
        final now = DateTime.now().toIso8601String();
        await _localStorage?.setString(_keyInstallDate, now);
        
        // Evento de primeira abertura
        await _logEvent(
          name: 'app_first_open',
          parameters: {'install_date': now},
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erro ao registrar data de instalação: $e');
      }
    }
  }

  /// Incrementa contador de sessões
  Future<void> _incrementSessionCount() async {
    try {
      final currentCount = _localStorage?.getInt(_keySessionCount) ?? 0;
      await _localStorage?.setInt(_keySessionCount, currentCount + 1);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erro ao incrementar sessão: $e');
      }
    }
  }

  /// Verifica e registra evento de primeira vez
  Future<bool> _trackFirstTimeEvent(String key, String eventName, Map<String, Object>? params) async {
    try {
      final alreadyTracked = _localStorage?.getBool(key) ?? false;
      if (!alreadyTracked) {
        await _localStorage?.setBool(key, true);
        await _logEvent(name: eventName, parameters: params);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erro ao rastrear first-time event: $e');
      }
      return false;
    }
  }

  // ==================== EVENTOS DE CHAT ====================

  /// Registra um evento de chat IA
  Future<void> trackChatEvent({
    required ChatEventType type,
    Map<String, dynamic>? properties,
  }) async {
    final params = <String, Object>{
      'event_type': type.name,
      ...?_sanitizeParams(properties),
    };
    
    await _logEvent(name: 'chat_${type.name}', parameters: params);
    
    // Rastreia primeira mensagem
    if (type == ChatEventType.promptSent) {
      await _trackFirstTimeEvent(
        _keyFirstChatMessage,
        'chat_first_message',
        params,
      );
    }
  }

  // ==================== EVENTOS DE RELATÓRIO ====================

  /// Registra um evento de relatório visual
  Future<void> trackReportEvent({
    required ReportEventType type,
    String? reportType,
    Map<String, dynamic>? properties,
  }) async {
    final params = <String, Object>{
      'event_type': type.name,
      if (reportType != null) 'report_type': reportType,
      ...?_sanitizeParams(properties),
    };
    
    await _logEvent(name: 'report_${type.name}', parameters: params);
    
    // Rastreia primeiro relatório visualizado
    if (type == ReportEventType.viewed) {
      await _trackFirstTimeEvent(
        _keyFirstReportView,
        'report_first_view',
        params,
      );
    }
  }

  // ==================== EVENTOS DE MONETIZAÇÃO ====================

  /// Registra impressão de anúncio
  Future<void> trackAdImpression({
    required String adUnitId,
    required String featureType,
    String adFormat = 'rewarded',
  }) async {
    await _logEvent(
      name: 'ad_impression',
      parameters: {
        'ad_unit_id': adUnitId,
        'feature_type': featureType,
        'ad_format': adFormat,
      },
    );
    
    // Rastreia primeiro anúncio exibido
    await _trackFirstTimeEvent(
      _keyFirstAdShown,
      'ad_first_shown',
      {'feature_type': featureType},
    );
  }

  /// Registra quando usuário inicia visualização do anúncio
  Future<void> trackAdStarted({
    required String adUnitId,
    required String featureType,
  }) async {
    await _logEvent(
      name: 'ad_started',
      parameters: {
        'ad_unit_id': adUnitId,
        'feature_type': featureType,
      },
    );
  }

  /// Registra quando usuário completa anúncio e ganha recompensa
  Future<void> trackAdRewardEarned({
    required String featureType,
    required int durationHours,
    required String adUnitId,
  }) async {
    await _logEvent(
      name: 'ad_reward_earned',
      parameters: {
        'feature_type': featureType,
        'duration_hours': durationHours,
        'ad_unit_id': adUnitId,
      },
    );
    
    // Incrementa contador de ads assistidos
    await _incrementAdsWatched();
  }

  /// Registra falha ao carregar anúncio
  Future<void> trackAdFailed({
    required String adUnitId,
    required String errorMessage,
    int? errorCode,
  }) async {
    await _logEvent(
      name: 'ad_failed_to_load',
      parameters: {
        'ad_unit_id': adUnitId,
        'error_message': errorMessage,
        if (errorCode != null) 'error_code': errorCode,
      },
    );
  }

  /// Registra quando usuário atinge limite diário
  Future<void> trackLimitReached({
    required String featureType,
    required int dailyLimit,
    int? sessionCount,
  }) async {
    await _logEvent(
      name: 'limit_reached',
      parameters: {
        'feature_type': featureType,
        'daily_limit': dailyLimit,
        if (sessionCount != null) 'session_count': sessionCount,
      },
    );
    
    // Rastreia primeira vez que atinge limite
    await _trackFirstTimeEvent(
      _keyFirstLimitReached,
      'limit_first_reached',
      {'feature_type': featureType},
    );
  }

  /// Registra quando banner de aviso de limite é exibido
  Future<void> trackLimitWarningShown({
    required String featureType,
    required int remaining,
  }) async {
    await _logEvent(
      name: 'limit_warning_shown',
      parameters: {
        'feature_type': featureType,
        'remaining': remaining,
      },
    );
  }

  /// Registra quando dialog de limite atingido é exibido
  Future<void> trackAdPromptShown({
    required String featureType,
  }) async {
    await _logEvent(
      name: 'ad_prompt_shown',
      parameters: {
        'feature_type': featureType,
      },
    );
  }

  /// Registra quando feature é desbloqueada
  Future<void> trackFeatureUnlock({
    required String featureType,
    required String unlockSource, // 'ad', 'purchase', 'trial', etc.
    required int durationHours,
  }) async {
    await _logEvent(
      name: 'feature_unlock',
      parameters: {
        'feature_type': featureType,
        'unlock_source': unlockSource,
        'duration_hours': durationHours,
      },
    );
  }

  /// Incrementa contador de ads assistidos
  Future<void> _incrementAdsWatched() async {
    try {
      final currentCount = _localStorage?.getInt(_keyTotalAdsWatched) ?? 0;
      final newCount = currentCount + 1;
      await _localStorage?.setInt(_keyTotalAdsWatched, newCount);
      await setUserProperty(name: 'total_ads_watched', value: newCount.toString());
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erro ao incrementar ads watched: $e');
      }
    }
  }

  // ==================== EVENTOS DE RETENÇÃO ====================

  /// Registra um evento de retenção
  Future<void> trackRetentionEvent({
    required RetentionEventType type,
    Map<String, dynamic>? properties,
  }) async {
    await _logEvent(
      name: 'retention_${type.name}',
      parameters: {
        'event_type': type.name,
        ...?_sanitizeParams(properties),
      },
    );
  }

  // ==================== EVENTOS DE ENGAJAMENTO ====================

  /// Registra um evento de engajamento
  Future<void> trackEngagementEvent({
    required String action,
    String? screen,
    Map<String, dynamic>? properties,
  }) async {
    await _logEvent(
      name: 'engagement_$action',
      parameters: {
        'action': action,
        if (screen != null) 'screen': screen,
        ...?_sanitizeParams(properties),
      },
    );
  }

  // ==================== EVENTOS DE NAVEGAÇÃO ====================

  /// Registra visualização de tela
  Future<void> trackScreenView({
    required String screenName,
    String? screenClass,
    String? previousScreen,
    Map<String, dynamic>? properties,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      
      if (kDebugMode) {
        print('📊 Screen view: $screenName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erro ao registrar screen view: $e');
      }
    }
  }

  /// Registra início de sessão
  Future<void> trackSessionStart() async {
    await _logEvent(
      name: 'session_start',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Registra fim de sessão
  Future<void> trackSessionEnd({int? durationSeconds}) async {
    await _logEvent(
      name: 'session_end',
      parameters: {
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ==================== EVENTOS CUSTOMIZADOS ====================

  /// Registra um evento personalizado
  Future<void> trackCustomEvent({
    required String name,
    String? category,
    Map<String, dynamic>? properties,
  }) async {
    await _logEvent(
      name: name,
      parameters: {
        if (category != null) 'category': category,
        ...?_sanitizeParams(properties),
      },
    );
  }

  // ==================== MÉTODOS INTERNOS ====================

  /// Método interno para enviar eventos ao Firebase
  Future<void> _logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Firebase Analytics tem limite de 40 caracteres para nome do evento
      final sanitizedName = name.length > 40 ? name.substring(0, 40) : name;
      
      await _analytics.logEvent(
        name: sanitizedName,
        parameters: parameters,
      );
      
      if (kDebugMode) {
        print('📊 Evento Firebase: $sanitizedName');
        if (parameters != null && parameters.isNotEmpty) {
          print('   Params: $parameters');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao enviar evento $name: $e');
      }
    }
  }

  /// Sanitiza parâmetros para Firebase Analytics
  Map<String, Object>? _sanitizeParams(Map<String, dynamic>? params) {
    if (params == null) return null;
    
    final sanitized = <String, Object>{};
    for (final entry in params.entries) {
      if (entry.value != null) {
        // Firebase aceita String, int, double
        if (entry.value is String || entry.value is int || entry.value is double || entry.value is bool) {
          sanitized[entry.key] = entry.value;
        } else {
          sanitized[entry.key] = entry.value.toString();
        }
      }
    }
    return sanitized.isEmpty ? null : sanitized;
  }

  /// Obtém instância do FirebaseAnalytics para uso externo (ex: Observer)
  FirebaseAnalytics get firebaseAnalytics => _analytics;

  /// Obtém contador de sessões atual
  int get sessionCount => _localStorage?.getInt(_keySessionCount) ?? 0;

  /// Obtém total de ads assistidos
  int get totalAdsWatched => _localStorage?.getInt(_keyTotalAdsWatched) ?? 0;
}

/// Tipos de eventos de chat
enum ChatEventType {
  promptSent,
  responseReceived,
  responseError,
  insightClicked,
  conversationStarted,
  conversationEnded,
}

/// Tipos de eventos de relatório
enum ReportEventType {
  generated,
  viewed,
  shared,
  exported,
  insightClicked,
  chartInteracted,
}

/// Tipos de eventos de retenção
enum RetentionEventType {
  dailyActive,
  weeklyActive,
  monthlyActive,
  featureDiscovered,
  goalCompleted,
  churnRisk,
}

/// Tipos de eventos de monetização
enum MonetizationEventType {
  limitWarningShown,
  limitReached,
  adPromptShown,
  adStarted,
  adCompleted,
  adFailed,
  featureUnlocked,
}
