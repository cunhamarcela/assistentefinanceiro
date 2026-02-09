import 'package:get/get.dart';
import '../services/openai_service.dart';
import '../storage/secure_storage.dart';

class ApiConfig {
  static const String _openaiApiKeyKey = 'openai_api_key';
  static const String _isOpenaiEnabledKey = 'openai_enabled';
  
  /// Configura a API key da OpenAI
  /// Esta função deve ser chamada durante o setup inicial do app
  static Future<void> setupOpenAI({
    required String apiKey,
    bool enabled = true,
  }) async {
    try {
      final secureStorage = Get.find<SecureStorage>();
      final openaiService = Get.find<OpenAIService>();
      
      // Salva a API key de forma segura
      await secureStorage.write(_openaiApiKeyKey, apiKey);
      await secureStorage.write(_isOpenaiEnabledKey, enabled.toString());
      
      // Configura o serviço
      await openaiService.setApiKey(apiKey);
      
      // Testa a conexão
      final isWorking = await openaiService.checkApiStatus();
      
      if (isWorking) {
        print('✅ OpenAI configurada com sucesso!');
      } else {
        print('⚠️ OpenAI configurada mas não está respondendo');
      }
    } catch (e) {
      print('❌ Erro ao configurar OpenAI: $e');
      throw Exception('Falha na configuração da OpenAI: $e');
    }
  }
  
  /// Verifica se a OpenAI está configurada e habilitada
  static Future<bool> isOpenAIEnabled() async {
    try {
      final secureStorage = Get.find<SecureStorage>();
      final enabled = await secureStorage.read(_isOpenaiEnabledKey);
      final apiKey = await secureStorage.read(_openaiApiKeyKey);
      
      return enabled == 'true' && apiKey != null && apiKey.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Habilita ou desabilita a OpenAI
  static Future<void> setOpenAIEnabled(bool enabled) async {
    try {
      final secureStorage = Get.find<SecureStorage>();
      await secureStorage.write(_isOpenaiEnabledKey, enabled.toString());
      
      print('${enabled ? '✅' : '❌'} OpenAI ${enabled ? 'habilitada' : 'desabilitada'}');
    } catch (e) {
      print('❌ Erro ao alterar status da OpenAI: $e');
    }
  }
  
  /// Remove configurações da OpenAI
  static Future<void> clearOpenAIConfig() async {
    try {
      final secureStorage = Get.find<SecureStorage>();
      await secureStorage.delete(_openaiApiKeyKey);
      await secureStorage.delete(_isOpenaiEnabledKey);
      
      print('🗑️ Configurações da OpenAI removidas');
    } catch (e) {
      print('❌ Erro ao limpar configurações da OpenAI: $e');
    }
  }
  
  /// Configuração para desenvolvimento/testes
  /// NUNCA usar em produção com API key real
  static Future<void> setupForDevelopment() async {
    const devApiKey = 'sk-dev-test-key-not-real';
    
    print('🚧 Configurando OpenAI para desenvolvimento (sem IA real)');
    
    try {
      final secureStorage = Get.find<SecureStorage>();
      await secureStorage.write(_openaiApiKeyKey, devApiKey);
      await secureStorage.write(_isOpenaiEnabledKey, 'false'); // Desabilitada em dev
      
      print('✅ Configuração de desenvolvimento aplicada');
    } catch (e) {
      print('❌ Erro na configuração de desenvolvimento: $e');
    }
  }
  
  /// Estima custos mensais baseado no uso
  static Map<String, dynamic> estimateMonthlyUsage({
    int dailyUsers = 100,
    int messagesPerUserPerDay = 5,
    int insightsPerUserPerDay = 2,
  }) {
    final openaiService = Get.find<OpenAIService>();
    
    final totalDailyMessages = dailyUsers * messagesPerUserPerDay;
    final totalDailyInsights = dailyUsers * insightsPerUserPerDay;
    
    final estimate = openaiService.estimateUsageCost(
      messagesPerDay: totalDailyMessages,
      insightsPerDay: totalDailyInsights,
    );
    
    return {
      ...estimate,
      'daily_users': dailyUsers,
      'messages_per_user_per_day': messagesPerUserPerDay,
      'insights_per_user_per_day': insightsPerUserPerDay,
      'total_daily_messages': totalDailyMessages,
      'total_daily_insights': totalDailyInsights,
    };
  }
  
  /// Configurações recomendadas para produção
  static Map<String, dynamic> getProductionRecommendations() {
    return {
      'model': 'gpt-4o-mini', // Mais econômico
      'max_tokens_chat': 400,
      'max_tokens_insight': 500,
      'temperature': 0.7,
      'rate_limit_per_user_per_hour': 20,
      'fallback_enabled': true,
      'cache_responses': true,
      'cache_duration_hours': 1,
      'estimated_monthly_cost_100_users': 'R\$ 150-300',
      'recommended_usage_monitoring': true,
    };
  }
}

/// Extensão para facilitar uso nos controllers
extension ApiConfigExtension on GetxController {
  Future<bool> get isAIEnabled => ApiConfig.isOpenAIEnabled();
  
  Future<void> setupAI(String apiKey) => ApiConfig.setupOpenAI(apiKey: apiKey);
  
  Future<void> toggleAI(bool enabled) => ApiConfig.setOpenAIEnabled(enabled);
}
