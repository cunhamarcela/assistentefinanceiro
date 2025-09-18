import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/onboarding_page_model.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/data/services/auth_service.dart';

class OnboardingController extends GetxController {
  late final PageController pageController;
  final RxInt currentPage = 0.obs;
  final RxBool isLastPage = false.obs;
  
  final List<OnboardingPageModel> pages = OnboardingPageModel.pages;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController();
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void onPageChanged(int index) {
    currentPage.value = index;
    isLastPage.value = pages[index].isLastPage;
  }

  void nextPage() {
    if (currentPage.value < pages.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      completeOnboarding();
    }
  }

  void previousPage() {
    if (currentPage.value > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void skipOnboarding() {
    completeOnboarding();
  }

  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> completeOnboarding() async {
    try {
      // Marcar onboarding como completo
      await Get.find<SecureStorage>().write(AppConstants.onboardingKey, 'true');
      
      // Após o onboarding, sempre ir para registro (primeira experiência)
      Get.offAllNamed(AppRoutes.register);
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao completar onboarding: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }
}
