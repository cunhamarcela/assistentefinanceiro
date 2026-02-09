class AppRoutes {
  // Authentication
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
  static const String completeProfile = '/complete-profile';
  
  // Main Navigation
  static const String home = '/home';
  static const String expenses = '/expenses';
  static const String addExpense = '/add-expense';
  static const String editExpense = '/edit-expense';
  static const String expenseDetail = '/expense-detail';
  static const String categories = '/categories';
  static const String addCategory = '/add-category';
  static const String editCategory = '/edit-category';
  static const String analytics = '/analytics';
  static const String chat = '/chat';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  
  // Credit Cards
  static const String creditCards = '/credit-cards';
  static const String addCreditCard = '/add-credit-card';
  static const String editCreditCard = '/edit-credit-card';
  static const String creditCardDetails = '/credit-card-details';
  
  // Onboarding
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';
  
  // Reports
  static const String reports = '/reports';
  static const String monthlyReport = '/monthly-report';
  static const String categoryReport = '/category-report';
  static const String quickSummary = '/quick-summary';
  
  // Income (Receitas)
  static const String incomes = '/incomes';
  static const String addIncome = '/income/add';
  static const String editIncome = '/income/edit';
  
  // Budget and Financial Goals
  static const String budgets = '/budgets';
  static const String createBudget = '/create-budget';
  static const String financialGoals = '/financial-goals';
  
  // Investments
  static const String investments = '/investments';
  static const String addInvestment = '/investment/add';
  
  // Premium Features
  static const String multiPeriodComparison = '/multi-period-comparison';
  
  // Error Pages
  static const String notFound = '/404';
  static const String maintenance = '/maintenance';
  
  // Route groups for easier management
  static const List<String> authRoutes = [
    login,
    register,
    forgotPassword,
    emailVerification,
    completeProfile,
  ];
  
  static const List<String> mainRoutes = [
    home,
    expenses,
    incomes,
    analytics,
    chat,
    settings,
  ];
  
  static const List<String> incomeRoutes = [
    incomes,
    addIncome,
    editIncome,
  ];
  
  static const List<String> expenseRoutes = [
    expenses,
    addExpense,
    editExpense,
    expenseDetail,
    categories,
    addCategory,
    editCategory,
    creditCards,
    addCreditCard,
    editCreditCard,
    creditCardDetails,
  ];
  
  static const List<String> reportRoutes = [
    reports,
    monthlyReport,
    categoryReport,
    quickSummary,
    analytics,
  ];
  
  static const List<String> investmentRoutes = [
    investments,
    addInvestment,
  ];
  
  static const List<String> premiumRoutes = [
    multiPeriodComparison,
  ];
  
  // Helper methods
  static bool isAuthRoute(String route) => authRoutes.contains(route);
  static bool isMainRoute(String route) => mainRoutes.contains(route);
  static bool isExpenseRoute(String route) => expenseRoutes.contains(route);
  static bool isReportRoute(String route) => reportRoutes.contains(route);
  static bool isPremiumRoute(String route) => premiumRoutes.contains(route);
  
  // Get route category
  static String getRouteCategory(String route) {
    if (isAuthRoute(route)) return 'auth';
    if (isMainRoute(route)) return 'main';
    if (isExpenseRoute(route)) return 'expense';
    if (isReportRoute(route)) return 'report';
    if (isPremiumRoute(route)) return 'premium';
    return 'other';
  }
}
