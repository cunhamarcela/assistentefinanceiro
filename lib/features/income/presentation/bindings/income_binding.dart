import 'package:get/get.dart';
import '../controllers/income_controller.dart';
import '../../domain/repositories/income_repository.dart';
import '../../data/repositories/income_repository_impl.dart';
import '../../../../core/services/analytics_service.dart';

/// Binding para injeção de dependências do módulo de receitas
class IncomeBinding extends Bindings {
  @override
  void dependencies() {
    // Repository
    Get.lazyPut<IncomeRepository>(
      () => IncomeRepositoryImpl(),
    );

    // Controller
    Get.lazyPut<IncomeController>(
      () => IncomeController(
        repository: Get.find<IncomeRepository>(),
        analyticsService: Get.isRegistered<AnalyticsService>() 
            ? Get.find<AnalyticsService>() 
            : null,
      ),
    );
  }
}




