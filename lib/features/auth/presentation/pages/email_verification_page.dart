import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../../shared/widgets/custom_button.dart';

class EmailVerificationPage extends GetView<AuthController> {
  const EmailVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone
              Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  color: Get.theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50.r),
                ),
                child: Icon(
                  Icons.mark_email_unread_outlined,
                  size: 50.sp,
                  color: Get.theme.primaryColor,
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // Título
              Text(
                'Verifique seu email',
                style: Get.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Get.theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 16.h),
              
              // Descrição
              Text(
                'Enviamos um link de verificação para seu email. Clique no link para ativar sua conta.',
                style: Get.textTheme.bodyLarge?.copyWith(
                  color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 32.h),
              
              // Botão reenviar
              CustomButton(
                text: 'Reenviar Email',
                onPressed: controller.sendEmailVerification,
                icon: Icons.refresh,
                isOutlined: true,
              ),
              
              SizedBox(height: 16.h),
              
              // Botão verificar
              CustomButton(
                text: 'Já Verifiquei',
                onPressed: controller.reloadUser,
                icon: Icons.check_circle_outline,
              ),
              
              SizedBox(height: 32.h),
              
              // Link para logout
              TextButton(
                onPressed: controller.logout,
                child: Text(
                  'Sair da conta',
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: Get.theme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
