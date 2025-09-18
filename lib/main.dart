import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/app_pages.dart';
import 'core/storage/secure_storage.dart';
import 'core/storage/storage_service.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/data/services/auth_service.dart';
import 'features/auth/data/services/firestore_user_service.dart';
import 'features/auth/presentation/bindings/auth_binding.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Firebase inicializado com sucesso
  print('🔥 Firebase inicializado com sucesso!');
  
  // Inicializar dados de localização para pt_BR
  await initializeDateFormatting('pt_BR', null);
  
  // Configurar orientações
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Inicializar serviços de storage antes do app
  await _initializeServices();
  
  runApp(const MyApp());
}

/// Inicializar serviços essenciais
Future<void> _initializeServices() async {
  // Inicializar StorageService
  final storageService = await StorageService.instance.init();
  Get.put<StorageService>(storageService, permanent: true);
  
  // Inicializar SecureStorage
  final secureStorage = await SecureStorage.instance.init();
  Get.put<SecureStorage>(secureStorage, permanent: true);
  
  // Inicializar FirestoreUserService
  final firestoreUserService = FirestoreUserService();
  Get.put<FirestoreUserService>(firestoreUserService, permanent: true);
  
  // Inicializar AuthService
  final authService = AuthService();
  await authService.onInit();
  Get.put<AuthService>(authService, permanent: true);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
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