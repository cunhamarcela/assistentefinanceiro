import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class ForgotPasswordPage extends GetView<AuthController> {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Senha'),
        centerTitle: true,
        leading: IconButton(
          onPressed: controller.goBack,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: controller.forgotPasswordFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40.h),
                
                // Header
                _buildHeader(),
                
                SizedBox(height: 40.h),
                
                // Campo de email
                _buildEmailField(),
                
                SizedBox(height: 32.h),
                
                // Botão de enviar
                _buildSendButton(),
                
                SizedBox(height: 24.h),
                
                // Informações adicionais
                _buildInfoCard(),
                
                SizedBox(height: 32.h),
                
                // Link para voltar ao login
                _buildBackToLoginLink(),
                
                SizedBox(height: 24.h),
                
                // Mensagens de erro/sucesso
                _buildMessages(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Ícone
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            color: Get.theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Icon(
            Icons.lock_reset_outlined,
            size: 40.sp,
            color: Get.theme.primaryColor,
          ),
        ),
        
        SizedBox(height: 24.h),
        
        // Título
        Text(
          'Esqueceu sua senha?',
          style: Get.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Get.theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: 12.h),
        
        // Subtítulo
        Text(
          'Não se preocupe! Digite seu email abaixo e enviaremos um link para redefinir sua senha.',
          style: Get.textTheme.bodyLarge?.copyWith(
            color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return CustomTextField(
      controller: controller.emailController,
      label: 'Email',
      hint: 'Digite seu email cadastrado',
      keyboardType: TextInputType.emailAddress,
      prefixIcon: Icons.email_outlined,
      validator: controller.validateEmail,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => controller.sendPasswordReset(),
      autofocus: true,
    );
  }

  Widget _buildSendButton() {
    return Obx(() => CustomButton(
      text: 'Enviar Link de Recuperação',
      onPressed: controller.isLoading.value ? null : controller.sendPasswordReset,
      isLoading: controller.isLoading.value,
      icon: Icons.send_outlined,
    ));
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Get.theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20.sp,
                color: Get.theme.primaryColor,
              ),
              SizedBox(width: 8.w),
              Text(
                'Como funciona?',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Get.theme.primaryColor,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          _buildInfoItem(
            '1.',
            'Digite o email da sua conta',
          ),
          
          SizedBox(height: 8.h),
          
          _buildInfoItem(
            '2.',
            'Verifique sua caixa de entrada',
          ),
          
          SizedBox(height: 8.h),
          
          _buildInfoItem(
            '3.',
            'Clique no link recebido por email',
          ),
          
          SizedBox(height: 8.h),
          
          _buildInfoItem(
            '4.',
            'Defina uma nova senha',
          ),
          
          SizedBox(height: 12.h),
          
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  size: 16.sp,
                  color: Colors.amber.shade700,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Verifique também a pasta de spam',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20.w,
          height: 20.w,
          decoration: BoxDecoration(
            color: Get.theme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: Get.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Get.theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackToLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.arrow_back,
          size: 16.sp,
          color: Get.theme.primaryColor,
        ),
        SizedBox(width: 4.w),
        TextButton(
          onPressed: controller.goToLogin,
          child: Text(
            'Voltar para o login',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Get.theme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessages() {
    return Obx(() {
      if (controller.hasError) {
        return Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade700,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  controller.errorMessage.value,
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: Colors.red.shade700,
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
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green.shade700,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      controller.successMessage.value,
                      style: Get.textTheme.bodyMedium?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'O link expira em 1 hora por segurança.',
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
        );
      }
      
      return const SizedBox.shrink();
    });
  }
}
