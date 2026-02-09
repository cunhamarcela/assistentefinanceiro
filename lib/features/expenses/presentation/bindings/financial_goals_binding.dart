import 'package:get/get.dart';
import '../controllers/financial_goals_controller.dart';
import '../../domain/repositories/financial_goals_repository.dart';
import '../../data/repositories/financial_goals_repository_impl.dart';
import '../../data/services/financial_profile_service.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/repositories/expense_repository.dart';

/// Binding para injeção de dependências das metas financeiras
class FinancialGoalsBinding extends Bindings {
  @override
  void dependencies() {
    // Use Case (se ainda não estiver registrado)
    if (!Get.isRegistered<GetCategoriesUseCase>()) {
      Get.lazyPut<GetCategoriesUseCase>(
        () => GetCategoriesUseCase(Get.find<ExpenseRepository>()),
        fenix: true,
      );
    }

    // Repository
    Get.lazyPut<FinancialGoalsRepository>(
      () => FinancialGoalsRepositoryImpl(),
      fenix: true,
    );

    // Services (se ainda não estiverem registrados)
    if (!Get.isRegistered<FinancialProfileService>()) {
      Get.lazyPut<FinancialProfileService>(
        () => FinancialProfileService(),
        fenix: true,
      );
    }

    // Controller
    Get.lazyPut<FinancialGoalsController>(
      () => FinancialGoalsController(),
    );
  }
}

