import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../controllers/welcome_controller.dart';

/// Tokens utilizados:
/// - Background: colorBrandPrimary, colorBrandDark (gradiente)
/// - Card: colorSurfaceCard
/// - Texto header: colorTextOnDark
/// - Texto benefícios: colorTextPrimary, colorTextMuted
/// - Ícones: colorBrandPrimary
/// - Botão CTA: colorActionPrimary
class WelcomePage extends GetView<WelcomeController> {
  const WelcomePage({super.key});

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
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding.w),
            child: Column(
              children: [
                SizedBox(height: 32.h),
                
                // Header com logo e título
                _buildHeader(),
                
                SizedBox(height: 24.h),
                
                // Card com benefícios
                _buildBenefitsCard(),
                
                SizedBox(height: 16.h),
                
                // Card sobre acesso e anúncios
                _buildAccessInfoCard(),
                
                SizedBox(height: 24.h),
                
                // Botão CTA
                _buildCtaButton(),
                
                SizedBox(height: 24.h),
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
        // Logo
        ClipRRect(
          borderRadius: BorderRadius.circular(14.r),
          child: Image.asset(
            'assets/icons/55d4ebc6-2cb3-4cf9-8c64-c3059b1207e2.png',
            width: 64.w,
            height: 64.w,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                color: AppColors.colorSurfaceCard,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: AppColors.colorBrandPrimary,
                size: 36.sp,
              ),
            ),
          ),
        ),
        
        SizedBox(height: 12.h),
        
        // Título
        Text(
          'Assistente Financeiro',
          style: AppTextStyles.headline1.copyWith(
            color: AppColors.colorTextOnDark,
            fontSize: 24.sp,
          ),
        ),
        
        SizedBox(height: 4.h),
        
        // Subtítulo
        Text(
          'Simplifique sua vida financeira',
          style: AppTextStyles.body1.copyWith(
            color: AppColors.colorTextOnDark.withOpacity(0.8),
            fontSize: 15.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.cardPadding.w),
      decoration: BoxDecoration(
        color: AppColors.colorSurfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.colorBrandDark.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'O que você pode fazer',
            style: AppTextStyles.headline3.copyWith(
              color: AppColors.colorTextPrimary,
              fontSize: 18.sp,
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Lista de benefícios - mais compacta
          _buildBenefitItem(
            icon: CupertinoIcons.chart_pie,
            title: 'Controle de Gastos',
            description: 'Categorize e acompanhe suas despesas',
          ),
          
          _buildDivider(),
          
          _buildBenefitItem(
            icon: CupertinoIcons.chart_bar,
            title: 'Relatórios',
            description: 'Gráficos e análises do seu dinheiro',
          ),
          
          _buildDivider(),
          
          _buildBenefitItem(
            icon: CupertinoIcons.chat_bubble_text,
            title: 'Assistente IA',
            description: 'Tire dúvidas financeiras a qualquer hora',
          ),
          
          _buildDivider(),
          
          _buildBenefitItem(
            icon: CupertinoIcons.flag,
            title: 'Metas Financeiras',
            description: 'Defina objetivos e acompanhe seu progresso',
          ),
        ],
      ),
    );
  }

  Widget _buildAccessInfoCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.cardPadding.w),
      decoration: BoxDecoration(
        color: AppColors.colorSurfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        border: Border.all(
          color: AppColors.colorBorderSubtle.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícone de presente/gift
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: AppColors.colorWarning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              CupertinoIcons.gift,
              color: AppColors.colorWarning,
              size: 22.sp,
            ),
          ),
          
          SizedBox(height: 12.h),
          
          Text(
            'Como funciona o acesso',
            style: AppTextStyles.subtitle2.copyWith(
              color: AppColors.colorTextPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15.sp,
            ),
          ),
          
          SizedBox(height: 8.h),
          
          // Explicação clara e direta
          Text(
            'O app é gratuito com uso diário limitado das funções de IA. '
            'Para acesso ilimitado por 24h, basta assistir um anúncio curto.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.colorTextMuted,
              fontSize: 13.sp,
              height: 1.4,
            ),
          ),
          
          SizedBox(height: 12.h),
          
          // Chips informativos
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            alignment: WrapAlignment.center,
            children: [
              _buildInfoChip(
                icon: CupertinoIcons.checkmark_circle,
                label: 'Gratuito',
              ),
              _buildInfoChip(
                icon: CupertinoIcons.play_circle,
                label: '1 anúncio = 24h livres',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.colorBrandPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.colorBrandPrimary,
            size: 14.sp,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.colorBrandPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          // Ícone
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: AppColors.colorBrandPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              color: AppColors.colorBrandPrimary,
              size: 20.sp,
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle2.copyWith(
                    color: AppColors.colorTextPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.colorTextMuted,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: AppColors.colorBorderSubtle.withOpacity(0.5),
      height: 1,
    );
  }

  Widget _buildCtaButton() {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: controller.getStarted,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.colorActionPrimary,
          foregroundColor: AppColors.colorTextOnDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button.r),
          ),
        ),
        child: Text(
          'Começar Agora',
          style: AppTextStyles.button.copyWith(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
