import 'package:get/get.dart';
import '../../data/datasources/expense_local_datasource.dart';
import '../../data/datasources/expense_firestore_datasource.dart';
import '../../data/repositories/expense_hybrid_repository.dart';
import '../../data/services/financial_profile_service.dart';
import '../../data/services/financial_insights_service.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/usecases/add_expense_usecase.dart';
import '../../domain/usecases/add_expense_with_goals_usecase.dart';
import '../../domain/usecases/update_expense_usecase.dart';
import '../../domain/usecases/delete_expense_usecase.dart';
import '../../domain/usecases/get_expense_by_id_usecase.dart';
import '../../domain/usecases/get_expenses_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/categorize_expense_usecase.dart';
import '../controllers/expense_controller.dart';
import '../controllers/financial_goals_controller.dart';
import '../controllers/enhanced_reports_controller.dart';

class ExpenseBinding extends Bindings {
  @override
  void dependencies() {
    // Data Sources
    Get.lazyPut<ExpenseLocalDataSource>(
      () => ExpenseLocalDataSource(),
    );

    Get.lazyPut<ExpenseFirestoreDataSource>(
      () => ExpenseFirestoreDataSource(),
    );

    // Repository Híbrido
    Get.lazyPut<ExpenseRepository>(
      () => ExpenseHybridRepository(
        localDataSource: Get.find<ExpenseLocalDataSource>(),
        firestoreDataSource: Get.find<ExpenseFirestoreDataSource>(),
      ),
    );

    // Use Cases
    Get.lazyPut<AddExpenseUseCase>(
      () => AddExpenseUseCase(Get.find<ExpenseRepository>()),
    );

    Get.lazyPut<AddExpenseWithGoalsUseCase>(
      () => AddExpenseWithGoalsUseCase(
        repository: Get.find<ExpenseRepository>(),
        profileService: Get.find<FinancialProfileService>(),
      ),
    );

    Get.lazyPut<UpdateExpenseUseCase>(
      () => UpdateExpenseUseCase(Get.find<ExpenseRepository>()),
    );

    Get.lazyPut<DeleteExpenseUseCase>(
      () => DeleteExpenseUseCase(Get.find<ExpenseRepository>()),
    );

    Get.lazyPut<GetExpenseByIdUseCase>(
      () => GetExpenseByIdUseCase(Get.find<ExpenseRepository>()),
    );

    Get.lazyPut<GetExpensesUseCase>(
      () => GetExpensesUseCase(Get.find<ExpenseRepository>()),
    );

    Get.lazyPut<CategorizeExpenseUseCase>(
      () => CategorizeExpenseUseCase(Get.find<ExpenseRepository>()),
    );

    Get.lazyPut<GetCategoriesUseCase>(
      () => GetCategoriesUseCase(Get.find<ExpenseRepository>()),
    );

    // Services
    Get.lazyPut<FinancialProfileService>(
      () => FinancialProfileService(),
    );

    Get.lazyPut<FinancialInsightsService>(
      () => FinancialInsightsService(),
    );

    // Controllers
    Get.lazyPut<ExpenseController>(
      () => ExpenseController(
        addExpenseUseCase: Get.find<AddExpenseUseCase>(),
        addExpenseWithGoalsUseCase: Get.find<AddExpenseWithGoalsUseCase>(),
        updateExpenseUseCase: Get.find<UpdateExpenseUseCase>(),
        deleteExpenseUseCase: Get.find<DeleteExpenseUseCase>(),
        getExpenseByIdUseCase: Get.find<GetExpenseByIdUseCase>(),
        getExpensesUseCase: Get.find<GetExpensesUseCase>(),
        categorizeExpenseUseCase: Get.find<CategorizeExpenseUseCase>(),
      ),
    );

    Get.lazyPut<FinancialGoalsController>(
      () => FinancialGoalsController(),
    );

    Get.lazyPut<EnhancedReportsController>(
      () => EnhancedReportsController(),
    );
  }
}
