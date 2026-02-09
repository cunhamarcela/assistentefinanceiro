import 'dart:io' show Platform, File, FileMode;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../features/monetization/domain/entities/usage_limit.dart';
import '../../features/monetization/domain/entities/feature_unlock.dart';
import '../../features/monetization/data/services/usage_limit_service.dart';
import 'analytics_service.dart';
import 'att_service.dart';

// #region agent log
void _debugLog(String hypothesisId, String location, String message, Map<String, dynamic> data) {
  try {
    final logEntry = '{"hypothesisId":"$hypothesisId","location":"$location","message":"$message","data":${data.toString().replaceAll("'", '"')},"timestamp":${DateTime.now().millisecondsSinceEpoch},"sessionId":"debug-ads"}\n';
    File('/Users/marcelacunha/meus_apps/assistente_financeiro/.cursor/debug.log').writeAsStringSync(logEntry, mode: FileMode.append);
  } catch (e) { /* ignore */ }
}
// #endregion

/// Configuração de IDs de anúncios
/// 
/// Tokens utilizados:
/// - Nenhum token de cor (serviço de backend)
class AdConfig {
  // ========================================
  // IDs de TESTE do Google AdMob (para desenvolvimento)
  // Estes IDs são oficiais do Google para testes
  // ========================================
  static const String testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  
  // ========================================
  // IDs de PRODUÇÃO - SUBSTITUA pelos seus IDs reais do AdMob
  // ========================================
  
  // iOS - Ad Unit ID real do AdMob (PRODUÇÃO)
  static const String prodRewardedAdUnitIdIOS = 'ca-app-pub-6286381265499018/7433719494';
  static const String prodInterstitialAdUnitIdIOS = 'ca-app-pub-6286381265499018/4081630365';
  
  // Android - Substitua pelo seu Ad Unit ID do AdMob para Android
  // Formato: ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY
  static const String prodRewardedAdUnitIdAndroid = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
  static const String prodInterstitialAdUnitIdAndroid = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
  
  /// Obtém o ID do anúncio recompensado baseado no ambiente e plataforma
  static String get rewardedAdUnitId {
    // Em modo debug, sempre usa IDs de teste
    if (kDebugMode) {
      return testRewardedAdUnitId;
    }
    
    // Em produção, usa o ID correto para cada plataforma
    if (Platform.isIOS) {
      return prodRewardedAdUnitIdIOS;
    } else if (Platform.isAndroid) {
      return prodRewardedAdUnitIdAndroid;
    }
    
    // Fallback para teste se plataforma não identificada
    return testRewardedAdUnitId;
  }
  
  /// Obtém o ID do anúncio intersticial baseado no ambiente e plataforma
  static String get interstitialAdUnitId {
    // Em modo debug, sempre usa IDs de teste
    if (kDebugMode) {
      return testInterstitialAdUnitId;
    }
    
    // Em produção, usa o ID correto para cada plataforma
    if (Platform.isIOS) {
      return prodInterstitialAdUnitIdIOS;
    } else if (Platform.isAndroid) {
      return prodInterstitialAdUnitIdAndroid;
    }
    
    // Fallback para teste se plataforma não identificada
    return testInterstitialAdUnitId;
  }
  
  /// Verifica se está usando IDs de teste
  static bool get isUsingTestAds => kDebugMode;
}

/// Resultado da exibição de um anúncio
class AdResult {
  final bool success;
  final String? error;
  final int? rewardAmount;
  final String? rewardType;

  const AdResult({
    required this.success,
    this.error,
    this.rewardAmount,
    this.rewardType,
  });

  factory AdResult.success({int? rewardAmount, String? rewardType}) {
    return AdResult(
      success: true,
      rewardAmount: rewardAmount,
      rewardType: rewardType,
    );
  }

  factory AdResult.failed(String error) {
    return AdResult(
      success: false,
      error: error,
    );
  }
}

/// Serviço para gerenciar anúncios do app
/// 
/// Este serviço gerencia a inicialização, carregamento e exibição
/// de anúncios recompensados (Rewarded Ads) e intersticiais (Interstitial Ads) 
/// do Google AdMob.
class AdsService extends GetxService {
  static AdsService get instance => Get.find<AdsService>();

  // Estado do serviço
  final RxBool isInitialized = false.obs;
  final RxBool isRewardedAdReady = false.obs;
  final RxBool isInterstitialAdReady = false.obs;
  final RxBool isLoadingAd = false.obs;
  final RxBool isLoadingInterstitial = false.obs;
  
  // Mensagem de último erro (para debug)
  final RxString lastError = ''.obs;
  
  // Anúncio recompensado carregado
  RewardedAd? _rewardedAd;
  
  // Anúncio intersticial carregado
  InterstitialAd? _interstitialAd;

  // Callback para quando o anúncio for concluído
  Function(FeatureUnlock?)? _onRewardedAdCompleted;

  // Feature atual sendo desbloqueada
  FeatureType? _currentFeatureType;
  
  // Duração do desbloqueio atual
  int _currentDurationHours = 24;
  
  // Analytics service para rastreamento
  AnalyticsService? _analyticsService;
  
  // Contador de tentativas de carregamento
  int _loadAttempts = 0;
  int _interstitialLoadAttempts = 0;
  static const int _maxLoadAttempts = 3;

  @override
  void onInit() {
    super.onInit();
    // #region agent log
    _debugLog('H1', 'ads_service.dart:onInit', 'AdsService.onInit chamado', {'timestamp': DateTime.now().toIso8601String()});
    // #endregion
    if (kDebugMode) {
      print('🎬 AdsService.onInit() chamado');
    }
    _initializeAds();
  }

  /// Inicializa o SDK de anúncios do Google Mobile Ads
  Future<void> _initializeAds() async {
    // #region agent log
    _debugLog('H2', 'ads_service.dart:_initializeAds:start', 'Iniciando inicializacao do SDK', {'platform': Platform.isIOS ? 'iOS' : 'Android'});
    // #endregion
    try {
      // IMPORTANTE: Solicitar ATT ANTES de inicializar o SDK de anúncios
      // Isso é crucial para ter fill rate em iOS 14+
      await _requestATTPermission();
      
      // Inicializa o SDK do Google Mobile Ads
      final initStatus = await MobileAds.instance.initialize();
      // #region agent log
      _debugLog('H2', 'ads_service.dart:_initializeAds:sdk_init', 'SDK inicializado', {'adapterStatuses': initStatus.adapterStatuses.keys.toList().toString()});
      // #endregion
      
      // Obtém referência ao AnalyticsService
      _initializeAnalytics();
      
      isInitialized.value = true;
      
      // Pré-carrega um anúncio recompensado
      await _loadRewardedAd();
      
      // Pré-carrega um anúncio intersticial
      await _loadInterstitialAd();
      
      // #region agent log
      _debugLog('H2', 'ads_service.dart:_initializeAds:success', 'AdsService inicializado com sucesso', {'isInitialized': isInitialized.value, 'isRewardedAdReady': isRewardedAdReady.value, 'isInterstitialAdReady': isInterstitialAdReady.value, 'isUsingTestAds': AdConfig.isUsingTestAds});
      // #endregion
      
      if (kDebugMode) {
        print('✅ AdsService inicializado com sucesso');
        print('   Usando IDs de teste: ${AdConfig.isUsingTestAds}');
        print('   Plataforma: ${Platform.isIOS ? "iOS" : "Android"}');
        print('   Interstitial Ad Unit ID: ${AdConfig.interstitialAdUnitId}');
      }
    } catch (e) {
      // #region agent log
      _debugLog('H2', 'ads_service.dart:_initializeAds:error', 'Erro ao inicializar SDK', {'error': e.toString()});
      // #endregion
      if (kDebugMode) {
        print('❌ Erro ao inicializar AdsService: $e');
      }
    }
  }
  
  /// Inicializa referência ao AnalyticsService
  void _initializeAnalytics() {
    try {
      _analyticsService = AnalyticsService.instance;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ AnalyticsService não disponível para AdsService: $e');
      }
    }
  }
  
  /// Solicita permissão ATT (App Tracking Transparency) no iOS
  /// 
  /// CRÍTICO: Deve ser chamado ANTES de inicializar o SDK de anúncios!
  /// Sem ATT autorizado, o fill rate cai drasticamente no iOS 14+.
  Future<void> _requestATTPermission() async {
    if (!Platform.isIOS) {
      if (kDebugMode) {
        print('📱 AdsService: Não é iOS, pulando ATT');
      }
      return;
    }
    
    try {
      // Verifica se o ATTService está registrado
      if (!Get.isRegistered<ATTService>()) {
        // Registra o serviço se não existir
        final attService = ATTService();
        Get.put<ATTService>(attService, permanent: true);
        await Future.delayed(const Duration(milliseconds: 100)); // Aguarda inicialização
      }
      
      final attService = Get.find<ATTService>();
      
      // Aguarda um pequeno delay para garantir que o app está pronto
      // O ATT deve ser pedido depois que o app está visível
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Solicita permissão
      final authorized = await attService.requestTrackingPermission();
      
      // #region agent log
      _debugLog('H2', 'ads_service.dart:_requestATTPermission:result', 'Resultado ATT', {'authorized': authorized, 'status': attService.consentStatus.value.name});
      // #endregion
      
      if (kDebugMode) {
        print('📱 AdsService: ATT solicitado');
        print('   Autorizado: $authorized');
        print('   Status: ${attService.consentStatus.value}');
      }
      
      // Rastreia no analytics
      _analyticsService?.trackCustomEvent(
        name: 'att_permission_result',
        properties: {
          'authorized': authorized.toString(),
          'status': attService.consentStatus.value.name,
        },
      );
      
    } catch (e) {
      // #region agent log
      _debugLog('H2', 'ads_service.dart:_requestATTPermission:error', 'Erro ao solicitar ATT', {'error': e.toString()});
      // #endregion
      if (kDebugMode) {
        print('⚠️ AdsService: Erro ao solicitar ATT: $e');
        print('   Continuando sem ATT (fill rate pode ser baixo)');
      }
    }
  }

  /// Carrega um anúncio recompensado
  Future<void> _loadRewardedAd() async {
    // #region agent log
    _debugLog('H3', 'ads_service.dart:_loadRewardedAd:entry', 'Iniciando carregamento de anuncio', {'isLoadingAd': isLoadingAd.value, 'loadAttempts': _loadAttempts, 'maxAttempts': _maxLoadAttempts});
    // #endregion
    
    if (isLoadingAd.value) {
      if (kDebugMode) {
        print('⏳ AdsService: já carregando anúncio, ignorando...');
      }
      return;
    }
    
    if (_loadAttempts >= _maxLoadAttempts) {
      // #region agent log
      _debugLog('H3', 'ads_service.dart:_loadRewardedAd:max_attempts', 'Maximo de tentativas atingido', {'loadAttempts': _loadAttempts});
      // #endregion
      if (kDebugMode) {
        print('⚠️ AdsService: máximo de tentativas atingido ($_loadAttempts)');
      }
      // Reseta após 5 minutos para tentar novamente
      Future.delayed(const Duration(minutes: 5), () {
        _loadAttempts = 0;
      });
      return;
    }
    
    try {
      isLoadingAd.value = true;
      _loadAttempts++;
      lastError.value = '';
      
      final adUnitId = AdConfig.rewardedAdUnitId;
      
      // #region agent log
      _debugLog('H3', 'ads_service.dart:_loadRewardedAd:loading', 'Chamando RewardedAd.load', {'adUnitId': adUnitId, 'attempt': _loadAttempts, 'isTestAd': AdConfig.isUsingTestAds});
      // #endregion
      
      if (kDebugMode) {
        print('🔄 AdsService: Carregando anúncio...');
        print('   Ad Unit ID: $adUnitId');
        print('   Tentativa: $_loadAttempts/$_maxLoadAttempts');
        print('   É ID de teste: ${AdConfig.isUsingTestAds}');
      }
      
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            // #region agent log
            _debugLog('H3', 'ads_service.dart:onAdLoaded', 'Anuncio carregado com sucesso!', {'responseId': ad.responseInfo?.responseId ?? 'null', 'adUnitId': adUnitId});
            // #endregion
            
            if (kDebugMode) {
              print('✅ AdsService: Anúncio carregado com sucesso!');
              print('   Response Info: ${ad.responseInfo?.responseId}');
            }
            
            _rewardedAd = ad;
            isRewardedAdReady.value = true;
            isLoadingAd.value = false;
            _loadAttempts = 0; // Reseta contador em sucesso
            lastError.value = '';
            
            // Configura callbacks do anúncio
            _setupAdCallbacks(ad);
          },
          onAdFailedToLoad: (LoadAdError error) {
            final errorMsg = '${error.message} (código: ${error.code}, domínio: ${error.domain})';
            lastError.value = errorMsg;
            
            // #region agent log
            _debugLog('H3', 'ads_service.dart:onAdFailedToLoad', 'Falha ao carregar anuncio', {'errorCode': error.code, 'errorMessage': error.message, 'errorDomain': error.domain, 'adUnitId': adUnitId});
            // #endregion
            
            if (kDebugMode) {
              print('❌ AdsService: Falha ao carregar anúncio');
              print('   Mensagem: ${error.message}');
              print('   Código: ${error.code}');
              print('   Domínio: ${error.domain}');
              print('   Ad Unit ID: $adUnitId');
            }
            
            // Rastreia falha no analytics
            _analyticsService?.trackAdFailed(
              adUnitId: adUnitId,
              errorMessage: error.message,
              errorCode: error.code,
            );
            
            _rewardedAd = null;
            isRewardedAdReady.value = false;
            isLoadingAd.value = false;
            
            // Tenta recarregar após um delay (aumenta delay a cada tentativa)
            final delay = Duration(seconds: 10 * _loadAttempts);
            if (kDebugMode) {
              print('⏰ AdsService: Tentando novamente em ${delay.inSeconds}s');
            }
            Future.delayed(delay, () {
              if (!isRewardedAdReady.value && !isLoadingAd.value) {
                _loadRewardedAd();
              }
            });
          },
        ),
      );
    } catch (e) {
      lastError.value = e.toString();
      if (kDebugMode) {
        print('❌ AdsService: Exceção ao carregar anúncio: $e');
      }
      isLoadingAd.value = false;
    }
  }
  
  /// Configura os callbacks do anúncio carregado
  void _setupAdCallbacks(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        if (kDebugMode) {
          print('📺 Anúncio exibido em tela cheia');
        }
        
        // Rastreia início do anúncio
        _analyticsService?.trackAdStarted(
          adUnitId: AdConfig.rewardedAdUnitId,
          featureType: _currentFeatureType?.name ?? 'unknown',
        );
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        if (kDebugMode) {
          print('📺 Anúncio fechado pelo usuário');
        }
        
        // Descarta o anúncio usado
        ad.dispose();
        _rewardedAd = null;
        isRewardedAdReady.value = false;
        
        // Carrega o próximo anúncio
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        if (kDebugMode) {
          print('❌ Falha ao exibir anúncio: ${error.message}');
        }
        
        // Rastreia falha no analytics
        _analyticsService?.trackAdFailed(
          adUnitId: AdConfig.rewardedAdUnitId,
          errorMessage: error.message,
          errorCode: error.code,
        );
        
        // Descarta o anúncio com erro
        ad.dispose();
        _rewardedAd = null;
        isRewardedAdReady.value = false;
        
        // Carrega um novo anúncio
        _loadRewardedAd();
      },
      onAdImpression: (RewardedAd ad) {
        if (kDebugMode) {
          print('📊 Impressão de anúncio registrada');
        }
        
        // Rastreia impressão no analytics
        _analyticsService?.trackAdImpression(
          adUnitId: AdConfig.rewardedAdUnitId,
          featureType: _currentFeatureType?.name ?? 'unknown',
          adFormat: 'rewarded',
        );
      },
    );
  }

  // ========================================
  // INTERSTITIAL ADS - Anúncios Intersticiais
  // ========================================

  /// Carrega um anúncio intersticial
  Future<void> _loadInterstitialAd() async {
    // #region agent log
    _debugLog('H3', 'ads_service.dart:_loadInterstitialAd:entry', 'Iniciando carregamento de interstitial', {'isLoadingInterstitial': isLoadingInterstitial.value, 'interstitialLoadAttempts': _interstitialLoadAttempts});
    // #endregion
    
    if (isLoadingInterstitial.value) {
      if (kDebugMode) {
        print('⏳ AdsService: já carregando interstitial, ignorando...');
      }
      return;
    }
    
    if (_interstitialAd != null) {
      if (kDebugMode) {
        print('✅ AdsService: interstitial já carregado');
      }
      return;
    }
    
    if (_interstitialLoadAttempts >= _maxLoadAttempts) {
      if (kDebugMode) {
        print('⚠️ AdsService: máximo de tentativas de interstitial atingido ($_interstitialLoadAttempts)');
      }
      // Reseta após 5 minutos para tentar novamente
      Future.delayed(const Duration(minutes: 5), () {
        _interstitialLoadAttempts = 0;
      });
      return;
    }
    
    try {
      isLoadingInterstitial.value = true;
      _interstitialLoadAttempts++;
      
      final adUnitId = AdConfig.interstitialAdUnitId;
      
      if (kDebugMode) {
        print('🔄 AdsService: Carregando interstitial...');
        print('   Ad Unit ID: $adUnitId');
        print('   Tentativa: $_interstitialLoadAttempts/$_maxLoadAttempts');
      }
      
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            // #region agent log
            _debugLog('H3', 'ads_service.dart:onInterstitialAdLoaded', 'Interstitial carregado com sucesso!', {'adUnitId': adUnitId});
            // #endregion
            
            if (kDebugMode) {
              print('✅ AdsService: Interstitial carregado com sucesso!');
            }
            
            _interstitialAd = ad;
            isInterstitialAdReady.value = true;
            isLoadingInterstitial.value = false;
            _interstitialLoadAttempts = 0;
            
            // Configura callbacks do interstitial
            _setupInterstitialCallbacks(ad);
          },
          onAdFailedToLoad: (LoadAdError error) {
            // #region agent log
            _debugLog('H3', 'ads_service.dart:onInterstitialAdFailedToLoad', 'Falha ao carregar interstitial', {'errorCode': error.code, 'errorMessage': error.message});
            // #endregion
            
            if (kDebugMode) {
              print('❌ AdsService: Falha ao carregar interstitial');
              print('   Mensagem: ${error.message}');
              print('   Código: ${error.code}');
            }
            
            _interstitialAd = null;
            isInterstitialAdReady.value = false;
            isLoadingInterstitial.value = false;
            
            // Tenta recarregar após um delay
            final delay = Duration(seconds: 10 * _interstitialLoadAttempts);
            Future.delayed(delay, () {
              if (!isInterstitialAdReady.value && !isLoadingInterstitial.value) {
                _loadInterstitialAd();
              }
            });
          },
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ AdsService: Exceção ao carregar interstitial: $e');
      }
      isLoadingInterstitial.value = false;
    }
  }
  
  /// Configura os callbacks do anúncio intersticial
  void _setupInterstitialCallbacks(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        if (kDebugMode) {
          print('📺 Interstitial exibido em tela cheia');
        }
        
        // Rastreia impressão no analytics
        _analyticsService?.trackAdImpression(
          adUnitId: AdConfig.interstitialAdUnitId,
          featureType: 'interstitial',
          adFormat: 'interstitial',
        );
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        if (kDebugMode) {
          print('📺 Interstitial fechado pelo usuário');
        }
        
        // Descarta o anúncio usado
        ad.dispose();
        _interstitialAd = null;
        isInterstitialAdReady.value = false;
        
        // Pré-carrega o próximo interstitial
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        if (kDebugMode) {
          print('❌ Falha ao exibir interstitial: ${error.message}');
        }
        
        // Rastreia falha no analytics
        _analyticsService?.trackAdFailed(
          adUnitId: AdConfig.interstitialAdUnitId,
          errorMessage: error.message,
          errorCode: error.code,
        );
        
        // Descarta o anúncio com erro
        ad.dispose();
        _interstitialAd = null;
        isInterstitialAdReady.value = false;
        
        // Carrega um novo anúncio
        _loadInterstitialAd();
      },
      onAdImpression: (InterstitialAd ad) {
        if (kDebugMode) {
          print('📊 Impressão de interstitial registrada');
        }
      },
    );
  }

  /// Mostra o anúncio intersticial se disponível
  /// Retorna true se o anúncio foi exibido, false caso contrário
  Future<bool> showInterstitialIfAvailable() async {
    // #region agent log
    _debugLog('H3', 'ads_service.dart:showInterstitialIfAvailable', 'Tentando mostrar interstitial', {'isInterstitialAdReady': isInterstitialAdReady.value, 'hasAd': _interstitialAd != null});
    // #endregion
    
    if (_interstitialAd == null || !isInterstitialAdReady.value) {
      if (kDebugMode) {
        print('⚠️ AdsService: Interstitial não disponível');
      }
      // Tenta carregar para a próxima vez
      _loadInterstitialAd();
      return false;
    }

    try {
      if (kDebugMode) {
        print('📺 AdsService: Exibindo interstitial...');
      }
      
      await _interstitialAd!.show();
      _interstitialAd = null;
      isInterstitialAdReady.value = false;
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AdsService: Erro ao mostrar interstitial: $e');
      }
      return false;
    }
  }

  /// Pré-carrega o anúncio intersticial (chamar na inicialização de telas)
  void loadInterstitial() {
    if (!isInterstitialAdReady.value && !isLoadingInterstitial.value) {
      _interstitialLoadAttempts = 0;
      _loadInterstitialAd();
    }
  }

  /// Verifica se há interstitial pronto para exibição
  bool get hasInterstitialReady => isInterstitialAdReady.value && _interstitialAd != null;

  // ========================================
  // REWARDED ADS - Anúncios Recompensados
  // ========================================

  /// Mostra um anúncio recompensado para desbloquear uma feature
  Future<AdResult> showRewardedAdForFeature({
    required FeatureType featureType,
    int durationHours = 24,
  }) async {
    _currentFeatureType = featureType;
    _currentDurationHours = durationHours;
    
    // #region agent log
    _debugLog('H1', 'ads_service.dart:showRewardedAdForFeature:entry', 'Iniciando showRewardedAdForFeature', {
      'featureType': featureType.name,
      'isRewardedAdReady': isRewardedAdReady.value,
      'hasRewardedAd': _rewardedAd != null,
      'isLoadingAd': isLoadingAd.value,
      'lastError': lastError.value,
    });
    // #endregion
    
    if (kDebugMode) {
      print('🎬 showRewardedAdForFeature chamado');
      print('   Feature: ${featureType.name}');
      print('   isRewardedAdReady: ${isRewardedAdReady.value}');
      print('   _rewardedAd != null: ${_rewardedAd != null}');
      print('   isLoadingAd: ${isLoadingAd.value}');
      print('   lastError: ${lastError.value}');
    }
    
    if (!isRewardedAdReady.value || _rewardedAd == null) {
      if (kDebugMode) {
        print('⏳ Anúncio não está pronto, tentando carregar...');
      }
      
      // Reseta tentativas para permitir novo carregamento
      _loadAttempts = 0;
      
      // Tenta carregar se não estiver pronto
      await _loadRewardedAd();
      
      // Aguarda até 10 segundos com polling (mais eficiente que espera fixa)
      const maxWaitSeconds = 10;
      for (var i = 0; i < maxWaitSeconds * 2; i++) {
        if (isRewardedAdReady.value && _rewardedAd != null) {
          if (kDebugMode) {
            print('✅ Anúncio carregou após ${(i * 0.5).toStringAsFixed(1)}s');
          }
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      if (!isRewardedAdReady.value || _rewardedAd == null) {
        // #region agent log
        _debugLog('H1', 'ads_service.dart:showRewardedAdForFeature:notReady', 'Anuncio NAO ficou pronto apos espera', {
          'isRewardedAdReady': isRewardedAdReady.value,
          'hasRewardedAd': _rewardedAd != null,
          'lastError': lastError.value,
        });
        // #endregion
        
        final errorMsg = lastError.value.isNotEmpty 
            ? 'Erro: ${lastError.value}'
            : 'Anúncio não disponível. Tente novamente em alguns segundos.';
        
        if (kDebugMode) {
          print('❌ Anúncio não ficou pronto: $errorMsg');
        }
        
        return AdResult.failed(errorMsg);
      }
    }

    try {
      if (kDebugMode) {
        print('📺 Exibindo anúncio recompensado...');
        print('   Feature: ${featureType.name}');
        print('   Duração: ${durationHours}h');
      }
      
      // Mostra o anúncio e aguarda a recompensa
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
          if (kDebugMode) {
            print('🎉 Usuário ganhou recompensa!');
            print('   Tipo: ${reward.type}');
            print('   Quantidade: ${reward.amount}');
          }
          
          // Processa a recompensa
          await _processReward(
            featureType: _currentFeatureType!,
            durationHours: _currentDurationHours,
          );
        },
      );
      
      // Retorna sucesso (a recompensa é processada no callback)
      return AdResult.success(
        rewardAmount: durationHours,
        rewardType: '${featureType.name}_unlock',
      );
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao mostrar anúncio: $e');
      }
      return AdResult.failed('Erro ao exibir anúncio: $e');
    }
  }

  /// Processa a recompensa do anúncio
  Future<FeatureUnlock?> _processReward({
    required FeatureType featureType,
    required int durationHours,
  }) async {
    // #region agent log
    _debugLog('H1', 'ads_service.dart:_processReward:entry', '_processReward CHAMADO', {'featureType': featureType.name, 'durationHours': durationHours});
    // #endregion
    
    try {
      // Rastreia recompensa ganha
      _analyticsService?.trackAdRewardEarned(
        featureType: featureType.name,
        durationHours: durationHours,
        adUnitId: AdConfig.rewardedAdUnitId,
      );
      
      // Obtém o UsageLimitService
      if (!Get.isRegistered<UsageLimitService>()) {
        // #region agent log
        _debugLog('H1', 'ads_service.dart:_processReward:noService', 'UsageLimitService NAO REGISTRADO', {});
        // #endregion
        if (kDebugMode) {
          print('⚠️ UsageLimitService não registrado');
        }
        return null;
      }
      
      final usageLimitService = Get.find<UsageLimitService>();
      // #region agent log
      _debugLog('H1', 'ads_service.dart:_processReward:callingUnlock', 'Chamando unlockFeatureFromAd', {'featureType': featureType.name});
      // #endregion
      
      // Desbloqueia a feature
      final unlock = await usageLimitService.unlockFeatureFromAd(
        featureType: featureType,
        adUnitId: AdConfig.rewardedAdUnitId,
        durationHours: durationHours,
      );
      
      // #region agent log
      _debugLog('H1', 'ads_service.dart:_processReward:unlockResult', 'Resultado do unlockFeatureFromAd', {'unlockNull': unlock == null, 'unlockId': unlock?.id, 'unlockIsActive': unlock?.isActive});
      // #endregion
      
      if (unlock != null) {
        // Rastreia feature desbloqueada
        _analyticsService?.trackFeatureUnlock(
          featureType: featureType.name,
          unlockSource: 'ad',
          durationHours: durationHours,
        );
        
        // Notifica callback se existir
        _onRewardedAdCompleted?.call(unlock);
        
        if (kDebugMode) {
          print('🎉 Recompensa processada com sucesso!');
          print('   Feature: ${featureType.name}');
          print('   Desbloqueado por: ${durationHours}h');
        }
      } else {
        // #region agent log
        _debugLog('H1', 'ads_service.dart:_processReward:unlockNull', 'UNLOCK RETORNOU NULL - falha ao desbloquear', {});
        // #endregion
      }
      
      return unlock;
    } catch (e) {
      // #region agent log
      _debugLog('H1', 'ads_service.dart:_processReward:error', 'ERRO em _processReward', {'error': e.toString()});
      // #endregion
      if (kDebugMode) {
        print('❌ Erro ao processar recompensa: $e');
      }
      return null;
    }
  }

  /// Define callback para quando anúncio recompensado for concluído
  void setRewardedAdCompletedCallback(Function(FeatureUnlock?)? callback) {
    _onRewardedAdCompleted = callback;
  }

  /// Verifica se há anúncio pronto para exibição
  bool get hasRewardedAdReady => isRewardedAdReady.value && _rewardedAd != null;

  /// Pré-carrega anúncios (chamar ao iniciar o app)
  Future<void> preloadAds() async {
    if (kDebugMode) {
      print('🎬 AdsService.preloadAds() chamado');
      print('   isInitialized: ${isInitialized.value}');
      print('   isRewardedAdReady: ${isRewardedAdReady.value}');
    }
    
    if (!isInitialized.value) {
      await _initializeAds();
    } else if (!isRewardedAdReady.value) {
      _loadAttempts = 0; // Reseta contador para permitir novas tentativas
      await _loadRewardedAd();
    }
  }
  
  /// Retorna status detalhado do serviço (para debug)
  Map<String, dynamic> getDebugStatus() {
    // Obtém info do ATT se disponível
    Map<String, dynamic>? attInfo;
    try {
      if (Get.isRegistered<ATTService>()) {
        attInfo = Get.find<ATTService>().getDebugInfo();
      }
    } catch (_) {}
    
    return {
      'isInitialized': isInitialized.value,
      'isRewardedAdReady': isRewardedAdReady.value,
      'isInterstitialAdReady': isInterstitialAdReady.value,
      'isLoadingAd': isLoadingAd.value,
      'isLoadingInterstitial': isLoadingInterstitial.value,
      'loadAttempts': _loadAttempts,
      'interstitialLoadAttempts': _interstitialLoadAttempts,
      'lastError': lastError.value,
      'isUsingTestAds': AdConfig.isUsingTestAds,
      'rewardedAdUnitId': AdConfig.rewardedAdUnitId,
      'interstitialAdUnitId': AdConfig.interstitialAdUnitId,
      'platform': Platform.isIOS ? 'iOS' : (Platform.isAndroid ? 'Android' : 'Unknown'),
      'att': attInfo ?? {'status': 'not_available'},
    };
  }
  
  /// Força recarregar anúncio (para debug ou recuperação de erro)
  Future<void> forceReloadAd() async {
    if (kDebugMode) {
      print('🔄 AdsService.forceReloadAd() chamado');
    }
    
    // Descarta anúncio atual se existir
    _rewardedAd?.dispose();
    _rewardedAd = null;
    isRewardedAdReady.value = false;
    _loadAttempts = 0;
    
    await _loadRewardedAd();
  }
  
  /// Testa carregamento com ID de teste oficial do Google
  /// Use este método para verificar se a integração está correta
  /// Se funcionar com ID de teste mas não com produção = problema de fill/config
  /// Se não funcionar nem com teste = problema de integração
  Future<Map<String, dynamic>> testWithOfficialTestId() async {
    final result = <String, dynamic>{};
    
    print('═══════════════════════════════════════════════════════');
    print('🧪 TESTE COM ID OFICIAL DO GOOGLE');
    print('═══════════════════════════════════════════════════════');
    print('   Plataforma: ${Platform.isIOS ? "iOS" : "Android"}');
    print('   Modo Debug: $kDebugMode');
    print('   ID de Teste: ${AdConfig.testRewardedAdUnitId}');
    print('═══════════════════════════════════════════════════════');
    
    var loadSuccess = false;
    String? loadError;
    int? errorCode;
    
    try {
      await RewardedAd.load(
        adUnitId: AdConfig.testRewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            print('✅ SUCESSO: Anúncio de teste carregou!');
            print('   Response ID: ${ad.responseInfo?.responseId}');
            print('   Mediator: ${ad.responseInfo?.mediationAdapterClassName}');
            loadSuccess = true;
            ad.dispose(); // Descarta após teste
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('❌ FALHA: Anúncio de teste NÃO carregou');
            print('   Código: ${error.code}');
            print('   Mensagem: ${error.message}');
            print('   Domínio: ${error.domain}');
            loadError = error.message;
            errorCode = error.code;
          },
        ),
      );
      
      // Aguarda até 15 segundos pelo callback
      for (var i = 0; i < 30; i++) {
        if (loadSuccess || loadError != null) break;
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
    } catch (e) {
      loadError = e.toString();
      print('❌ EXCEÇÃO: $e');
    }
    
    result['success'] = loadSuccess;
    result['error'] = loadError;
    result['errorCode'] = errorCode;
    
    print('═══════════════════════════════════════════════════════');
    if (loadSuccess) {
      print('📋 RESULTADO: Integração OK!');
      print('   Se anúncios de produção não funcionam, o problema é:');
      print('   • No fill (sem inventário)');
      print('   • Conta AdMob em avaliação');
      print('   • ATT/Consentimento não configurado');
      print('   • app-ads.txt ausente');
    } else {
      print('📋 RESULTADO: Problema de INTEGRAÇÃO!');
      if (errorCode == 0) {
        print('   Código 0: Verifique GADApplicationIdentifier no Info.plist');
      } else if (errorCode == 2) {
        print('   Código 2: Erro de rede - verifique conexão');
      } else if (errorCode == 3) {
        print('   Código 3: No fill - tente novamente em alguns segundos');
      }
    }
    print('═══════════════════════════════════════════════════════');
    
    return result;
  }
  
  /// Imprime status completo para debug
  void printFullStatus() {
    final status = getDebugStatus();
    
    print('═══════════════════════════════════════════════════════');
    print('📊 STATUS COMPLETO DO ADS SERVICE');
    print('═══════════════════════════════════════════════════════');
    status.forEach((key, value) {
      print('   $key: $value');
    });
    print('═══════════════════════════════════════════════════════');
  }

  /// Libera recursos de anúncios
  @override
  void onClose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
    super.onClose();
  }
}

/// Mixin para adicionar funcionalidade de ads a controllers
mixin AdsControllerMixin on GetxController {
  AdsService? _adsService;
  
  AdsService get adsService {
    _adsService ??= Get.find<AdsService>();
    return _adsService!;
  }
  
  /// Mostra anúncio para desbloquear feature
  Future<bool> showAdToUnlockFeature(FeatureType featureType) async {
    final result = await adsService.showRewardedAdForFeature(
      featureType: featureType,
    );
    return result.success;
  }
}
