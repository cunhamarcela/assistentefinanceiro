import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../features/auth/data/services/auth_service.dart';
import '../../../../features/auth/data/models/user_model.dart';
import '../../../../core/routes/app_routes.dart';
import '../../data/services/profile_settings_service.dart';

class ProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final ProfileSettingsService _settingsService = ProfileSettingsService();
  
  // Observables
  final _isLoading = false.obs;
  final _user = Rxn<UserModel>();
  final _notificationsEnabled = true.obs;
  final _appNotificationsEnabled = false.obs;
  final _currentLanguage = 'Português'.obs;
  final _currentCountry = 'Brasil'.obs;
  
  // Getters
  bool get isLoading => _isLoading.value;
  UserModel? get user => _user.value;
  RxBool get notificationsEnabled => _notificationsEnabled;
  RxBool get appNotificationsEnabled => _appNotificationsEnabled;
  RxString get currentLanguage => _currentLanguage;
  RxString get currentCountry => _currentCountry;
  
  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    _loadSettings();
  }
  
  /// Carrega dados do usuário
  void _loadUserData() {
    _user.value = _authService.currentUser;
  }
  
  /// Navega para edição de perfil
  void goToEditProfile() {
    Get.toNamed(AppRoutes.editProfile);
  }
  
  /// Navega para alteração de senha
  void goToChangePassword() {
    Get.toNamed(AppRoutes.changePassword);
  }
  
  /// Faz logout do usuário
  Future<void> logout() async {
    try {
      _isLoading.value = true;
      
      // Confirmar logout
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirmar Logout'),
          content: const Text('Tem certeza que deseja sair da sua conta?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Sair'),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        await _authService.signOut();
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao fazer logout: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }
  
  /// Atualiza dados do usuário após edição
  void refreshUserData() {
    _loadUserData();
  }
  
  /// Formata nome para exibição
  String get displayName {
    if (user?.name.isNotEmpty == true) {
      return user!.name;
    }
    return user?.email.split('@').first ?? 'Usuário';
  }
  
  /// Obtém iniciais do nome para avatar
  String get initials {
    final name = displayName;
    if (name.isEmpty) return 'U';
    
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
  
  /// Carrega configurações do usuário
  void _loadSettings() async {
    try {
      final settings = await _settingsService.getAllSettings();
      _notificationsEnabled.value = settings['notificationsEnabled'] ?? true;
      _appNotificationsEnabled.value = settings['appNotificationsEnabled'] ?? false;
      _currentLanguage.value = settings['currentLanguage'] ?? 'Português';
      _currentCountry.value = settings['currentCountry'] ?? 'Brasil';
    } catch (e) {
      print('Erro ao carregar configurações: $e');
    }
  }
  
  /// Alterna notificações gerais
  void toggleNotifications(bool value) {
    _notificationsEnabled.value = value;
    _saveNotificationSettings();
  }
  
  /// Alterna notificações do app
  void toggleAppNotifications(bool value) {
    _appNotificationsEnabled.value = value;
    _saveNotificationSettings();
  }
  
  /// Salva configurações de notificação
  void _saveNotificationSettings() async {
    try {
      await _settingsService.saveNotificationsEnabled(_notificationsEnabled.value);
      await _settingsService.saveAppNotificationsEnabled(_appNotificationsEnabled.value);
      
      Get.snackbar(
        'Configurações',
        'Configurações de notificação atualizadas',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao salvar configurações de notificação',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }
  
  /// Mostra seletor de idioma
  void showLanguageSelector() {
    final languages = ['Português', 'English', 'Español', 'Français'];
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecionar Idioma',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...languages.map((language) => ListTile(
              title: Text(language),
              trailing: _currentLanguage.value == language 
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                _currentLanguage.value = language;
                _saveLanguageSettings();
                Get.back();
              },
            )),
          ],
        ),
      ),
    );
  }
  
  /// Mostra seletor de país
  void showCountrySelector() {
    final countries = ['Brasil', 'Estados Unidos', 'Argentina', 'Chile', 'México'];
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecionar País',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...countries.map((country) => ListTile(
              title: Text(country),
              trailing: _currentCountry.value == country 
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                _currentCountry.value = country;
                _saveCountrySettings();
                Get.back();
              },
            )),
          ],
        ),
      ),
    );
  }
  
  /// Salva configurações de idioma
  void _saveLanguageSettings() async {
    try {
      await _settingsService.saveCurrentLanguage(_currentLanguage.value);
      
      Get.snackbar(
        'Idioma',
        'Idioma alterado para ${_currentLanguage.value}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao salvar configuração de idioma',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }
  
  /// Salva configurações de país
  void _saveCountrySettings() async {
    try {
      await _settingsService.saveCurrentCountry(_currentCountry.value);
      
      Get.snackbar(
        'País',
        'País alterado para ${_currentCountry.value}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao salvar configuração de país',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }
}
