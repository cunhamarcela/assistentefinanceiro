import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../controllers/edit_profile_controller.dart';

class EditProfilePage extends GetView<EditProfileController> {
  const EditProfilePage({super.key});

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
      child: Column(
        children: [
          Row(
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
                  'Editar perfil',
                  style: AppTextStyles.headline2,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Para balancear o botão de voltar
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Obx(() {
      return Stack(
        children: [
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.accentGradient,
              border: Border.all(
                color: AppColors.textPrimary,
                width: 3,
              ),
            ),
            child: controller.user?.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      controller.user!.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildInitialsAvatar();
                      },
                    ),
                  )
                : _buildInitialsAvatar(),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 36.w,
              height: 36.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blue,
              ),
              child: IconButton(
                onPressed: controller.changePhoto,
                icon: const Icon(
                  Icons.camera_alt,
                  color: AppColors.textPrimary,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildInitialsAvatar() {
    return Center(
      child: Text(
        controller.initials,
        style: AppTextStyles.headline1.copyWith(
          fontSize: 48.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            
            // Campo Nome de Usuário
            Text(
              'Nome de Usuário',
              style: AppTextStyles.subtitle2Dark,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppTextField(
              controller: controller.usernameController,
              hint: 'Digite seu nome de usuário',
              prefixIcon: Icons.person,
              validator: controller.validateUsername,
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Campo Nome Completo
            Text(
              'Nome Completo',
              style: AppTextStyles.subtitle2Dark,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppTextField(
              controller: controller.fullNameController,
              hint: 'Digite seu nome completo',
              prefixIcon: Icons.badge,
              validator: controller.validateFullName,
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Campo Email
            Text(
              'Email',
              style: AppTextStyles.subtitle2Dark,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppTextField(
              controller: controller.emailController,
              hint: 'Digite seu email',
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              enabled: false, // Email não pode ser alterado
              validator: controller.validateEmail,
            ),
            
            const SizedBox(height: AppSpacing.sm),
            Text(
              'O email não pode ser alterado',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            
            const Spacer(),
            
            // Botão Salvar
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Obx(() => AppButton(
                text: 'Salvar',
                onPressed: controller.saveProfile,
                loading: controller.isLoading,
              )),
            ),
          ],
        ),
      ),
    );
  }
}
