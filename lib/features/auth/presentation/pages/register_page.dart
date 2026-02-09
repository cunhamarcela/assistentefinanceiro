import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';

class RegisterPage extends GetView<AuthController> {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.colorBrandPrimary,
              AppColors.colorBrandDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header com imagem de fundo
              _buildBackgroundHeader(),
              
              // Card de registro
              Expanded(
                child: _buildRegisterCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundHeader() {
    return Container(
      height: 200.h,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern/image placeholder
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30.r),
                  bottomRight: Radius.circular(30.r),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.person_add_outlined,
                  size: 60.sp,
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
            ),
          ),
          
          // Back button
          Positioned(
            top: 20.h,
            left: 24.w,
            child: IconButton(
              onPressed: () => Get.back(),
              icon: Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary,
                size: 24.sp,
              ),
            ),
          ),
          
          // App logo and title
          Positioned(
            top: 20.h,
            right: 24.w,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.asset(
                    'assets/icons/55d4ebc6-2cb3-4cf9-8c64-c3059b1207e2.png',
                    width: 32.w,
                    height: 32.w,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.colorTextOnDark,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Assistente Financeiro',
                  style: AppTextStyles.subtitle1.copyWith(
                    color: AppColors.colorTextOnDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Welcome text
          Positioned(
            bottom: 30.h,
            left: 24.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Criar Conta',
                  style: AppTextStyles.headline1.copyWith(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.colorTextOnDark,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Comece sua jornada financeira.',
                  style: AppTextStyles.subtitle1.copyWith(
                    color: AppColors.colorTextOnDark.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterCard() {
    return Container(
      margin: EdgeInsets.only(top: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.r),
          topRight: Radius.circular(30.r),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: controller.registerFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 8.h),
              
              // Título do card
              Text(
                'Criar sua conta',
                style: AppTextStyles.headline2.copyWith(
                  color: AppColors.textDark,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 32.h),
              
              // Campo de nome
              _buildNameField(),
              SizedBox(height: 16.h),
              
              // Campo de email
              _buildEmailField(),
              SizedBox(height: 16.h),
              
              // Campo de senha
              _buildPasswordField(),
              
              SizedBox(height: 16.h),
              
              // Campo de confirmar senha
              _buildConfirmPasswordField(),
              
              SizedBox(height: 16.h),
              
              // Termos e condições
              _buildTermsCheckbox(),
              
              SizedBox(height: 32.h),
              
              // Botão de registro
              _buildRegisterButton(),
              
              SizedBox(height: 24.h),
              
              // Divisor
              _buildDivider(),
              
              SizedBox(height: 24.h),
              
              // Registro com Google
              _buildGoogleButton(),
              
              SizedBox(height: 16.h),
              
              // Registro com Apple
              _buildAppleButton(),
              
              SizedBox(height: 32.h),
              
              // Link para login
              _buildLoginLink(),
              
              SizedBox(height: 24.h),
              
              // Mensagens de erro/sucesso
              _buildMessages(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nome completo',
          style: AppTextStyles.body1.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        AppTextField(
          controller: controller.nameController,
          validator: controller.validateName,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: AppTextStyles.body1.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        AppTextField.email(
          controller: controller.emailController,
          validator: controller.validateEmail,
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Senha',
          style: AppTextStyles.body1.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Obx(() => AppTextField.password(
          controller: controller.passwordController,
          obscureText: controller.obscurePassword.value,
          suffixIcon: IconButton(
            onPressed: controller.togglePasswordVisibility,
            icon: Icon(
              controller.obscurePassword.value 
                  ? Icons.visibility_outlined 
                  : Icons.visibility_off_outlined,
              color: AppColors.textSecondary,
            ),
          ),
          validator: controller.validatePassword,
        )),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirmar senha',
          style: AppTextStyles.body1.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Obx(() => AppTextField.password(
          controller: controller.confirmPasswordController,
          obscureText: controller.obscureConfirmPassword.value,
          suffixIcon: IconButton(
            onPressed: controller.toggleConfirmPasswordVisibility,
            icon: Icon(
              controller.obscureConfirmPassword.value 
                  ? Icons.visibility_outlined 
                  : Icons.visibility_off_outlined,
              color: AppColors.textSecondary,
            ),
          ),
          validator: controller.validateConfirmPassword,
          onFieldSubmitted: (_) => controller.registerWithEmail(),
        )),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Obx(() => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: controller.acceptTerms?.value ?? false,
          onChanged: (value) => controller.acceptTerms?.value = value ?? false,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          activeColor: AppColors.primary,
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 12.h),
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
                children: [
                  const TextSpan(text: 'Concordo com os '),
                  TextSpan(
                    text: 'Termos de Uso',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(text: ' e '),
                  TextSpan(
                    text: 'Política de Privacidade',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ));
  }

  Widget _buildRegisterButton() {
    return Obx(() => Container(
      height: 56.h,
      child: ElevatedButton(
        onPressed: controller.isLoading.value ? null : controller.registerWithEmail,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 0,
        ),
        child: controller.isLoading.value
            ? SizedBox(
                width: 24.w,
                height: 24.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Criar Conta',
                style: AppTextStyles.button.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    ));
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'ou',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return Obx(() => Container(
      height: 56.h,
      child: OutlinedButton.icon(
        onPressed: controller.isLoading.value ? null : controller.loginWithGoogle,
        icon: controller.isLoading.value 
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.g_mobiledata,
                size: 24.sp,
                color: Colors.red,
              ),
        label: Text(
          'Registrar com Google',
          style: AppTextStyles.button.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
            fontSize: 16.sp,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: AppColors.divider, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    ));
  }

  Widget _buildAppleButton() {
    return Obx(() => Container(
      height: 56.h,
      child: OutlinedButton.icon(
        onPressed: controller.isLoading.value ? null : controller.loginWithApple,
        icon: controller.isLoading.value 
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.apple,
                size: 24.sp,
                color: AppColors.textDark,
              ),
        label: Text(
          'Registrar com Apple',
          style: AppTextStyles.button.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
            fontSize: 16.sp,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: AppColors.divider, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    ));
  }


  Widget _buildMessages() {
    return Obx(() {
      if (controller.hasError) {
        return Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.error.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  controller.errorMessage.value,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      
      if (controller.hasSuccess) {
        return Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  controller.successMessage.value,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      
      return const SizedBox.shrink();
    });
  }

  Widget _buildLoginLink() {
    return Center(
      child: TextButton(
        onPressed: () => Get.toNamed(AppRoutes.login),
        child: RichText(
          text: TextSpan(
            text: 'Já tem uma conta? ',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
            ),
            children: [
              TextSpan(
                text: 'Entrar',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
