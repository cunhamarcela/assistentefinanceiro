import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/logging_service.dart';

class AuthController extends GetxController {
  late final AuthService _authService;

  // Form keys
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> registerFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> forgotPasswordFormKey = GlobalKey<FormState>();

  // Text controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Observables
  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;
  final RxBool rememberMe = false.obs;
  final RxBool? acceptTerms = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;

  // Getters
  UserModel? get currentUser => _authService.currentUser;
  bool get isAuthenticated => _authService.isAuthenticated;
  bool get isEmailVerified => _authService.isEmailVerified;

  @override
  void onInit() {
    super.onInit();
    AppLogger.info(FeatureTag.auth, '🔐 AuthController inicializando');
    
    _authService = Get.find<AuthService>();
    _loadLastEmail();
    
    // Escutar mudanças no estado de autenticação
    _authService.authStateChanges.listen((user) {
      AppLogger.debug(FeatureTag.auth, 'Auth state changed', data: {
        'has_user': user != null && user.isNotEmpty,
        'current_route': Get.currentRoute,
      });
      
      if (user != null && user.isNotEmpty) {
        // Usuário autenticado, redirecionar para home
        Future.delayed(const Duration(milliseconds: 100), () {
          if (Get.currentRoute == AppRoutes.login || 
              Get.currentRoute == AppRoutes.register) {
            AppLogger.navigate(Get.currentRoute, AppRoutes.home, params: {'reason': 'auth_state_change'});
            Get.offAllNamed(AppRoutes.home);
          }
        });
      }
    });
    
    AppLogger.info(FeatureTag.auth, '✅ AuthController inicializado');
  }

  @override
  void onClose() {
    AppLogger.debug(FeatureTag.auth, 'AuthController disposing');
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  /// Carregar último email usado
  Future<void> _loadLastEmail() async {
    final opId = AppLogger.startOp(FeatureTag.auth, 'load_last_email');
    
    try {
      final secureStorage = Get.find<SecureStorage>();
      final lastEmail = await secureStorage.getLastEmail();
      if (lastEmail != null) {
        emailController.text = lastEmail;
        AppLogger.debug(FeatureTag.auth, 'Último email carregado', data: {'email_length': lastEmail.length});
      }
      
      final remember = await secureStorage.getRememberMe();
      rememberMe.value = remember;
      
      AppLogger.completeOp(opId, data: {'has_last_email': lastEmail != null, 'remember_me': remember});
    } catch (e) {
      AppLogger.failOp(opId, 'Erro ao carregar último email', exception: e);
    }
  }

  /// Login com email e senha
  Future<void> loginWithEmail() async {
    final opId = AppLogger.startOp(FeatureTag.auth, 'login_email');
    AppLogger.authLogin('email');
    
    try {
      if (!loginFormKey.currentState!.validate()) {
        AppLogger.warning(FeatureTag.auth, 'Login: formulário inválido');
        AppLogger.failOp(opId, 'Formulário inválido');
        return;
      }

      clearMessages();
      AppLogger.state(FeatureTag.auth, 'login_in_progress');
      
      await _authService.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      if (rememberMe.value) {
        final secureStorage = Get.find<SecureStorage>();
        await secureStorage.setRememberMe(true);
        AppLogger.debug(FeatureTag.auth, 'Remember me salvo');
      }

      successMessage.value = 'Login realizado com sucesso!';
      AppLogger.authSuccess('email', userId: currentUser?.id);
      AppLogger.completeOp(opId, message: 'Login email bem sucedido');
      
      // Navegar para home após delay para mostrar mensagem
      await Future.delayed(const Duration(milliseconds: 500));
      _handleSuccessfulLogin();
      
    } on AuthException catch (e) {
      errorMessage.value = e.message;
      AppLogger.authError('email', e.code ?? 'unknown', error: e);
      AppLogger.failOp(opId, e.message);
    } catch (e) {
      errorMessage.value = 'Erro inesperado durante o login';
      AppLogger.authError('email', 'unexpected_error', error: e);
      AppLogger.failOp(opId, 'Erro inesperado', exception: e);
    }
  }

  /// Registro com email e senha
  Future<void> registerWithEmail() async {
    final opId = AppLogger.startOp(FeatureTag.auth, 'register_email');
    AppLogger.info(FeatureTag.auth, '📝 Iniciando registro com email');
    
    try {
      if (!registerFormKey.currentState!.validate()) {
        AppLogger.warning(FeatureTag.auth, 'Registro: formulário inválido');
        AppLogger.failOp(opId, 'Formulário inválido');
        return;
      }

      clearMessages();
      AppLogger.state(FeatureTag.auth, 'register_in_progress');
      
      await _authService.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
        name: nameController.text,
      );

      successMessage.value = 'Conta criada com sucesso! Verifique seu email.';
      AppLogger.info(FeatureTag.auth, '✅ Conta criada com sucesso', data: {
        'email_verified': false,
        'user_id': currentUser?.id,
      });
      AppLogger.completeOp(opId, message: 'Registro email bem sucedido');
      
      // Navegar para home após delay
      await Future.delayed(const Duration(milliseconds: 1500));
      _handleSuccessfulLogin();
      
    } on AuthException catch (e) {
      errorMessage.value = e.message;
      AppLogger.authError('email_register', e.code ?? 'unknown', error: e);
      AppLogger.failOp(opId, e.message);
    } catch (e) {
      errorMessage.value = 'Erro inesperado durante o registro';
      AppLogger.authError('email_register', 'unexpected_error', error: e);
      AppLogger.failOp(opId, 'Erro inesperado', exception: e);
    }
  }

  /// Login com Google
  Future<void> loginWithGoogle() async {
    final opId = AppLogger.startOp(FeatureTag.auth, 'login_google');
    AppLogger.authLogin('google');
    
    try {
      clearMessages();
      AppLogger.state(FeatureTag.auth, 'google_login_in_progress');
      
      await _authService.signInWithGoogle();
      
      successMessage.value = 'Login com Google realizado com sucesso!';
      AppLogger.authSuccess('google', userId: currentUser?.id);
      AppLogger.completeOp(opId, message: 'Login Google bem sucedido');
      
      // Forçar redirecionamento após sucesso
      await Future.delayed(const Duration(milliseconds: 300));
      _handleSuccessfulLogin();
      
    } on AuthException catch (e) {
      errorMessage.value = e.message;
      AppLogger.authError('google', e.code ?? 'unknown', error: e);
      AppLogger.failOp(opId, e.message);
    } catch (e) {
      errorMessage.value = 'Erro inesperado durante login com Google';
      AppLogger.authError('google', 'unexpected_error', error: e);
      AppLogger.failOp(opId, 'Erro inesperado', exception: e);
    }
  }

  /// Login com Apple
  Future<void> loginWithApple() async {
    final opId = AppLogger.startOp(FeatureTag.auth, 'login_apple');
    AppLogger.authLogin('apple');
    
    try {
      clearMessages();
      
      // Primeiro, testar a configuração
      AppLogger.debug(FeatureTag.auth, 'Testando configuração Apple Sign-In');
      final testResult = await _authService.testAppleSignInConfiguration();
      
      AppLogger.debug(FeatureTag.auth, 'Resultado teste Apple Sign-In', data: testResult);
      
      if (testResult['error'] != null) {
        AppLogger.warning(FeatureTag.auth, 'Apple Sign-In não disponível', data: testResult);
        
        // Mostrar erro mais específico baseado no problema
        if (testResult['error'].toString().contains('não está disponível')) {
          errorMessage.value = 'Apple Sign-In requer:\n• Dispositivo iOS físico OU\n• Simulador iOS 13+ OU\n• Configuração no Firebase Console';
        } else {
          errorMessage.value = testResult['error'];
        }
        
        AppLogger.failOp(opId, 'Apple Sign-In não configurado');
        return;
      }
      
      AppLogger.state(FeatureTag.auth, 'apple_login_in_progress');
      await _authService.signInWithApple();
      
      successMessage.value = 'Login com Apple realizado com sucesso!';
      AppLogger.authSuccess('apple', userId: currentUser?.id);
      AppLogger.completeOp(opId, message: 'Login Apple bem sucedido');
      
      // Forçar redirecionamento após sucesso
      await Future.delayed(const Duration(milliseconds: 300));
      _handleSuccessfulLogin();
      
    } on AuthException catch (e) {
      errorMessage.value = e.message;
      AppLogger.authError('apple', e.code ?? 'unknown', error: e);
      AppLogger.failOp(opId, e.message);
    } catch (e) {
      errorMessage.value = 'Erro inesperado durante login com Apple';
      AppLogger.authError('apple', 'unexpected_error', error: e);
      AppLogger.failOp(opId, 'Erro inesperado', exception: e);
    }
  }

  /// Lidar com login bem-sucedido
  void _handleSuccessfulLogin() {
    if (_authService.isAuthenticated) {
      AppLogger.navigate(Get.currentRoute, AppRoutes.home, params: {'reason': 'successful_login'});
      AppLogger.info(FeatureTag.auth, '🏠 Redirecionando para home após login');
      Get.offAllNamed(AppRoutes.home);
    } else {
      AppLogger.warning(FeatureTag.auth, '⚠️ handleSuccessfulLogin chamado mas usuário não autenticado');
    }
  }

  /// Recuperação de senha
  Future<void> sendPasswordReset() async {
    final opId = AppLogger.startOp(FeatureTag.auth, 'password_reset');
    AppLogger.info(FeatureTag.auth, '📧 Iniciando recuperação de senha');
    
    try {
      if (!forgotPasswordFormKey.currentState!.validate()) {
        AppLogger.warning(FeatureTag.auth, 'Password reset: formulário inválido');
        AppLogger.failOp(opId, 'Formulário inválido');
        return;
      }

      clearMessages();
      
      await _authService.sendPasswordResetEmail(emailController.text);
      
      successMessage.value = 'Email de recuperação enviado! Verifique sua caixa de entrada.';
      AppLogger.info(FeatureTag.auth, '✅ Email de recuperação enviado', data: {
        'email_length': emailController.text.length,
      });
      AppLogger.completeOp(opId, message: 'Email de recuperação enviado');
      
      // Voltar para login após delay
      await Future.delayed(const Duration(milliseconds: 2000));
      Get.back();
      
    } on AuthException catch (e) {
      errorMessage.value = e.message;
      AppLogger.authError('password_reset', e.code ?? 'unknown', error: e);
      AppLogger.failOp(opId, e.message);
    } catch (e) {
      errorMessage.value = 'Erro ao enviar email de recuperação';
      AppLogger.authError('password_reset', 'unexpected_error', error: e);
      AppLogger.failOp(opId, 'Erro inesperado', exception: e);
    }
  }

  /// Enviar verificação de email
  Future<void> sendEmailVerification() async {
    final opId = AppLogger.startOp(FeatureTag.auth, 'email_verification');
    AppLogger.info(FeatureTag.auth, '📧 Enviando verificação de email');
    
    try {
      clearMessages();
      
      await _authService.sendEmailVerification();
      
      successMessage.value = 'Email de verificação enviado!';
      AppLogger.completeOp(opId, message: 'Email de verificação enviado');
      
    } on AuthException catch (e) {
      errorMessage.value = e.message;
      AppLogger.failOp(opId, e.message);
    } catch (e) {
      errorMessage.value = 'Erro ao enviar email de verificação';
      AppLogger.failOp(opId, 'Erro inesperado', exception: e);
    }
  }

  /// Recarregar dados do usuário
  Future<void> reloadUser() async {
    AppLogger.debug(FeatureTag.auth, 'Recarregando dados do usuário');
    
    try {
      await _authService.reloadUser();
      AppLogger.debug(FeatureTag.auth, 'Dados do usuário recarregados', data: {
        'email_verified': isEmailVerified,
        'user_id': currentUser?.id,
      });
      update(); // Atualizar UI
    } catch (e) {
      errorMessage.value = 'Erro ao recarregar dados do usuário';
      AppLogger.error(FeatureTag.auth, 'Erro ao recarregar usuário', error: e);
    }
  }

  /// Logout
  Future<void> logout() async {
    final opId = AppLogger.startOp(FeatureTag.auth, 'logout');
    AppLogger.authLogout(reason: 'user_initiated');
    
    try {
      clearMessages();
      
      final userId = currentUser?.id;
      await _authService.signOut();
      
      // Limpar formulários
      clearForms();
      
      AppLogger.info(FeatureTag.auth, '✅ Logout realizado', data: {'previous_user': userId});
      AppLogger.completeOp(opId, message: 'Logout bem sucedido');
      
      // Navegar para login
      AppLogger.navigate(Get.currentRoute, AppRoutes.login, params: {'reason': 'logout'});
      Get.offAllNamed(AppRoutes.login);
      
    } catch (e) {
      errorMessage.value = 'Erro durante logout';
      AppLogger.failOp(opId, 'Erro no logout', exception: e);
    }
  }

  /// Alternar visibilidade da senha
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  /// Alternar visibilidade da confirmação de senha
  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  /// Alternar "Lembrar de mim"
  void toggleRememberMe() {
    rememberMe.value = !rememberMe.value;
    AppLogger.action('toggle_remember_me', feature: FeatureTag.auth, data: {'value': rememberMe.value});
  }

  /// Limpar mensagens
  void clearMessages() {
    errorMessage.value = '';
    successMessage.value = '';
  }

  /// Limpar formulários
  void clearForms() {
    emailController.clear();
    passwordController.clear();
    nameController.clear();
    confirmPasswordController.clear();
    clearMessages();
    AppLogger.debug(FeatureTag.auth, 'Formulários limpos');
  }

  /// Navegar para registro
  void goToRegister() {
    clearMessages();
    AppLogger.navigate(Get.currentRoute, AppRoutes.register);
    Get.toNamed(AppRoutes.register);
  }

  /// Navegar para login
  void goToLogin() {
    clearMessages();
    AppLogger.navigate(Get.currentRoute, AppRoutes.login);
    Get.toNamed(AppRoutes.login);
  }

  /// Navegar para recuperação de senha
  void goToForgotPassword() {
    clearMessages();
    AppLogger.navigate(Get.currentRoute, AppRoutes.forgotPassword);
    Get.toNamed(AppRoutes.forgotPassword);
  }

  /// Voltar para tela anterior
  void goBack() {
    clearMessages();
    Get.back();
  }

  // ==================== VALIDADORES ====================

  /// Validador de email
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }
    
    return null;
  }

  /// Validador de senha
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    
    if (value.length < 6) {
      return 'Senha deve ter pelo menos 6 caracteres';
    }
    
    if (value.length > 128) {
      return 'Senha muito longa (máximo 128 caracteres)';
    }
    
    return null;
  }

  /// Validador de confirmação de senha
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirmação de senha é obrigatória';
    }
    
    if (value != passwordController.text) {
      return 'Senhas não coincidem';
    }
    
    return null;
  }

  /// Validador de nome
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nome é obrigatório';
    }
    
    if (value.trim().length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }
    
    if (value.length > 100) {
      return 'Nome muito longo (máximo 100 caracteres)';
    }
    
    return null;
  }

  // ==================== HELPERS ====================

  /// Verificar se há mensagem de erro
  bool get hasError => errorMessage.value.isNotEmpty;

  /// Verificar se há mensagem de sucesso
  bool get hasSuccess => successMessage.value.isNotEmpty;

  /// Verificar se os formulários estão válidos
  bool get isLoginFormValid {
    return emailController.text.isNotEmpty && 
           passwordController.text.isNotEmpty &&
           validateEmail(emailController.text) == null &&
           validatePassword(passwordController.text) == null;
  }

  bool get isRegisterFormValid {
    return nameController.text.isNotEmpty &&
           emailController.text.isNotEmpty && 
           passwordController.text.isNotEmpty &&
           confirmPasswordController.text.isNotEmpty &&
           validateName(nameController.text) == null &&
           validateEmail(emailController.text) == null &&
           validatePassword(passwordController.text) == null &&
           validateConfirmPassword(confirmPasswordController.text) == null;
  }

  bool get isForgotPasswordFormValid {
    return emailController.text.isNotEmpty &&
           validateEmail(emailController.text) == null;
  }

  /// Mostrar snackbar de erro
  void showErrorSnackbar(String message) {
    Get.snackbar(
      'Erro',
      message,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.error_outline, color: Colors.red),
      duration: const Duration(seconds: 4),
      snackPosition: SnackPosition.TOP,
    );
  }

  /// Mostrar snackbar de sucesso
  void showSuccessSnackbar(String message) {
    Get.snackbar(
      'Sucesso',
      message,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle_outline, color: Colors.green),
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
    );
  }
}
