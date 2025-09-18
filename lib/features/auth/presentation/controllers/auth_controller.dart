import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/secure_storage.dart';

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
    _authService = Get.find<AuthService>();
    _loadLastEmail();
    
    // Escutar mudanças no estado de autenticação
    _authService.authStateChanges.listen((user) {
      if (user != null && user.isNotEmpty) {
        // Usuário autenticado, redirecionar para home
        Future.delayed(const Duration(milliseconds: 100), () {
          if (Get.currentRoute == AppRoutes.login || 
              Get.currentRoute == AppRoutes.register) {
            Get.offAllNamed(AppRoutes.home);
          }
        });
      }
    });
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  /// Carregar último email usado
  Future<void> _loadLastEmail() async {
    try {
      final secureStorage = Get.find<SecureStorage>();
      final lastEmail = await secureStorage.getLastEmail();
      if (lastEmail != null) {
        emailController.text = lastEmail;
      }
      
      final remember = await secureStorage.getRememberMe();
      rememberMe.value = remember;
    } catch (e) {
      print('Erro ao carregar último email: $e');
    }
  }

  /// Login com email e senha
  Future<void> loginWithEmail() async {
    try {
      if (!loginFormKey.currentState!.validate()) return;

      clearMessages();
      
      await _authService.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      if (rememberMe.value) {
        final secureStorage = Get.find<SecureStorage>();
        await secureStorage.setRememberMe(true);
      }

      successMessage.value = 'Login realizado com sucesso!';
      
      // Navegar para home após delay para mostrar mensagem
      await Future.delayed(const Duration(milliseconds: 500));
      _handleSuccessfulLogin();
      
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Erro inesperado durante o login';
    }
  }

  /// Registro com email e senha
  Future<void> registerWithEmail() async {
    try {
      if (!registerFormKey.currentState!.validate()) return;

      clearMessages();
      
      await _authService.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
        name: nameController.text,
      );

      successMessage.value = 'Conta criada com sucesso! Verifique seu email.';
      
      // Navegar para home após delay
      await Future.delayed(const Duration(milliseconds: 1500));
      _handleSuccessfulLogin();
      
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Erro inesperado durante o registro';
    }
  }

  /// Login com Google
  Future<void> loginWithGoogle() async {
    try {
      clearMessages();
      
      await _authService.signInWithGoogle();
      
      successMessage.value = 'Login com Google realizado com sucesso!';
      
      // Forçar redirecionamento após sucesso
      await Future.delayed(const Duration(milliseconds: 300));
      _handleSuccessfulLogin();
      
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Erro inesperado durante login com Google';
    }
  }

  /// Login com Apple
  Future<void> loginWithApple() async {
    try {
      clearMessages();
      
      // Primeiro, testar a configuração
      final testResult = await _authService.testAppleSignInConfiguration();
      print('Teste de configuração Apple Sign-In: $testResult');
      
      if (testResult['error'] != null) {
        // Mostrar erro mais específico baseado no problema
        if (testResult['error'].toString().contains('não está disponível')) {
          errorMessage.value = 'Apple Sign-In requer:\n• Dispositivo iOS físico OU\n• Simulador iOS 13+ OU\n• Configuração no Firebase Console';
        } else {
          errorMessage.value = testResult['error'];
        }
        
        // Mostrar sugestão se disponível
        if (testResult['suggestion'] != null) {
          print('Sugestão: ${testResult['suggestion']}');
        }
        return;
      }
      
      await _authService.signInWithApple();
      
      successMessage.value = 'Login com Apple realizado com sucesso!';
      
      // Forçar redirecionamento após sucesso
      await Future.delayed(const Duration(milliseconds: 300));
      _handleSuccessfulLogin();
      
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Erro inesperado durante login com Apple';
      print('Erro detalhado no Apple Sign-In: $e');
    }
  }

  /// Lidar com login bem-sucedido
  void _handleSuccessfulLogin() {
    if (_authService.isAuthenticated) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  /// Recuperação de senha
  Future<void> sendPasswordReset() async {
    try {
      if (!forgotPasswordFormKey.currentState!.validate()) return;

      clearMessages();
      
      await _authService.sendPasswordResetEmail(emailController.text);
      
      successMessage.value = 'Email de recuperação enviado! Verifique sua caixa de entrada.';
      
      // Voltar para login após delay
      await Future.delayed(const Duration(milliseconds: 2000));
      Get.back();
      
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Erro ao enviar email de recuperação';
    }
  }

  /// Enviar verificação de email
  Future<void> sendEmailVerification() async {
    try {
      clearMessages();
      
      await _authService.sendEmailVerification();
      
      successMessage.value = 'Email de verificação enviado!';
      
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Erro ao enviar email de verificação';
    }
  }

  /// Recarregar dados do usuário
  Future<void> reloadUser() async {
    try {
      await _authService.reloadUser();
      update(); // Atualizar UI
    } catch (e) {
      errorMessage.value = 'Erro ao recarregar dados do usuário';
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      clearMessages();
      
      await _authService.signOut();
      
      // Limpar formulários
      clearForms();
      
      // Navegar para login
      Get.offAllNamed(AppRoutes.login);
      
    } catch (e) {
      errorMessage.value = 'Erro durante logout';
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
  }

  /// Navegar para registro
  void goToRegister() {
    clearMessages();
    Get.toNamed(AppRoutes.register);
  }

  /// Navegar para login
  void goToLogin() {
    clearMessages();
    Get.toNamed(AppRoutes.login);
  }

  /// Navegar para recuperação de senha
  void goToForgotPassword() {
    clearMessages();
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
