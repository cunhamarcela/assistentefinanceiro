class AppConstants {
  // App Info
  static const String appName = 'Assistente Financeiro IA';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String expensesKey = 'expenses_data';
  static const String categoriesKey = 'categories_data';
  static const String onboardingKey = 'onboarding_completed';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Financial
  static const String defaultCurrency = 'R\$';
  static const String currencySymbol = 'R\$';
  
  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String monthYearFormat = 'MM/yyyy';
  
  // Validation
  static const double minExpenseAmount = 0.01;
  static const double maxExpenseAmount = 999999.99;
  static const int maxDescriptionLength = 100;
  
  // Colors (as hex strings for easy use)
  static const String primaryColorHex = '#1B5E20';
  static const String secondaryColorHex = '#2E7D32';
  static const String accentColorHex = '#4CAF50';
  static const String errorColorHex = '#D32F2F';
  static const String warningColorHex = '#FF9800';
  static const String successColorHex = '#4CAF50';
  
  // Default Categories
  static const List<String> defaultCategoryIds = [
    'alimentacao',
    'transporte',
    'saude',
    'contas',
    'lazer',
    'casa',
    'educacao',
    'outros',
  ];
}
