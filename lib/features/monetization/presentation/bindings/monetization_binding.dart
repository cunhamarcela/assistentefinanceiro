import 'package:get/get.dart';
import '../../data/services/usage_limit_service.dart';
import '../../../../core/services/ads_service.dart';

/// Binding para injeção de dependências do módulo de monetização
class MonetizationBinding extends Bindings {
  @override
  void dependencies() {
    // Usage Limit Service (singleton para gerenciar limites)
    Get.lazyPut<UsageLimitService>(
      () => UsageLimitService(),
      fenix: true, // Mantém a instância viva
    );

    // Ads Service (singleton para gerenciar anúncios)
    Get.lazyPut<AdsService>(
      () => AdsService(),
      fenix: true,
    );
  }
}

/// Binding global para inicializar serviços de monetização no app start
class MonetizationGlobalBinding {
  static void init() {
    // Registra o UsageLimitService como singleton permanente
    if (!Get.isRegistered<UsageLimitService>()) {
      Get.put<UsageLimitService>(UsageLimitService(), permanent: true);
    }

    // Registra o AdsService como singleton permanente
    if (!Get.isRegistered<AdsService>()) {
      Get.put<AdsService>(AdsService(), permanent: true);
    }
  }
}




