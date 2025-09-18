import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  
  StorageService._();

  late SharedPreferences _prefs;

  /// Inicializar o storage
  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  // ==================== STRING ====================
  
  /// Salvar string
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  /// Obter string
  String? getString(String key, {String? defaultValue}) {
    return _prefs.getString(key) ?? defaultValue;
  }

  // ==================== INT ====================
  
  /// Salvar int
  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  /// Obter int
  int? getInt(String key, {int? defaultValue}) {
    return _prefs.getInt(key) ?? defaultValue;
  }

  // ==================== DOUBLE ====================
  
  /// Salvar double
  Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  /// Obter double
  double? getDouble(String key, {double? defaultValue}) {
    return _prefs.getDouble(key) ?? defaultValue;
  }

  // ==================== BOOL ====================
  
  /// Salvar bool
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  /// Obter bool
  bool? getBool(String key, {bool? defaultValue}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  // ==================== LIST STRING ====================
  
  /// Salvar lista de strings
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  /// Obter lista de strings
  List<String>? getStringList(String key, {List<String>? defaultValue}) {
    return _prefs.getStringList(key) ?? defaultValue;
  }

  // ==================== JSON ====================
  
  /// Salvar objeto como JSON
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    return await _prefs.setString(key, jsonString);
  }

  /// Obter objeto do JSON
  Map<String, dynamic>? getJson(String key) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Erro ao decodificar JSON para chave $key: $e');
      return null;
    }
  }

  /// Salvar lista de objetos como JSON
  Future<bool> setJsonList(String key, List<Map<String, dynamic>> value) async {
    final jsonString = jsonEncode(value);
    return await _prefs.setString(key, jsonString);
  }

  /// Obter lista de objetos do JSON
  List<Map<String, dynamic>>? getJsonList(String key) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    
    try {
      final decoded = jsonDecode(jsonString) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Erro ao decodificar lista JSON para chave $key: $e');
      return null;
    }
  }

  // ==================== UTILIDADES ====================
  
  /// Verificar se uma chave existe
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  /// Remover uma chave
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  /// Remover múltiplas chaves
  Future<void> removeKeys(List<String> keys) async {
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  /// Limpar todos os dados
  Future<bool> clear() async {
    return await _prefs.clear();
  }

  /// Obter todas as chaves
  Set<String> getAllKeys() {
    return _prefs.getKeys();
  }

  /// Recarregar dados do storage
  Future<void> reload() async {
    await _prefs.reload();
  }

  // ==================== CONFIGURAÇÕES ESPECÍFICAS ====================
  
  /// Configurações de tema
  Future<bool> setThemeMode(String mode) => setString('theme_mode', mode);
  String getThemeMode() => getString('theme_mode', defaultValue: 'system') ?? 'system';

  /// Configurações de idioma
  Future<bool> setLanguage(String language) => setString('language', language);
  String getLanguage() => getString('language', defaultValue: 'pt') ?? 'pt';

  /// Primeira execução do app
  Future<bool> setFirstRun(bool isFirst) => setBool('first_run', isFirst);
  bool isFirstRun() => getBool('first_run', defaultValue: true) ?? true;

  /// Versão do app (para migrations)
  Future<bool> setAppVersion(String version) => setString('app_version', version);
  String? getAppVersion() => getString('app_version');

  /// Configurações de notificação
  Future<bool> setNotificationsEnabled(bool enabled) => setBool('notifications_enabled', enabled);
  bool areNotificationsEnabled() => getBool('notifications_enabled', defaultValue: true) ?? true;

  /// Configurações de analytics
  Future<bool> setAnalyticsEnabled(bool enabled) => setBool('analytics_enabled', enabled);
  bool isAnalyticsEnabled() => getBool('analytics_enabled', defaultValue: true) ?? true;

  /// Última sincronização
  Future<bool> setLastSync(DateTime dateTime) => setString('last_sync', dateTime.toIso8601String());
  DateTime? getLastSync() {
    final dateString = getString('last_sync');
    return dateString != null ? DateTime.tryParse(dateString) : null;
  }

  /// Configurações de backup
  Future<bool> setAutoBackupEnabled(bool enabled) => setBool('auto_backup_enabled', enabled);
  bool isAutoBackupEnabled() => getBool('auto_backup_enabled', defaultValue: false) ?? false;

  /// Moeda padrão
  Future<bool> setDefaultCurrency(String currency) => setString('default_currency', currency);
  String getDefaultCurrency() => getString('default_currency', defaultValue: 'BRL') ?? 'BRL';

  /// Formato de data
  Future<bool> setDateFormat(String format) => setString('date_format', format);
  String getDateFormat() => getString('date_format', defaultValue: 'dd/MM/yyyy') ?? 'dd/MM/yyyy';

  // ==================== DEBUG ====================
  
  /// Imprimir todas as configurações (apenas para debug)
  void printAllSettings() {
    final keys = getAllKeys();
    print('=== CONFIGURAÇÕES ARMAZENADAS ===');
    for (final key in keys) {
      final value = _prefs.get(key);
      print('$key: $value');
    }
    print('================================');
  }

  /// Obter estatísticas do storage
  Map<String, dynamic> getStorageStats() {
    final keys = getAllKeys();
    final stats = <String, dynamic>{
      'total_keys': keys.length,
      'keys': keys.toList(),
    };
    
    // Contar tipos de dados
    int strings = 0, ints = 0, doubles = 0, bools = 0, lists = 0;
    
    for (final key in keys) {
      final value = _prefs.get(key);
      if (value is String) strings++;
      else if (value is int) ints++;
      else if (value is double) doubles++;
      else if (value is bool) bools++;
      else if (value is List) lists++;
    }
    
    stats.addAll({
      'strings': strings,
      'ints': ints,
      'doubles': doubles,
      'bools': bools,
      'lists': lists,
    });
    
    return stats;
  }
}
