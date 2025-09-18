import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_routes.dart';
import '../middleware/auth_middleware.dart';
import '../../features/auth/presentation/bindings/auth_binding.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/email_verification_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/onboarding/presentation/bindings/onboarding_binding.dart';
import '../../features/expenses/presentation/bindings/expense_binding.dart';
import '../../features/expenses/presentation/pages/home_page.dart';
import '../../features/expenses/presentation/pages/expenses_page.dart';
import '../../features/expenses/presentation/pages/add_expense_page.dart';
import '../../features/expenses/presentation/pages/edit_expense_page.dart';
import '../../features/expenses/presentation/pages/categories_page.dart';
import '../../features/expenses/presentation/pages/add_category_page.dart';
import '../../features/expenses/presentation/bindings/category_binding.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/change_password_page.dart';
import '../../features/profile/presentation/bindings/profile_binding.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/chat/presentation/bindings/chat_binding.dart';
import '../../features/expenses/presentation/pages/reports_page.dart';
import '../../features/expenses/presentation/pages/enhanced_reports_page.dart';
import '../../features/expenses/presentation/bindings/reports_binding.dart';
import '../../features/expenses/presentation/pages/financial_goals_page.dart';

class AppPages {
  static final routes = [
    // Onboarding Route
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingPage(),
      binding: OnboardingBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Authentication Routes
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: LoginBinding(),
      middlewares: [MiddlewareFactory.guest()],
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterPage(),
      binding: RegisterBinding(),
      middlewares: [MiddlewareFactory.guest()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordPage(),
      binding: ForgotPasswordBinding(),
      middlewares: [MiddlewareFactory.guest()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    GetPage(
      name: AppRoutes.emailVerification,
      page: () => const EmailVerificationPage(),
      binding: AuthBinding(),
      middlewares: [MiddlewareFactory.auth()],
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Home
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: ExpenseBinding(),
      middlewares: [MiddlewareFactory.auth()],
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Expenses
    GetPage(
      name: AppRoutes.expenses,
      page: () => const ExpensesPage(),
      binding: ExpenseBinding(),
      middlewares: [MiddlewareFactory.auth()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Add Expense
    GetPage(
      name: AppRoutes.addExpense,
      page: () => const AddExpensePage(),
      binding: ExpenseBinding(),
      middlewares: [MiddlewareFactory.auth()],
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Edit Expense
    GetPage(
      name: AppRoutes.editExpense,
      page: () => const EditExpensePage(),
      binding: ExpenseBinding(),
      middlewares: [MiddlewareFactory.auth()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Categories
    GetPage(
      name: AppRoutes.categories,
      page: () => const CategoriesPage(),
      binding: CategoryBinding(),
      middlewares: [MiddlewareFactory.auth()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Add Category
    GetPage(
      name: AppRoutes.addCategory,
      page: () => const AddCategoryPage(), // Voltando para versão original
      binding: CategoryBinding(),
      middlewares: [MiddlewareFactory.auth()],
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Edit Category
    GetPage(
      name: AppRoutes.editCategory,
      page: () => const AddCategoryPage(), // Mesma página, modo edição
      binding: CategoryBinding(),
      middlewares: [MiddlewareFactory.auth()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Chat IA
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatPage(),
      binding: ChatBinding(),
      middlewares: [MiddlewareFactory.auth()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Relatórios
    GetPage(
      name: AppRoutes.reports,
      page: () => const EnhancedReportsPage(),
      binding: ExpenseBinding(),
      middlewares: [MiddlewareFactory.auth()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Analytics (placeholder - agora redirecionando para relatórios aprimorados)
    GetPage(
      name: AppRoutes.analytics,
      page: () => const EnhancedReportsPage(),
      binding: ExpenseBinding(),
      middlewares: [MiddlewareFactory.auth()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Settings (placeholder)
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      middlewares: [MiddlewareFactory.auth()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Profile
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfilePage(),
      binding: ProfileBinding(),
      middlewares: [MiddlewareFactory.auth()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Edit Profile
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfilePage(),
      binding: EditProfileBinding(),
      middlewares: [MiddlewareFactory.auth()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Change Password
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordPage(),
      binding: ChangePasswordBinding(),
      middlewares: [MiddlewareFactory.auth()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Financial Goals
    GetPage(
      name: AppRoutes.financialGoals,
      page: () => const FinancialGoalsPage(),
      binding: ExpenseBinding(),
      middlewares: [MiddlewareFactory.auth()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}

// Páginas placeholder
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Analytics em desenvolvimento',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Configurações em desenvolvimento',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
