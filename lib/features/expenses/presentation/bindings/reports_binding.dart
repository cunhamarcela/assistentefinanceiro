import 'package:get/get.dart';
import '../controllers/reports_controller.dart';
import '../controllers/enhanced_reports_controller.dart';
import '../../domain/usecases/generate_insight_report_usecase.dart';
import '../../domain/repositories/insight_repository.dart';
import '../../data/repositories/insight_repository_impl.dart';
import '../../data/datasources/reports_local_datasource.dart';
import '../../data/datasources/reports_remote_datasource.dart';
import '../../data/datasources/expense_local_datasource.dart';
import '../../domain/repositories/financial_goals_repository.dart';
import '../../data/repositories/financial_goals_repository_impl.dart';
import '../../data/services/financial_profile_service.dart';
import '../../data/services/financial_insights_service.dart';
import '../../data/services/enhanced_insights_generator.dart';
import '../../../onboarding/data/services/onboarding_service.dart';
import '../../../onboarding/data/services/ai_insights_service.dart';
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

    // Registrar ExpenseLocalDataSource se ainda não estiver registrado
    if (!Get.isRegistered<ExpenseLocalDataSource>()) {
      Get.lazyPut<ExpenseLocalDataSource>(
        () => ExpenseLocalDataSource(),
        fenix: true,
      );
    }

    // Data Sources
    Get.lazyPut<ReportsLocalDataSource>(
      () => ReportsLocalDataSourceImpl(
        expenseDataSource: Get.find<ExpenseLocalDataSource>(),
      ),
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

    // Additional Services for Enhanced Reports
    Get.lazyPut<FinancialProfileService>(() => FinancialProfileService());
    Get.lazyPut<FinancialInsightsService>(() => FinancialInsightsService());
    Get.lazyPut<EnhancedInsightsGenerator>(() => EnhancedInsightsGenerator());
    Get.lazyPut<OnboardingService>(() => OnboardingService());
    Get.lazyPut<AIInsightsService>(() => AIInsightsService());
    
    // Financial Goals Repository (if not already registered)
    if (!Get.isRegistered<FinancialGoalsRepository>()) {
      Get.lazyPut<FinancialGoalsRepository>(
        () => FinancialGoalsRepositoryImpl(),
        fenix: true,
      );
    }

    // Controllers
    Get.lazyPut<ReportsController>(
      () => ReportsController(
        generateReportUseCase: Get.find<GenerateInsightReportUseCase>(),
        analyticsService: Get.find<AnalyticsService>(),
      ),
    );
    
    Get.lazyPut<EnhancedReportsController>(() => EnhancedReportsController());
  }
}
