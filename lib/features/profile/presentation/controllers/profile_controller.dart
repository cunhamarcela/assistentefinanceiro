import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/data/services/auth_service.dart';
import '../../../../features/auth/data/models/user_model.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
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
    AppLogger.info(FeatureTag.profile, '👤 ProfileController inicializando');
    _loadUserData();
    _loadSettings();
  }
  
  /// Carrega dados do usuário
  void _loadUserData() {
    AppLogger.debug(FeatureTag.profile, 'Carregando dados do usuário');
    _user.value = _authService.currentUser;
    
    if (_user.value != null) {
      AppLogger.debug(FeatureTag.profile, 'Dados do usuário carregados', data: {
        'has_name': _user.value!.name.isNotEmpty,
        'has_email': _user.value!.email.isNotEmpty,
        'email_verified': _user.value!.emailVerified,
      });
    } else {
      AppLogger.warning(FeatureTag.profile, 'Nenhum usuário autenticado');
    }
  }
  
  /// Navega para edição de perfil
  void goToEditProfile() {
    AppLogger.navigate(Get.currentRoute, AppRoutes.editProfile);
    Get.toNamed(AppRoutes.editProfile);
  }
  
  /// Navega para alteração de senha
  void goToChangePassword() {
    AppLogger.navigate(Get.currentRoute, AppRoutes.changePassword);
    Get.toNamed(AppRoutes.changePassword);
  }
  
  /// Faz logout do usuário
  Future<void> logout() async {
    final opId = AppLogger.startOp(FeatureTag.profile, 'logout');
    
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
        AppLogger.authLogout(reason: 'user_requested');
        await _authService.signOut();
        
        AppLogger.completeOp(opId, message: 'Logout realizado');
        AppLogger.navigate(Get.currentRoute, AppRoutes.login, params: {'reason': 'logout'});
        Get.offAllNamed(AppRoutes.login);
      } else {
        AppLogger.debug(FeatureTag.profile, 'Logout cancelado pelo usuário');
        AppLogger.completeOp(opId, message: 'Logout cancelado');
      }
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao fazer logout', exception: e);
      Get.snackbar(
        'Erro',
        'Erro ao fazer logout: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Deletar conta do usuário
  Future<void> deleteAccount() async {
    final opId = AppLogger.startOp(FeatureTag.profile, 'delete_account');
    AppLogger.warning(FeatureTag.profile, '⚠️ Usuário solicitou exclusão de conta');
    
    try {
      // Primeiro diálogo de confirmação
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Excluir Conta'),
          content: const Text(
            'Tem certeza que deseja excluir sua conta permanentemente?\n\n'
            'Esta ação não pode ser desfeita e todos os seus dados serão perdidos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: AppColors.colorError),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        AppLogger.debug(FeatureTag.profile, 'Exclusão de conta cancelada pelo usuário');
        AppLogger.completeOp(opId, message: 'Exclusão cancelada');
        return;
      }

      // Verificar se precisa de senha para reautenticação
      String? password;
      final user = _authService.currentUser;
      
      // Se for conta com email/senha, solicitar senha
      if (user?.email != null && !user!.email.contains('google.com') && !user.email.contains('apple.com')) {
        AppLogger.debug(FeatureTag.profile, 'Solicitando senha para reautenticação');
        
        password = await Get.dialog<String>(
          AlertDialog(
            title: const Text('Confirmar Senha'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Para excluir sua conta, confirme sua senha:'),
                const SizedBox(height: 16),
                TextField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => password = value,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Get.back(result: password),
                style: TextButton.styleFrom(foregroundColor: AppColors.colorError),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        );

        if (password == null || password!.isEmpty) {
          AppLogger.debug(FeatureTag.profile, 'Exclusão cancelada (senha não fornecida)');
          AppLogger.completeOp(opId, message: 'Exclusão cancelada - sem senha');
          return;
        }
      }

      _isLoading.value = true;
      AppLogger.info(FeatureTag.profile, 'Executando exclusão de conta', data: {
        'user_id': user?.id,
      });

      // Executar exclusão da conta
      await _authService.deleteAccount(password: password);

      AppLogger.completeOp(opId, message: 'Conta excluída com sucesso');

      // Navegar para tela de login
      AppLogger.navigate(Get.currentRoute, AppRoutes.login, params: {'reason': 'account_deleted'});
      Get.offAllNamed(AppRoutes.login);

      // Mostrar mensagem de sucesso
      Get.snackbar(
        'Conta Excluída',
        'Sua conta foi excluída com sucesso.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorSuccess,
        colorText: AppColors.colorTextOnDark,
      );

    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao excluir conta', exception: e);
      Get.snackbar(
        'Erro',
        'Erro ao excluir conta: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.colorError,
        colorText: AppColors.colorTextOnDark,
      );
    } finally {
      _isLoading.value = false;
    }
  }
  
  /// Atualiza dados do usuário após edição
  void refreshUserData() {
    AppLogger.debug(FeatureTag.profile, 'Atualizando dados do usuário');
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
    final opId = AppLogger.startOp(FeatureTag.profile, 'load_settings');
    
    try {
      final settings = await _settingsService.getAllSettings();
      _notificationsEnabled.value = settings['notificationsEnabled'] ?? true;
      _appNotificationsEnabled.value = settings['appNotificationsEnabled'] ?? false;
      _currentLanguage.value = settings['currentLanguage'] ?? 'Português';
      _currentCountry.value = settings['currentCountry'] ?? 'Brasil';
      
      AppLogger.completeOp(opId, message: 'Configurações carregadas', data: {
        'notifications': _notificationsEnabled.value,
        'app_notifications': _appNotificationsEnabled.value,
        'language': _currentLanguage.value,
        'country': _currentCountry.value,
      });
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao carregar configurações', exception: e);
    }
  }
  
  /// Alterna notificações gerais
  void toggleNotifications(bool value) {
    AppLogger.action('toggle_notifications', feature: FeatureTag.profile, data: {'value': value});
    _notificationsEnabled.value = value;
    _saveNotificationSettings();
  }
  
  /// Alterna notificações do app
  void toggleAppNotifications(bool value) {
    AppLogger.action('toggle_app_notifications', feature: FeatureTag.profile, data: {'value': value});
    _appNotificationsEnabled.value = value;
    _saveNotificationSettings();
  }
  
  /// Salva configurações de notificação
  void _saveNotificationSettings() async {
    final opId = AppLogger.startOp(FeatureTag.profile, 'save_notification_settings');
    
    try {
      await _settingsService.saveNotificationsEnabled(_notificationsEnabled.value);
      await _settingsService.saveAppNotificationsEnabled(_appNotificationsEnabled.value);
      
      AppLogger.completeOp(opId, message: 'Configurações de notificação salvas');
      
      Get.snackbar(
        'Configurações',
        'Configurações de notificação atualizadas',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao salvar configurações de notificação', exception: e);
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
    AppLogger.action('show_language_selector', feature: FeatureTag.profile);
    
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
                  ? const Icon(Icons.check, color: AppColors.colorSuccess)
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
    AppLogger.action('show_country_selector', feature: FeatureTag.profile);
    
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
                  ? const Icon(Icons.check, color: AppColors.colorSuccess)
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
    final opId = AppLogger.startOp(FeatureTag.profile, 'save_language_settings');
    
    try {
      await _settingsService.saveCurrentLanguage(_currentLanguage.value);
      
      AppLogger.completeOp(opId, message: 'Idioma alterado', data: {
        'language': _currentLanguage.value,
      });
      
      Get.snackbar(
        'Idioma',
        'Idioma alterado para ${_currentLanguage.value}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao salvar idioma', exception: e);
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
    final opId = AppLogger.startOp(FeatureTag.profile, 'save_country_settings');
    
    try {
      await _settingsService.saveCurrentCountry(_currentCountry.value);
      
      AppLogger.completeOp(opId, message: 'País alterado', data: {
        'country': _currentCountry.value,
      });
      
      Get.snackbar(
        'País',
        'País alterado para ${_currentCountry.value}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao salvar país', exception: e);
      Get.snackbar(
        'Erro',
        'Erro ao salvar configuração de país',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Mostra o onboarding novamente (para testes)
  Future<void> showOnboardingAgain() async {
    AppLogger.action('show_onboarding_again', feature: FeatureTag.profile);
    
    try {
      final secureStorage = Get.find<SecureStorage>();
      
      // Remove a flag de onboarding completado
      await secureStorage.delete(AppConstants.onboardingKey);
      
      AppLogger.info(FeatureTag.profile, 'Onboarding resetado - redirecionando');
      
      // Navega para o onboarding
      Get.offAllNamed(AppRoutes.onboarding);
    } catch (e) {
      AppLogger.error(FeatureTag.profile, 'Erro ao resetar onboarding', error: e);
      Get.snackbar(
        'Erro',
        'Erro ao abrir onboarding: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
