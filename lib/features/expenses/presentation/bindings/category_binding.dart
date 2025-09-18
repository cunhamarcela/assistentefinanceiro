import 'package:get/get.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/usecases/category_management_usecase.dart';
import '../controllers/category_controller.dart';

class CategoryBinding extends Bindings {
  @override
  void dependencies() {
    // Use Case
    Get.lazyPut<CategoryManagementUseCase>(
      () => CategoryManagementUseCase(Get.find<ExpenseRepository>()),
    );

    // Controller
    Get.lazyPut<CategoryController>(
      () => CategoryController(
        categoryManagementUseCase: Get.find<CategoryManagementUseCase>(),
      ),
    );
  }
}


