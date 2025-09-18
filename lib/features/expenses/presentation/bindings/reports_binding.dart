import 'package:get/get.dart';
import '../controllers/reports_controller.dart';
import '../../domain/usecases/generate_insight_report_usecase.dart';
import '../../domain/repositories/insight_repository.dart';
import '../../data/repositories/insight_repository_impl.dart';
import '../../data/datasources/reports_local_datasource.dart';
import '../../data/datasources/reports_remote_datasource.dart';
import '../../../../core/services/analytics_service.dart';

/// Binding para injeção de dependências dos relatórios
class ReportsBinding extends Bindings {
  @override
  void dependencies() {
    // Analytics Service (singleton)
    Get.lazyPut<AnalyticsService>(
      () => AnalyticsService.instance,
      fenix: true,
    );

    // Data Sources
    Get.lazyPut<ReportsLocalDataSource>(
      () => ReportsLocalDataSourceImpl(),
    );

    Get.lazyPut<ReportsRemoteDataSource>(
      () => ReportsRemoteDataSourceImpl(),
    );

    // Repository
    Get.lazyPut<InsightRepository>(
      () => InsightRepositoryImpl(
        localDataSource: Get.find<ReportsLocalDataSource>(),
        remoteDataSource: Get.find<ReportsRemoteDataSource>(),
      ),
    );

    // Use Cases
    Get.lazyPut<GenerateInsightReportUseCase>(
      () => GenerateInsightReportUseCase(Get.find<InsightRepository>()),
    );

    // Controller
    Get.lazyPut<ReportsController>(
      () => ReportsController(
        generateReportUseCase: Get.find<GenerateInsightReportUseCase>(),
        analyticsService: Get.find<AnalyticsService>(),
      ),
    );
  }
}
