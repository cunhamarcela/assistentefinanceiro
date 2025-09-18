import 'package:flutter/foundation.dart';
import '../storage/storage_service.dart';

/// Serviço de analytics para rastreamento de eventos de retenção
class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();
  
  AnalyticsService._();

  final StorageService _localStorage = StorageService.instance;
  final List<AnalyticsEvent> _eventQueue = [];
  bool _isInitialized = false;

  /// Inicializa o serviço de analytics
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Carrega eventos pendentes do armazenamento local
      await _loadPendingEvents();
      
      // Configura envio periódico de eventos
      _scheduleEventSync();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('📊 AnalyticsService inicializado');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao inicializar AnalyticsService: $e');
      }
    }
  }

  /// Registra um evento de chat IA
  Future<void> trackChatEvent({
    required ChatEventType type,
    Map<String, dynamic>? properties,
  }) async {
    await _trackEvent(
      name: 'chat_${type.name}',
      category: 'chat_ai',
      properties: {
        'event_type': type.name,
        ...?properties,
      },
    );
  }

  /// Registra um evento de relatório visual
  Future<void> trackReportEvent({
    required ReportEventType type,
    String? reportType,
    Map<String, dynamic>? properties,
  }) async {
    await _trackEvent(
      name: 'report_${type.name}',
      category: 'visual_reports',
      properties: {
        'event_type': type.name,
        'report_type': reportType,
        ...?properties,
      },
    );
  }

  /// Registra um evento de retenção
  Future<void> trackRetentionEvent({
    required RetentionEventType type,
    Map<String, dynamic>? properties,
  }) async {
    await _trackEvent(
      name: 'retention_${type.name}',
      category: 'retention',
      properties: {
        'event_type': type.name,
        ...?properties,
      },
    );
  }

  /// Registra um evento de engajamento
  Future<void> trackEngagementEvent({
    required String action,
    String? screen,
    Map<String, dynamic>? properties,
  }) async {
    await _trackEvent(
      name: 'engagement_$action',
      category: 'engagement',
      properties: {
        'action': action,
        'screen': screen,
        ...?properties,
      },
    );
  }

  /// Registra um evento personalizado
  Future<void> trackCustomEvent({
    required String name,
    String? category,
    Map<String, dynamic>? properties,
  }) async {
    await _trackEvent(
      name: name,
      category: category ?? 'custom',
      properties: properties,
    );
  }

  /// Registra início de sessão
  Future<void> trackSessionStart() async {
    await _trackEvent(
      name: 'session_start',
      category: 'session',
      properties: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Registra fim de sessão
  Future<void> trackSessionEnd({int? durationSeconds}) async {
    await _trackEvent(
      name: 'session_end',
      category: 'session',
      properties: {
        'duration_seconds': durationSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Registra visualização de tela
  Future<void> trackScreenView({
    required String screenName,
    String? previousScreen,
    Map<String, dynamic>? properties,
  }) async {
    await _trackEvent(
      name: 'screen_view',
      category: 'navigation',
      properties: {
        'screen_name': screenName,
        'previous_screen': previousScreen,
        ...?properties,
      },
    );
  }

  /// Método interno para registrar eventos
  Future<void> _trackEvent({
    required String name,
    required String category,
    Map<String, dynamic>? properties,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final event = AnalyticsEvent(
      name: name,
      category: category,
      properties: properties ?? {},
      timestamp: DateTime.now(),
    );

    // Adiciona à fila local
    _eventQueue.add(event);

    // Salva no armazenamento local para persistência
    await _savePendingEvents();

    if (kDebugMode) {
      print('📊 Evento registrado: ${event.name} (${event.category})');
    }

    // Tenta enviar eventos se houver conexão
    _trySyncEvents();
  }

  /// Carrega eventos pendentes do armazenamento local
  Future<void> _loadPendingEvents() async {
    try {
      final eventsData = _localStorage.getStringList('pending_analytics_events');
      if (eventsData != null) {
        for (final eventJson in eventsData) {
          try {
            final event = AnalyticsEvent.fromJson(eventJson);
            _eventQueue.add(event);
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Erro ao carregar evento: $e');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erro ao carregar eventos pendentes: $e');
      }
    }
  }

  /// Salva eventos pendentes no armazenamento local
  Future<void> _savePendingEvents() async {
    try {
      final eventsJson = _eventQueue.map((e) => e.toJson()).toList();
      await _localStorage.setStringList('pending_analytics_events', eventsJson);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erro ao salvar eventos pendentes: $e');
      }
    }
  }

  /// Configura sincronização periódica de eventos
  void _scheduleEventSync() {
    // Implementar timer para sincronização periódica
    // Por enquanto, apenas tenta sincronizar a cada evento
  }

  /// Tenta sincronizar eventos com o servidor
  Future<void> _trySyncEvents() async {
    if (_eventQueue.isEmpty) return;

    try {
      // TODO: Implementar envio real para Firebase Analytics ou outro serviço
      // Por enquanto, apenas simula o envio bem-sucedido
      
      if (kDebugMode) {
        print('📤 Sincronizando ${_eventQueue.length} eventos...');
      }

      // Simula delay de rede
      await Future.delayed(const Duration(milliseconds: 100));

      // Limpa eventos após envio bem-sucedido
      _eventQueue.clear();
      await _localStorage.remove('pending_analytics_events');

      if (kDebugMode) {
        print('✅ Eventos sincronizados com sucesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao sincronizar eventos: $e');
      }
      // Mantém eventos na fila para tentar novamente depois
    }
  }

  /// Força sincronização de todos os eventos pendentes
  Future<void> syncAllEvents() async {
    await _trySyncEvents();
  }

  /// Limpa todos os eventos pendentes
  Future<void> clearAllEvents() async {
    _eventQueue.clear();
    await _localStorage.remove('pending_analytics_events');
  }

  /// Obtém estatísticas dos eventos
  Map<String, dynamic> getEventStats() {
    final categoryCount = <String, int>{};
    final eventCount = <String, int>{};

    for (final event in _eventQueue) {
      categoryCount[event.category] = (categoryCount[event.category] ?? 0) + 1;
      eventCount[event.name] = (eventCount[event.name] ?? 0) + 1;
    }

    return {
      'total_events': _eventQueue.length,
      'categories': categoryCount,
      'events': eventCount,
    };
  }
}

/// Modelo de evento de analytics
class AnalyticsEvent {
  final String name;
  final String category;
  final Map<String, dynamic> properties;
  final DateTime timestamp;

  AnalyticsEvent({
    required this.name,
    required this.category,
    required this.properties,
    required this.timestamp,
  });

  /// Converte para JSON
  String toJson() {
    return '{'
        '"name": "$name",'
        '"category": "$category",'
        '"properties": ${_mapToJson(properties)},'
        '"timestamp": "${timestamp.toIso8601String()}"'
        '}';
  }

  /// Cria instância a partir de JSON
  factory AnalyticsEvent.fromJson(String json) {
    // Implementação simplificada - em produção usar biblioteca JSON
    final data = <String, dynamic>{}; // Parse real do JSON
    
    return AnalyticsEvent(
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      properties: data['properties'] ?? {},
      timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  String _mapToJson(Map<String, dynamic> map) {
    final entries = map.entries.map((e) => '"${e.key}": "${e.value}"').join(',');
    return '{$entries}';
  }
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
