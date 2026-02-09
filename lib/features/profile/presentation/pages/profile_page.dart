import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../controllers/profile_controller.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

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
            stops: [0.0, 0.4],
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
                  color: AppColors.colorTextOnDark,
                ),
              ),
              Expanded(
                child: Text(
                  'Perfil',
                  style: AppTextStyles.headline2.copyWith(
                    color: AppColors.colorTextOnDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Para balancear o botão de voltar
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildAvatar(),
          const SizedBox(height: AppSpacing.md),
          Obx(() => Text(
            controller.displayName,
            style: AppTextStyles.headline2.copyWith(
              color: AppColors.colorTextPrimary,
            ),
            textAlign: TextAlign.center,
          )),
          const SizedBox(height: AppSpacing.xs),
          Obx(() => Text(
            controller.user?.email ?? '',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.colorTextSecondary,
            ),
            textAlign: TextAlign.center,
          )),
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
                color: AppColors.colorTextOnDark,
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
                color: AppColors.colorBrandSoft,
              ),
              child: IconButton(
                onPressed: controller.goToEditProfile,
                icon: const Icon(
                  Icons.edit,
                  color: AppColors.colorTextOnDark,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          
          // Seção Conta
          _buildSection(
            title: 'Conta',
            icon: Icons.person,
            children: [
              _buildMenuItem(
                icon: Icons.edit,
                title: 'Editar perfil',
                onTap: controller.goToEditProfile,
              ),
              _buildMenuItem(
                icon: Icons.lock,
                title: 'Alterar senha',
                onTap: controller.goToChangePassword,
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Seção Notificações
          _buildSection(
            title: 'Notificações',
            icon: Icons.notifications,
            children: [
              Obx(() => _buildSwitchMenuItem(
                icon: Icons.notifications_active,
                title: 'Notificações',
                value: controller.notificationsEnabled.value,
                onChanged: controller.toggleNotifications,
              )),
              Obx(() => _buildSwitchMenuItem(
                icon: Icons.mobile_friendly,
                title: 'Notificações do app',
                value: controller.appNotificationsEnabled.value,
                onChanged: controller.toggleAppNotifications,
              )),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Seção Mais
          _buildSection(
            title: 'Mais',
            icon: Icons.more_horiz,
            children: [
              _buildMenuItem(
                icon: Icons.language,
                title: 'Idioma',
                subtitle: controller.currentLanguage.value,
                onTap: controller.showLanguageSelector,
              ),
              _buildMenuItem(
                icon: Icons.public,
                title: 'País',
                subtitle: controller.currentCountry.value,
                onTap: controller.showCountrySelector,
              ),
              _buildMenuItem(
                icon: Icons.play_circle_outline,
                title: 'Ver introdução do app',
                subtitle: 'Rever a tela de boas-vindas',
                onTap: controller.showOnboardingAgain,
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Botão de Logout
          Obx(() => AppButton.outlined(
            text: 'Logout',
            onPressed: controller.logout,
            loading: controller.isLoading,
            color: AppColors.colorBrandPrimary,
            textColor: AppColors.colorBrandPrimary,
          )),
          
          const SizedBox(height: AppSpacing.md),
          
          // Botão de Excluir Conta
          Obx(() => AppButton.outlined(
            text: 'Excluir Conta',
            onPressed: controller.deleteAccount,
            loading: controller.isLoading,
            color: AppColors.colorError,
            textColor: AppColors.colorError,
          )),
          
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: AppTextStyles.subtitle1Dark,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body1Dark,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchMenuItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.body1Dark,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
