import 'package:shared_preferences/shared_preferences.dart';

/// Serviço para gerenciar configurações do perfil do usuário
class ProfileSettingsService {
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _appNotificationsEnabledKey = 'app_notifications_enabled';
  static const String _currentLanguageKey = 'current_language';
  static const String _currentCountryKey = 'current_country';
  
  /// Salvar configuração de notificações gerais
  Future<void> saveNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }
  
  /// Carregar configuração de notificações gerais
  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }
  
  /// Salvar configuração de notificações do app
  Future<void> saveAppNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appNotificationsEnabledKey, enabled);
  }
  
  /// Carregar configuração de notificações do app
  Future<bool> getAppNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_appNotificationsEnabledKey) ?? false;
  }
  
  /// Salvar idioma atual
  Future<void> saveCurrentLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentLanguageKey, language);
  }
  
  /// Carregar idioma atual
  Future<String> getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentLanguageKey) ?? 'Português';
  }
  
  /// Salvar país atual
  Future<void> saveCurrentCountry(String country) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentCountryKey, country);
  }
  
  /// Carregar país atual
  Future<String> getCurrentCountry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentCountryKey) ?? 'Brasil';
  }
  
  /// Carregar todas as configurações
  Future<Map<String, dynamic>> getAllSettings() async {
    return {
      'notificationsEnabled': await getNotificationsEnabled(),
      'appNotificationsEnabled': await getAppNotificationsEnabled(),
      'currentLanguage': await getCurrentLanguage(),
      'currentCountry': await getCurrentCountry(),
    };
  }
  
  /// Limpar todas as configurações
  Future<void> clearAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsEnabledKey);
    await prefs.remove(_appNotificationsEnabledKey);
    await prefs.remove(_currentLanguageKey);
    await prefs.remove(_currentCountryKey);
  }
}
