/// Helper para debug de anúncios AdMob
/// Execute este código para diagnosticar problemas com anúncios
/// 
/// Tokens utilizados:
/// - Nenhum token de cor (serviço de debug)

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;

class AdsDebugHelper {
  /// Executa diagnóstico completo do sistema de anúncios
  static Future<Map<String, dynamic>> runDiagnostic() async {
    final results = <String, dynamic>{};
    
    print('═══════════════════════════════════════════════════════');
    print('🔍 DIAGNÓSTICO DE ANÚNCIOS ADMOB');
    print('═══════════════════════════════════════════════════════');
    
    // 1. Verificar ambiente
    results['environment'] = {
      'isDebugMode': kDebugMode,
      'isReleaseMode': kReleaseMode,
      'isProfileMode': kProfileMode,
      'platform': Platform.isIOS ? 'iOS' : (Platform.isAndroid ? 'Android' : 'Unknown'),
    };
    
    print('\n📱 AMBIENTE:');
    print('   Debug Mode: $kDebugMode');
    print('   Release Mode: $kReleaseMode');
    print('   Plataforma: ${Platform.isIOS ? "iOS" : "Android"}');
    
    // 2. Verificar inicialização do SDK
    print('\n🔧 INICIALIZANDO SDK...');
    try {
      final initStatus = await MobileAds.instance.initialize();
      final adapters = initStatus.adapterStatuses;
      
      results['sdkInitialization'] = {
        'success': true,
        'adaptersCount': adapters.length,
        'adapters': adapters.map((key, value) => MapEntry(key, {
          'state': value.state.name,
          'description': value.description,
        })),
      };
      
      print('   ✅ SDK inicializado com sucesso');
      print('   Adaptadores: ${adapters.length}');
      adapters.forEach((name, status) {
        final icon = status.state == AdapterInitializationState.ready ? '✅' : '⚠️';
        print('   $icon $name: ${status.state.name}');
        if (status.description.isNotEmpty) {
          print('      └─ ${status.description}');
        }
      });
    } catch (e) {
      results['sdkInitialization'] = {
        'success': false,
        'error': e.toString(),
      };
      print('   ❌ ERRO na inicialização: $e');
    }
    
    // 3. Testar carregamento de anúncio de TESTE
    print('\n🎬 TESTANDO CARREGAMENTO DE REWARDED AD (ID DE TESTE)...');
    final testAdUnitId = 'ca-app-pub-3940256099942544/5224354917'; // ID oficial de teste
    
    try {
      final loadResult = await _testRewardedAdLoad(testAdUnitId);
      results['testAdLoad'] = loadResult;
      
      if (loadResult['success'] == true) {
        print('   ✅ Anúncio de TESTE carregou com sucesso!');
        print('   Response ID: ${loadResult['responseId']}');
      } else {
        print('   ❌ ERRO ao carregar anúncio de teste:');
        print('   Código: ${loadResult['errorCode']}');
        print('   Mensagem: ${loadResult['errorMessage']}');
        print('   Domínio: ${loadResult['errorDomain']}');
      }
    } catch (e) {
      results['testAdLoad'] = {
        'success': false,
        'error': e.toString(),
      };
      print('   ❌ Exceção: $e');
    }
    
    // 4. Resumo e recomendações
    print('\n═══════════════════════════════════════════════════════');
    print('📋 RESUMO DO DIAGNÓSTICO');
    print('═══════════════════════════════════════════════════════');
    
    _printDiagnosticSummary(results);
    
    return results;
  }
  
  /// Testa carregamento de um Rewarded Ad
  static Future<Map<String, dynamic>> _testRewardedAdLoad(String adUnitId) async {
    final completer = <String, dynamic>{};
    var isComplete = false;
    
    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          completer['success'] = true;
          completer['responseId'] = ad.responseInfo?.responseId;
          completer['mediationAdapterClassName'] = ad.responseInfo?.mediationAdapterClassName;
          ad.dispose(); // Descarta após teste
          isComplete = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          completer['success'] = false;
          completer['errorCode'] = error.code;
          completer['errorMessage'] = error.message;
          completer['errorDomain'] = error.domain;
          isComplete = true;
        },
      ),
    );
    
    // Aguarda até 15 segundos pelo callback
    for (var i = 0; i < 150 && !isComplete; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    if (!isComplete) {
      completer['success'] = false;
      completer['error'] = 'Timeout - nenhuma resposta em 15 segundos';
    }
    
    return completer;
  }
  
  /// Imprime resumo com recomendações
  static void _printDiagnosticSummary(Map<String, dynamic> results) {
    final env = results['environment'] as Map<String, dynamic>;
    final sdk = results['sdkInitialization'] as Map<String, dynamic>?;
    final testAd = results['testAdLoad'] as Map<String, dynamic>?;
    
    // Verificar problemas
    final issues = <String>[];
    final recommendations = <String>[];
    
    // SDK
    if (sdk?['success'] != true) {
      issues.add('SDK não inicializou corretamente');
      recommendations.add('Verifique se o GADApplicationIdentifier está correto no Info.plist (iOS) ou AndroidManifest.xml (Android)');
    }
    
    // Anúncio de teste
    if (testAd?['success'] == true) {
      print('✅ Anúncio de TESTE funcionando - integração OK!');
      
      if (env['isDebugMode'] == false) {
        recommendations.add('Em produção, o problema provavelmente é:');
        recommendations.add('  • No fill (sem inventário disponível)');
        recommendations.add('  • Conta AdMob em avaliação ou com limitação');
        recommendations.add('  • ATT/Consentimento não configurado (iOS)');
        recommendations.add('  • app-ads.txt ausente ou incorreto');
      }
    } else {
      issues.add('Anúncio de TESTE não carregou');
      
      final errorCode = testAd?['errorCode'];
      if (errorCode == 3) {
        recommendations.add('Código 3 = No fill - sem anúncio disponível');
        recommendations.add('Mesmo anúncios de teste podem ter no fill em certas condições');
        recommendations.add('Tente novamente em alguns segundos');
      } else if (errorCode == 0) {
        recommendations.add('Código 0 = Erro interno ou configuração');
        recommendations.add('Verifique se o App ID está correto no manifest');
      } else if (errorCode == 2) {
        recommendations.add('Código 2 = Erro de rede');
        recommendations.add('Verifique a conexão com a internet');
      }
    }
    
    // Imprimir issues
    if (issues.isNotEmpty) {
      print('\n⚠️ PROBLEMAS ENCONTRADOS:');
      for (final issue in issues) {
        print('   • $issue');
      }
    }
    
    // Imprimir recomendações
    if (recommendations.isNotEmpty) {
      print('\n💡 RECOMENDAÇÕES:');
      for (final rec in recommendations) {
        print('   $rec');
      }
    }
    
    print('\n═══════════════════════════════════════════════════════');
  }
  
  /// Abre o Ad Inspector (ferramenta de debug do AdMob)
  static Future<void> openAdInspector() async {
    print('🔍 Abrindo Ad Inspector...');
    try {
      MobileAds.instance.openAdInspector((error) {
        if (error != null) {
          print('❌ Erro ao abrir Ad Inspector: $error');
        }
      });
    } catch (e) {
      print('❌ Exceção ao abrir Ad Inspector: $e');
    }
  }
}
