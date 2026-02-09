import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../services/openai_service.dart';
import '../storage/secure_storage.dart';
import '../../features/onboarding/data/services/onboarding_service.dart';
import 'api_config.dart';

class AppInitialization {
  /// Inicializa todos os serviços essenciais do app
  static Future<void> initialize() async {
    print('🚀 Inicializando Assistente Financeiro IA...');
    
    try {
      // 1. Inicializar storage seguro
      await _initializeSecureStorage();
      
      // 2. Inicializar OnboardingService (requerido por Chat IA)
      await _initializeOnboardingService();
      
      // 3. Configurar OpenAI
      await _setupOpenAI();
      
      // 4. Verificar configurações
      await _verifyConfiguration();
      
      print('✅ App inicializado com sucesso!');
    } catch (e) {
      print('❌ Erro na inicialização: $e');
      rethrow;
    }
  }
  
  /// Inicializa o OnboardingService
  static Future<void> _initializeOnboardingService() async {
    print('📋 Inicializando OnboardingService...');
    
    if (!Get.isRegistered<OnboardingService>()) {
      Get.put<OnboardingService>(OnboardingService(), permanent: true);
    }
    
    print('✅ OnboardingService configurado');
  }
  
  /// Inicializa o storage seguro
  static Future<void> _initializeSecureStorage() async {
    print('📱 Inicializando storage seguro...');
    
    final secureStorage = SecureStorage.instance;
    await secureStorage.init();
    Get.put(secureStorage, permanent: true);
    
    print('✅ Storage seguro configurado');
  }
  
  /// Configura a OpenAI com a API key
  static Future<void> _setupOpenAI() async {
    print('🤖 Configurando OpenAI...');
    
    // Registrar o serviço OpenAI
    Get.put(OpenAIService(), permanent: true);
    
    // Buscar API key do secure storage (configurada via settings)
    final secureStorage = Get.find<SecureStorage>();
    final apiKey = await secureStorage.read('openai_api_key');
    
    if (apiKey != null && apiKey.isNotEmpty) {
      await ApiConfig.setupOpenAI(
        apiKey: apiKey,
        enabled: true,
      );
    } else {
      print('⚠️ OpenAI API key não encontrada no storage seguro');
      print('   Configure via Perfil > Configurações de IA');
    }
    
    print('✅ OpenAI configurada');
  }
  
  /// Verifica se todas as configurações estão corretas
  static Future<void> _verifyConfiguration() async {
    print('🔍 Verificando configurações...');
    
    final checks = <String, bool>{};
    
    // Verificar OpenAI
    try {
      final openaiService = Get.find<OpenAIService>();
      checks['OpenAI Configurada'] = await openaiService.isConfigured();
      checks['OpenAI Online'] = await openaiService.checkApiStatus();
    } catch (e) {
      checks['OpenAI'] = false;
      print('⚠️ Erro ao verificar OpenAI: $e');
    }
    
    // Verificar Storage
    try {
      final secureStorage = Get.find<SecureStorage>();
      await secureStorage.write('test_key', 'test_value');
      final testValue = await secureStorage.read('test_key');
      checks['Storage Seguro'] = testValue == 'test_value';
      await secureStorage.delete('test_key');
    } catch (e) {
      checks['Storage Seguro'] = false;
      print('⚠️ Erro ao verificar storage: $e');
    }
    
    // Exibir resultados
    print('\n📊 Status das Configurações:');
    checks.forEach((key, value) {
      print('${value ? '✅' : '❌'} $key');
    });
    
    // Verificar se tudo está funcionando
    final allGood = checks.values.every((check) => check);
    if (allGood) {
      print('\n🎉 Todas as configurações estão funcionando!');
    } else {
      print('\n⚠️ Algumas configurações precisam de atenção');
    }
  }
  
  /// Configuração específica para desenvolvimento
  static Future<void> initializeForDevelopment() async {
    print('🚧 Inicializando para desenvolvimento...');
    
    await _initializeSecureStorage();
    
    // Registrar OnboardingService
    await _initializeOnboardingService();
    
    // Registrar OpenAI mas sem configurar (para testes)
    Get.put(OpenAIService(), permanent: true);
    await ApiConfig.setupForDevelopment();
    
    print('✅ Desenvolvimento configurado (IA simulada)');
  }
  
  /// Configuração para produção
  static Future<void> initializeForProduction() async {
    print('🏭 Inicializando para produção...');
    
    await initialize();
    
    // Configurações adicionais de produção
    await _setupProductionSettings();
    
    print('✅ Produção configurada');
  }
  
  /// Configurações específicas de produção
  static Future<void> _setupProductionSettings() async {
    // Configurar rate limiting, cache, etc.
    final recommendations = ApiConfig.getProductionRecommendations();
    print('📋 Configurações de produção aplicadas:');
    recommendations.forEach((key, value) {
      print('  • $key: $value');
    });
  }
  
  /// Limpa todas as configurações (útil para reset)
  static Future<void> reset() async {
    print('🗑️ Limpando configurações...');
    
    try {
      await ApiConfig.clearOpenAIConfig();
      
      final secureStorage = Get.find<SecureStorage>();
      // Limpar dados específicos, não todos
      await secureStorage.delete('openai_api_key');
      await secureStorage.delete('openai_enabled');
      
      print('✅ Configurações limpas');
    } catch (e) {
      print('❌ Erro ao limpar configurações: $e');
    }
  }
  
  /// Informações sobre o status atual
  static Future<Map<String, dynamic>> getStatus() async {
    final status = <String, dynamic>{};
    
    try {
      // Status OpenAI
      final openaiService = Get.find<OpenAIService>();
      status['openai'] = {
        'configured': await openaiService.isConfigured(),
        'online': await openaiService.checkApiStatus(),
        'enabled': await ApiConfig.isOpenAIEnabled(),
      };
      
      // Estimativa de custos
      status['cost_estimate'] = ApiConfig.estimateMonthlyUsage(
        dailyUsers: 50, // Estimativa conservadora
        messagesPerUserPerDay: 3,
        insightsPerUserPerDay: 1,
      );
      
      // Configurações gerais
      status['app'] = {
        'version': '1.0.0',
        'environment': kDebugMode ? 'development' : 'production',
        'platform': defaultTargetPlatform.name,
      };
      
    } catch (e) {
      status['error'] = e.toString();
    }
    
    return status;
  }
}
