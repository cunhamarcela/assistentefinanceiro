import 'package:get/get.dart';
import '../controllers/investment_controller.dart';
import '../../domain/repositories/investment_repository.dart';
import '../../data/repositories/investment_repository_impl.dart';
import '../../data/datasources/investment_local_datasource.dart';
import '../../data/datasources/investment_firestore_datasource.dart';
import '../../../auth/data/services/auth_service.dart';

/// Binding para injeção de dependências dos investimentos
class InvestmentBinding extends Bindings {
  @override
  void dependencies() {
    // Data Sources
    if (!Get.isRegistered<InvestmentLocalDataSource>()) {
      Get.lazyPut<InvestmentLocalDataSource>(
        () => InvestmentLocalDataSource(),
        fenix: true,
      );
    }

    if (!Get.isRegistered<InvestmentFirestoreDataSource>()) {
      Get.lazyPut<InvestmentFirestoreDataSource>(
        () => InvestmentFirestoreDataSource(),
        fenix: true,
      );
    }

    // Repository
    Get.lazyPut<InvestmentRepository>(
      () => InvestmentRepositoryImpl(
        localDataSource: Get.find<InvestmentLocalDataSource>(),
        firestoreDataSource: Get.find<InvestmentFirestoreDataSource>(),
        authService: Get.find<AuthService>(),
      ),
      fenix: true,
    );

    // Controller
    Get.lazyPut<InvestmentController>(
      () => InvestmentController(),
    );
  }
}



