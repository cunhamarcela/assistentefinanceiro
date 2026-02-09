import 'package:get/get.dart';
import '../../../../core/services/financial_context_service.dart';
import '../controllers/multi_period_comparison_controller.dart';
import '../../domain/usecases/generate_multi_period_comparison_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../data/datasources/expense_local_datasource.dart';
import '../../data/datasources/expense_firestore_datasource.dart';
import '../../data/repositories/expense_hybrid_repository.dart';
import '../../data/services/smart_comparison_service.dart';
import '../../data/services/enhanced_insights_generator.dart';

/// Binding para a tela de comparações multi-período
/// 
/// Registra todas as dependências necessárias, incluindo
/// o SmartComparisonService para integração inteligente.
/// 
/// IMPORTANTE: Este binding garante que todas as dependências
/// estão disponíveis mesmo quando navegando diretamente para
/// esta tela sem passar por outras páginas.
class ComparisonBinding extends Bindings {
  @override
  void dependencies() {
    // ============================================
    // DATA SOURCES (se não existirem)
    // ============================================
    
    if (!Get.isRegistered<ExpenseLocalDataSource>()) {
      Get.lazyPut<ExpenseLocalDataSource>(
        () => ExpenseLocalDataSource(),
        fenix: true,
      );
    }
    
    if (!Get.isRegistered<ExpenseFirestoreDataSource>()) {
      Get.lazyPut<ExpenseFirestoreDataSource>(
        () => ExpenseFirestoreDataSource(),
        fenix: true,
      );
    }
    
    // ============================================
    // REPOSITORY (se não existir)
    // ============================================
    
    if (!Get.isRegistered<ExpenseRepository>()) {
      Get.lazyPut<ExpenseRepository>(
        () => ExpenseHybridRepository(
          localDataSource: Get.find<ExpenseLocalDataSource>(),
          firestoreDataSource: Get.find<ExpenseFirestoreDataSource>(),
        ),
        fenix: true,
      );
    }

    // ============================================
    // SERVIÇOS DE INTEGRAÇÃO (se não existirem)
    // ============================================
    
    // SmartComparisonService - serviço principal de comparações inteligentes
    if (!Get.isRegistered<SmartComparisonService>()) {
      Get.lazyPut<SmartComparisonService>(
        () => SmartComparisonService(),
        fenix: true,
      );
    }
    
    // EnhancedInsightsGenerator - gerador de insights
    if (!Get.isRegistered<EnhancedInsightsGenerator>()) {
      Get.lazyPut<EnhancedInsightsGenerator>(
        () => EnhancedInsightsGenerator(),
        fenix: true,
      );
    }
    
    // FinancialContextService - contexto financeiro
    if (!Get.isRegistered<FinancialContextService>()) {
      Get.lazyPut<FinancialContextService>(
        () => FinancialContextService(),
        fenix: true,
      );
    }

    // ============================================
    // USE CASES
    // ============================================
    
    // GetCategoriesUseCase
    if (!Get.isRegistered<GetCategoriesUseCase>()) {
      Get.lazyPut<GetCategoriesUseCase>(
        () => GetCategoriesUseCase(Get.find<ExpenseRepository>()),
        fenix: true,
      );
    }
    
    // GenerateMultiPeriodComparisonUseCase com SmartComparisonService
    SmartComparisonService? smartService;
    if (Get.isRegistered<SmartComparisonService>()) {
      smartService = Get.find<SmartComparisonService>();
    }
    
    if (!Get.isRegistered<GenerateMultiPeriodComparisonUseCase>()) {
      Get.lazyPut<GenerateMultiPeriodComparisonUseCase>(
        () => GenerateMultiPeriodComparisonUseCase(
          Get.find<ExpenseRepository>(),
          smartComparisonService: smartService,
        ),
        fenix: true,
      );
    }
    
    // ============================================
    // CONTROLLER
    // ============================================
    
    Get.lazyPut<MultiPeriodComparisonController>(
      () => MultiPeriodComparisonController(
        generateComparisonUseCase: Get.find<GenerateMultiPeriodComparisonUseCase>(),
        getCategoriesUseCase: Get.find<GetCategoriesUseCase>(),
      ),
    );
  }
}
