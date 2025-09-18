import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/onboarding_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/buttons/app_button.dart';

class OnboardingPage extends GetView<OnboardingController> {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C2C2E),
              Color(0xFF1C1C1E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildPageView(),
              ),
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
        // Logo
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Image.asset(
            'assets/icons/55d4ebc6-2cb3-4cf9-8c64-c3059b1207e2.png',
            width: 40.w,
            height: 40.w,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
          ),
        ),
          
          // Skip button
          Obx(() => controller.isLastPage.value
              ? const SizedBox.shrink()
              : TextButton(
                  onPressed: controller.skipOnboarding,
                  child: Text(
                    'Pular',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: controller.pageController,
      onPageChanged: controller.onPageChanged,
      itemCount: controller.pages.length,
      itemBuilder: (context, index) {
        final page = controller.pages[index];
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 40.h),
              
              // Illustration
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Center(
                    child: _buildPageIcon(index),
                  ),
                ),
              ),
              
              SizedBox(height: 40.h),
              
              // Content
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Title
                      Text(
                        page.title,
                        style: AppTextStyles.headline1.copyWith(
                          fontSize: 24.sp, // Reduzido de 28.sp para 24.sp
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 8.h), // Reduzido de 12.h para 8.h
                      
                      // Subtitle
                      Text(
                        page.subtitle,
                        style: AppTextStyles.subtitle1.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp, // Adicionado tamanho específico
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 16.h), // Reduzido de 20.h para 16.h
                      
                      // Description
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Text(
                          page.description,
                          style: AppTextStyles.body1.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5, // Reduzido de 1.6 para 1.5
                            fontSize: 14.sp, // Adicionado tamanho específico
                          ),
                          textAlign: TextAlign.center,
                          maxLines: null, // Permite múltiplas linhas
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          // Page indicators
          _buildPageIndicators(),
          
          SizedBox(height: 32.h),
          
          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Obx(() => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        controller.pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: controller.currentPage.value == index ? 24.w : 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: controller.currentPage.value == index
                ? AppColors.primary
                : AppColors.textSecondary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
      ),
    ));
  }

  Widget _buildNavigationButtons() {
    return Obx(() {
      if (controller.isLastPage.value) {
        return AppButton(
          text: 'Começar',
          onPressed: controller.completeOnboarding,
          icon: Icons.arrow_forward,
          color: AppColors.primary,
        );
      }

      return Row(
        children: [
          // Previous button
          if (controller.currentPage.value > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: controller.previousPage,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.textSecondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  'Anterior',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          
          if (controller.currentPage.value > 0) SizedBox(width: 16.w),
          
          // Next button
          Expanded(
            child: AppButton(
              text: 'Próximo',
              onPressed: controller.nextPage,
              icon: Icons.arrow_forward,
              color: AppColors.primary,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPageIcon(int index) {
    switch (index) {
      case 0:
        // Primeira tela: Logo do app
        return Image.asset(
          'assets/icons/55d4ebc6-2cb3-4cf9-8c64-c3059b1207e2.png',
          width: 120.w,
          height: 120.w,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.account_balance_wallet_outlined,
            size: 120.sp,
            color: AppColors.primary,
          ),
        );
      case 1:
        // Segunda tela: Ícone de categorização automática
        return Icon(
          Icons.auto_awesome_outlined,
          size: 120.sp,
          color: AppColors.primary,
        );
      case 2:
        // Terceira tela: Ícone de gerenciamento
        return Icon(
          Icons.category_outlined,
          size: 120.sp,
          color: AppColors.primary,
        );
      case 3:
        // Quarta tela: Ícone de relatórios
        return Icon(
          Icons.analytics_outlined,
          size: 120.sp,
          color: AppColors.primary,
        );
      default:
        return Icon(
          Icons.star_outline,
          size: 120.sp,
          color: AppColors.primary,
        );
    }
  }
}
