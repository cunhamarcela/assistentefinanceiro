import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../controllers/change_password_controller.dart';

class ChangePasswordPage extends GetView<ChangePasswordController> {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.surface,
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              'Alterar Senha',
              style: AppTextStyles.headline2,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Para balancear o botão de voltar
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xl),
            
            // Ícone de segurança
            Center(
              child: Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Descrição
            Text(
              'Para sua segurança, digite sua senha atual e depois a nova senha.',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Campo Senha Atual
            Text(
              'Senha Atual',
              style: AppTextStyles.subtitle2Dark,
            ),
            const SizedBox(height: AppSpacing.xs),
            Obx(() => AppTextField.password(
              controller: controller.currentPasswordController,
              hint: 'Digite sua senha atual',
              obscureText: controller.obscureCurrentPassword.value,
              validator: controller.validateCurrentPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  controller.obscureCurrentPassword.value
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: AppColors.textSecondary,
                ),
                onPressed: controller.toggleCurrentPasswordVisibility,
              ),
            )),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Campo Nova Senha
            Text(
              'Nova Senha',
              style: AppTextStyles.subtitle2Dark,
            ),
            const SizedBox(height: AppSpacing.xs),
            Obx(() => AppTextField.password(
              controller: controller.newPasswordController,
              hint: 'Digite sua nova senha',
              obscureText: controller.obscureNewPassword.value,
              validator: controller.validateNewPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  controller.obscureNewPassword.value
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: AppColors.textSecondary,
                ),
                onPressed: controller.toggleNewPasswordVisibility,
              ),
            )),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Campo Confirmar Nova Senha
            Text(
              'Confirmar Nova Senha',
              style: AppTextStyles.subtitle2Dark,
            ),
            const SizedBox(height: AppSpacing.xs),
            Obx(() => AppTextField.password(
              controller: controller.confirmPasswordController,
              hint: 'Confirme sua nova senha',
              obscureText: controller.obscureConfirmPassword.value,
              validator: controller.validateConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  controller.obscureConfirmPassword.value
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: AppColors.textSecondary,
                ),
                onPressed: controller.toggleConfirmPasswordVisibility,
              ),
            )),
            
            const SizedBox(height: AppSpacing.sm),
            
            // Dicas de senha
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.info.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sua senha deve ter:',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '• Pelo menos 6 caracteres\n• Pelo menos uma letra maiúscula\n• Pelo menos um número',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Botão Alterar Senha
            Obx(() => AppButton(
              text: 'Alterar Senha',
              onPressed: controller.changePassword,
              loading: controller.isLoading,
            )),
            
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
