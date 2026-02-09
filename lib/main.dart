import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/app_pages.dart';
import 'core/storage/secure_storage.dart';
import 'core/storage/storage_service.dart';
import 'core/constants/app_constants.dart';
import 'core/config/app_initialization.dart';
import 'core/services/crash_reporting_service.dart';
import 'core/services/logging_service.dart';
import 'core/services/analytics_service.dart';
import 'features/auth/data/services/auth_service.dart';
import 'features/auth/data/services/firestore_user_service.dart';
import 'features/auth/presentation/bindings/auth_binding.dart';
import 'features/monetization/data/services/usage_limit_service.dart';
import 'core/services/ads_service.dart';
import 'core/services/att_service.dart';
import 'firebase_options.dart';

void main() async {
  // Executar app dentro de uma zona de erro para capturar todos os erros
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      
      // Inicializar Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Inicializar Crash Reporting IMEDIATAMENTE após Firebase
      await CrashReportingService.instance.initialize();
      await LoggingService.instance.initialize();
      
      LoggingService.instance.logInfo('App', '🔥 Firebase inicializado com sucesso!');
      
      // Inicializar dados de localização para pt_BR
      await initializeDateFormatting('pt_BR', null);
      
      // Configurar orientações (mais flexível para iPad)
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      
      // Inicializar serviços de storage antes do app
      await _initializeServices();
      
      // Inicializar OpenAI e outros serviços avançados
      await AppInitialization.initialize();
      
      LoggingService.instance.logInfo('App', '✅ App inicializado com sucesso');
      
      runApp(const MyApp());
    },
    (error, stack) {
      // Capturar todos os erros não tratados da zona
      CrashReportingService.instance.recordError(
        error,
        stack,
        reason: 'Erro não tratado na zona principal',
        fatal: true,
      );
      
      if (kDebugMode) {
        debugPrint('🚨 ERRO NÃO TRATADO: $error');
        debugPrint('Stack trace: $stack');
      }
    },
  );
}

/// Inicializar serviços essenciais
Future<void> _initializeServices() async {
  final logger = LoggingService.instance;
  
  try {
    // Inicializar StorageService
    logger.logInfo('Services', 'Inicializando StorageService...');
    final storageService = await StorageService.instance.init();
    Get.put<StorageService>(storageService, permanent: true);
    
    // Inicializar SecureStorage
    logger.logInfo('Services', 'Inicializando SecureStorage...');
    final secureStorage = await SecureStorage.instance.init();
    Get.put<SecureStorage>(secureStorage, permanent: true);
    
    // Inicializar FirestoreUserService
    logger.logInfo('Services', 'Inicializando FirestoreUserService...');
    final firestoreUserService = FirestoreUserService();
    Get.put<FirestoreUserService>(firestoreUserService, permanent: true);
    
    // Inicializar AuthService
    logger.logInfo('Services', 'Inicializando AuthService...');
    final authService = AuthService();
    await authService.onInit();
    Get.put<AuthService>(authService, permanent: true);
    
    // Configurar informações do usuário no crash reporting
    if (authService.isAuthenticated && authService.currentUser != null) {
      await CrashReportingService.instance.setUserId(authService.currentUser!.id);
      await CrashReportingService.instance.setUserInfo(
        email: authService.currentUser!.email,
        name: authService.currentUser!.displayName,
      );
      await LoggingService.instance.setUserId(authService.currentUser!.id);
    }
    
    // Inicializar AnalyticsService (Firebase Analytics)
    logger.logInfo('Services', 'Inicializando AnalyticsService...');
    final analyticsService = AnalyticsService.instance;
    await analyticsService.initialize();
    Get.put<AnalyticsService>(analyticsService, permanent: true);
    
    // Configurar User ID no analytics se autenticado
    if (authService.isAuthenticated && authService.currentUser != null) {
      await analyticsService.setUserId(authService.currentUser!.id);
    }
    
    // Inicializar serviços de monetização
    logger.logInfo('Services', 'Inicializando serviços de monetização...');
    final usageLimitService = UsageLimitService();
    Get.put<UsageLimitService>(usageLimitService, permanent: true);
    
    // Inicializar ATT Service ANTES do AdsService (crítico para iOS)
    logger.logInfo('Services', 'Inicializando ATTService (App Tracking Transparency)...');
    final attService = ATTService();
    Get.put<ATTService>(attService, permanent: true);
    
    final adsService = AdsService();
    Get.put<AdsService>(adsService, permanent: true);
    
    // Carregar dados de uso do usuário se autenticado
    if (authService.isAuthenticated) {
      await usageLimitService.loadUserData();
    }
    
    logger.logInfo('Services', '✅ Todos os serviços inicializados');
  } catch (e, stack) {
    logger.logError(
      'Services',
      'Erro ao inicializar serviços',
      error: e,
      stackTrace: stack,
    );
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      builder: (context, child) {
        return FutureBuilder<String>(
          future: _getInitialRoute(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return MaterialApp(
                home: Scaffold(
                  body: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6A4DFF), Color(0xFF9C3DFF)],
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
              );
            }

            return GetMaterialApp(
              title: 'Assistente Financeiro IA',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.system,
              initialBinding: InitialBinding(),
              initialRoute: snapshot.data ?? AppRoutes.onboarding,
              getPages: AppPages.routes,
              defaultTransition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 300),
              locale: const Locale('pt', 'BR'),
              fallbackLocale: const Locale('en', 'US'),
              // Observer para tracking automático de telas no Firebase Analytics
              navigatorObservers: [
                FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
              ],
              builder: (context, widget) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.0),
                  ),
                  child: widget!,
                );
              },
            );
          },
        );
      },
    );
  }

  Future<String> _getInitialRoute() async {
    try {
      final secureStorage = Get.find<SecureStorage>();
      final onboardingCompleted = await secureStorage.read(AppConstants.onboardingKey);
      
      if (onboardingCompleted == 'true') {
        // Onboarding já foi completado, verificar autenticação
        final authService = Get.find<AuthService>();
        if (authService.isAuthenticated) {
          return AppRoutes.home;
        } else {
          return AppRoutes.login;
        }
      } else {
        // Primeira vez, mostrar onboarding
        return AppRoutes.onboarding;
      }
    } catch (e) {
      print('Erro ao determinar rota inicial: $e');
      return AppRoutes.onboarding;
    }
  }

}