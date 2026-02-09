/// Serviço para gerenciar App Tracking Transparency (ATT) no iOS
/// 
/// O ATT é obrigatório no iOS 14+ para acessar o IDFA (Identifier for Advertisers).
/// Sem o IDFA, o fill rate de anúncios cai drasticamente.
///
/// Tokens utilizados:
/// - Nenhum token de cor (serviço de backend)

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

/// Status do consentimento ATT
enum ATTConsentStatus {
  /// Ainda não foi solicitado
  notDetermined,
  
  /// Usuário autorizou o tracking
  authorized,
  
  /// Usuário negou o tracking
  denied,
  
  /// Tracking restrito pelo sistema (ex: controle parental)
  restricted,
  
  /// Plataforma não suporta ATT (Android)
  notSupported,
}

/// Serviço para gerenciar ATT (App Tracking Transparency)
class ATTService extends GetxService {
  static ATTService get instance => Get.find<ATTService>();
  
  // Estado do consentimento
  final Rx<ATTConsentStatus> consentStatus = ATTConsentStatus.notDetermined.obs;
  final RxBool hasRequestedPermission = false.obs;
  final RxBool isLoading = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _checkCurrentStatus();
  }
  
  /// Verifica o status atual do ATT
  Future<void> _checkCurrentStatus() async {
    if (!Platform.isIOS) {
      consentStatus.value = ATTConsentStatus.notSupported;
      if (kDebugMode) {
        print('📱 ATTService: Plataforma não iOS, ATT não aplicável');
      }
      return;
    }
    
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      consentStatus.value = _mapStatus(status);
      
      if (kDebugMode) {
        print('📱 ATTService: Status atual do ATT: ${consentStatus.value}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ATTService: Erro ao verificar status ATT: $e');
      }
    }
  }
  
  /// Solicita permissão ATT ao usuário
  /// 
  /// IMPORTANTE: Deve ser chamado ANTES de carregar anúncios.
  /// Retorna true se o usuário autorizou, false caso contrário.
  Future<bool> requestTrackingPermission() async {
    if (!Platform.isIOS) {
      if (kDebugMode) {
        print('📱 ATTService: Não é iOS, retornando true');
      }
      return true;
    }
    
    // Já solicitou antes?
    if (hasRequestedPermission.value && 
        consentStatus.value != ATTConsentStatus.notDetermined) {
      if (kDebugMode) {
        print('📱 ATTService: Permissão já foi solicitada: ${consentStatus.value}');
      }
      return consentStatus.value == ATTConsentStatus.authorized;
    }
    
    try {
      isLoading.value = true;
      
      if (kDebugMode) {
        print('📱 ATTService: Solicitando permissão ATT...');
      }
      
      // Solicita permissão
      final status = await AppTrackingTransparency.requestTrackingAuthorization();
      consentStatus.value = _mapStatus(status);
      hasRequestedPermission.value = true;
      
      if (kDebugMode) {
        print('📱 ATTService: Resposta do usuário: ${consentStatus.value}');
      }
      
      return consentStatus.value == ATTConsentStatus.authorized;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ ATTService: Erro ao solicitar ATT: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Retorna se o tracking está autorizado
  bool get isTrackingAuthorized {
    if (!Platform.isIOS) return true;
    return consentStatus.value == ATTConsentStatus.authorized;
  }
  
  /// Retorna se podemos tentar pedir permissão
  bool get canRequestPermission {
    if (!Platform.isIOS) return false;
    return consentStatus.value == ATTConsentStatus.notDetermined;
  }
  
  /// Mapeia o status do SDK para nosso enum
  ATTConsentStatus _mapStatus(TrackingStatus status) {
    switch (status) {
      case TrackingStatus.notDetermined:
        return ATTConsentStatus.notDetermined;
      case TrackingStatus.authorized:
        return ATTConsentStatus.authorized;
      case TrackingStatus.denied:
        return ATTConsentStatus.denied;
      case TrackingStatus.restricted:
        return ATTConsentStatus.restricted;
      default:
        return ATTConsentStatus.notDetermined;
    }
  }
  
  /// Retorna informações de debug
  Map<String, dynamic> getDebugInfo() {
    return {
      'platform': Platform.isIOS ? 'iOS' : 'Android',
      'consentStatus': consentStatus.value.name,
      'hasRequestedPermission': hasRequestedPermission.value,
      'isTrackingAuthorized': isTrackingAuthorized,
      'canRequestPermission': canRequestPermission,
    };
  }
}
