import 'package:get/get.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/constants/app_constants.dart';

class WelcomeController extends GetxController {
  final _secureStorage = Get.find<SecureStorage>();

  Future<void> getStarted() async {
    // Marca o onboarding como concluído
    await _secureStorage.write(AppConstants.onboardingKey, 'true');
    
    // Navega para a tela de login
    Get.offAllNamed(AppRoutes.login);
  }
}



