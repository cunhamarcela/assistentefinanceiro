#!/usr/bin/env dart
// Script para verificar configuração de anúncios AdMob

import 'dart:io';

void main() {
  print('🔍 Verificando configuração de anúncios AdMob...\n');
  
  var allOk = true;
  
  // Verificar pubspec.yaml
  print('📦 Verificando pubspec.yaml...');
  final pubspec = File('pubspec.yaml').readAsStringSync();
  if (pubspec.contains('google_mobile_ads:')) {
    print('  ✅ google_mobile_ads está instalado');
  } else {
    print('  ❌ google_mobile_ads NÃO está instalado');
    allOk = false;
  }
  
  // Verificar ads_service.dart
  print('\n📱 Verificando ads_service.dart...');
  final adsService = File('lib/core/services/ads_service.dart').readAsStringSync();
  
  // Verificar iOS Ad Unit ID
  if (adsService.contains('ca-app-pub-6286381265499018/7433719494')) {
    print('  ✅ iOS Rewarded Ad Unit ID configurado');
  } else {
    print('  ⚠️  iOS Ad Unit ID não encontrado ou diferente');
  }
  
  // Verificar Android Ad Unit ID
  if (adsService.contains('ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY')) {
    print('  ❌ Android Ad Unit ID ainda é PLACEHOLDER');
    print('     Você precisa substituir por um ID real do AdMob!');
    allOk = false;
  } else if (adsService.contains(RegExp(r'ca-app-pub-6286381265499018/\d{10}'))) {
    print('  ✅ Android Rewarded Ad Unit ID configurado');
  } else {
    print('  ⚠️  Android Ad Unit ID parece incorreto');
  }
  
  // Verificar AndroidManifest.xml
  print('\n🤖 Verificando AndroidManifest.xml...');
  final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
  
  if (manifest.contains('ca-app-pub-3940256099942544~3347511713')) {
    print('  ❌ USANDO ID DE TESTE DO GOOGLE!');
    print('     Isso NÃO gera receita. Substitua pelo App ID de produção.');
    allOk = false;
  } else if (manifest.contains('ca-app-pub-6286381265499018~')) {
    print('  ✅ App ID de produção configurado');
  } else {
    print('  ⚠️  App ID não encontrado ou diferente');
  }
  
  // Verificar Info.plist
  print('\n🍎 Verificando Info.plist...');
  final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
  
  if (infoPlist.contains('ca-app-pub-6286381265499018~1604993535')) {
    print('  ✅ iOS App ID configurado');
  } else {
    print('  ⚠️  iOS App ID não encontrado ou diferente');
  }
  
  if (infoPlist.contains('NSUserTrackingUsageDescription')) {
    print('  ✅ NSUserTrackingUsageDescription configurado');
  } else {
    print('  ❌ NSUserTrackingUsageDescription faltando (necessário para iOS 14+)');
    allOk = false;
  }
  
  if (infoPlist.contains('SKAdNetworkItems')) {
    print('  ✅ SKAdNetworkItems configurado');
  } else {
    print('  ❌ SKAdNetworkItems faltando');
    allOk = false;
  }
  
  // Verificar app-ads.txt
  print('\n📄 Verificando app-ads.txt...');
  final appAdsTxt = File('web/app-ads.txt');
  if (appAdsTxt.existsSync()) {
    final content = appAdsTxt.readAsStringSync();
    if (content.contains('pub-6286381265499018')) {
      print('  ✅ app-ads.txt configurado com Publisher ID correto');
    } else {
      print('  ⚠️  app-ads.txt existe mas Publisher ID parece incorreto');
    }
  } else {
    print('  ⚠️  app-ads.txt não encontrado (recomendado para web)');
  }
  
  // Verificar inicialização no main.dart
  print('\n🚀 Verificando main.dart...');
  final mainFile = File('lib/main.dart').readAsStringSync();
  
  if (mainFile.contains('AdsService')) {
    print('  ✅ AdsService importado');
  } else {
    print('  ❌ AdsService não importado');
    allOk = false;
  }
  
  if (mainFile.contains('Get.put<AdsService>')) {
    print('  ✅ AdsService registrado no GetX');
  } else {
    print('  ❌ AdsService não registrado no GetX');
    allOk = false;
  }
  
  // Resultado final
  print('\n' + '=' * 60);
  if (allOk) {
    print('✅ CONFIGURAÇÃO COMPLETA!');
    print('   Os anúncios devem funcionar em produção.');
  } else {
    print('❌ CONFIGURAÇÃO INCOMPLETA!');
    print('   Corrija os problemas listados acima.');
    print('\n📋 Consulte: CHECKLIST_ANUNCIOS_ADMOB.md');
  }
  print('=' * 60);
  
  exit(allOk ? 0 : 1);
}



