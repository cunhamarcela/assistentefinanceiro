import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../expenses/data/datasources/expense_local_datasource.dart';
import '../../../expenses/data/datasources/expense_firestore_datasource.dart';
import '../../../expenses/data/services/financial_profile_service.dart';
import '../../../expenses/data/services/financial_insights_service.dart';

/// Binding para injeção de dependências de autenticação
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Registrar AuthController
    Get.lazyPut<AuthController>(
      () => AuthController(),
      fenix: true, // Permite recriar se necessário
    );
  }
}

/// Binding inicial da aplicação
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Todos os serviços já foram inicializados no main.dart
    // Só precisamos registrar o AuthController
    
    Get.lazyPut<AuthController>(
      () => AuthController(),
      fenix: true,
    );
    
    // Registrar serviços de despesas globalmente
    _registerExpenseServices();
  }
  
  void _registerExpenseServices() {
    // Data Sources
    Get.lazyPut(() => ExpenseLocalDataSource());
    Get.lazyPut(() => ExpenseFirestoreDataSource());
    
    // Services
    Get.lazyPut(() => FinancialProfileService());
    Get.lazyPut(() => FinancialInsightsService());
  }
}

/// Binding específico para telas de autenticação
class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(
      () => AuthController(),
      fenix: true,
    );
  }
}

/// Binding para tela de registro
class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(
      () => AuthController(),
      fenix: true,
    );
  }
}

/// Binding para tela de recuperação de senha
class ForgotPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(
      () => AuthController(),
      fenix: true,
    );
  }
}
