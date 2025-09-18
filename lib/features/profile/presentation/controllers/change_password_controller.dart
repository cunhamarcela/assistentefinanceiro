import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../features/auth/data/services/auth_service.dart';

class ChangePasswordController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  
  // Form key
  final formKey = GlobalKey<FormState>();
  
  // Text controllers
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  // Observables
  final _isLoading = false.obs;
  final _obscureCurrentPassword = true.obs;
  final _obscureNewPassword = true.obs;
  final _obscureConfirmPassword = true.obs;
  
  // Getters
  bool get isLoading => _isLoading.value;
  RxBool get obscureCurrentPassword => _obscureCurrentPassword;
  RxBool get obscureNewPassword => _obscureNewPassword;
  RxBool get obscureConfirmPassword => _obscureConfirmPassword;
  
  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
  
  /// Alternar visibilidade da senha atual
  void toggleCurrentPasswordVisibility() {
    _obscureCurrentPassword.value = !_obscureCurrentPassword.value;
  }
  
  /// Alternar visibilidade da nova senha
  void toggleNewPasswordVisibility() {
    _obscureNewPassword.value = !_obscureNewPassword.value;
  }
  
  /// Alternar visibilidade da confirmação de senha
  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword.value = !_obscureConfirmPassword.value;
  }
  
  /// Validação da senha atual
  String? validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha atual é obrigatória';
    }
    if (value.length < 6) {
      return 'Senha deve ter pelo menos 6 caracteres';
    }
    return null;
  }
  
  /// Validação da nova senha
  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nova senha é obrigatória';
    }
    if (value.length < 6) {
      return 'Senha deve ter pelo menos 6 caracteres';
    }
    if (value == currentPasswordController.text) {
      return 'A nova senha deve ser diferente da atual';
    }
    if (!_hasUpperCase(value)) {
      return 'Senha deve ter pelo menos uma letra maiúscula';
    }
    if (!_hasNumber(value)) {
      return 'Senha deve ter pelo menos um número';
    }
    return null;
  }
  
  /// Validação da confirmação de senha
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirmação de senha é obrigatória';
    }
    if (value != newPasswordController.text) {
      return 'Senhas não coincidem';
    }
    return null;
  }
  
  /// Verifica se tem letra maiúscula
  bool _hasUpperCase(String password) {
    return password.contains(RegExp(r'[A-Z]'));
  }
  
  /// Verifica se tem número
  bool _hasNumber(String password) {
    return password.contains(RegExp(r'[0-9]'));
  }
  
  /// Alterar senha
  Future<void> changePassword() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    
    try {
      _isLoading.value = true;
      
      final currentPassword = currentPasswordController.text.trim();
      final newPassword = newPasswordController.text.trim();
      
      // Primeiro, reautenticar o usuário com a senha atual
      await _authService.reauthenticateWithPassword(currentPassword);
      
      // Depois, alterar para a nova senha
      await _authService.updatePassword(newPassword);
      
      Get.snackbar(
        'Sucesso',
        'Senha alterada com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        icon: const Icon(Icons.check_circle, color: Colors.green),
      );
      
      // Limpar campos
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      
      // Voltar para a tela anterior
      Get.back();
      
    } catch (e) {
      String errorMessage = 'Erro ao alterar senha';
      
      if (e.toString().contains('wrong-password')) {
        errorMessage = 'Senha atual incorreta';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'A nova senha é muito fraca';
      } else if (e.toString().contains('requires-recent-login')) {
        errorMessage = 'Por segurança, faça login novamente antes de alterar a senha';
      }
      
      Get.snackbar(
        'Erro',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      _isLoading.value = false;
    }
  }
}
