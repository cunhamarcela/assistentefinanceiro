import 'dart:io';

/// Script para verificar a integração Firebase
void main() async {
  print('🔥 Verificando Integração Firebase - Sistema de Metas Financeiras');
  print('=' * 60);
  
  // 1. Verificar arquivos de configuração
  await _checkConfigFiles();
  
  // 2. Verificar dependências
  await _checkDependencies();
  
  // 3. Verificar estrutura de código
  await _checkCodeStructure();
  
  // 4. Verificar regras de segurança
  await _checkSecurityRules();
  
  print('\n✅ Verificação concluída!');
  print('📝 Recomendações:');
  print('1. Execute o app e teste a funcionalidade de metas');
  print('2. Verifique os logs do console para erros Firebase');
  print('3. Teste offline-first (desconecte internet)');
  print('4. Verifique sincronização quando reconectar');
}

Future<void> _checkConfigFiles() async {
  print('\n📁 Verificando arquivos de configuração...');
  
  final files = [
    'firebase.json',
    'firestore.rules',
    'android/app/google-services.json',
    'ios/Runner/GoogleService-Info.plist',
    'lib/firebase_options.dart',
  ];
  
  for (final file in files) {
    final exists = await File(file).exists();
    print('${exists ? '✅' : '❌'} $file');
    
    if (!exists && file == 'firestore.rules') {
      print('   ⚠️  Arquivo de regras criado automaticamente');
    }
  }
}

Future<void> _checkDependencies() async {
  print('\n📦 Verificando dependências...');
  
  final pubspecFile = File('pubspec.yaml');
  if (!await pubspecFile.exists()) {
    print('❌ pubspec.yaml não encontrado');
    return;
  }
  
  final content = await pubspecFile.readAsString();
  final requiredDeps = [
    'firebase_core',
    'cloud_firestore',
    'firebase_auth',
    'get',
    'sqflite',
  ];
  
  for (final dep in requiredDeps) {
    final hasDepRegex = RegExp(r'^\s*' + dep + r':', multiLine: true);
    final hasDep = hasDepRegex.hasMatch(content);
    print('${hasDep ? '✅' : '❌'} $dep');
  }
}

Future<void> _checkCodeStructure() async {
  print('\n🏗️  Verificando estrutura de código...');
  
  final criticalFiles = [
    'lib/features/expenses/domain/entities/financial_profile.dart',
    'lib/features/expenses/domain/entities/financial_goal.dart',
    'lib/features/expenses/domain/entities/financial_insight.dart',
    'lib/features/expenses/data/models/financial_profile_model.dart',
    'lib/features/expenses/data/models/financial_goal_model.dart',
    'lib/features/expenses/data/services/financial_profile_service.dart',
    'lib/features/expenses/data/services/financial_insights_service.dart',
    'lib/features/expenses/presentation/pages/financial_goals_page.dart',
    'lib/features/expenses/presentation/pages/enhanced_reports_page.dart',
    'lib/features/expenses/presentation/controllers/financial_goals_controller.dart',
    'lib/features/expenses/presentation/controllers/enhanced_reports_controller.dart',
  ];
  
  for (final file in criticalFiles) {
    final exists = await File(file).exists();
    print('${exists ? '✅' : '❌'} $file');
  }
}

Future<void> _checkSecurityRules() async {
  print('\n🔒 Verificando regras de segurança...');
  
  final rulesFile = File('firestore.rules');
  if (!await rulesFile.exists()) {
    print('❌ firestore.rules não encontrado');
    return;
  }
  
  final content = await rulesFile.readAsString();
  final requiredRules = [
    'financial_profiles',
    'financial_goals',
    'request.auth.uid == userId',
  ];
  
  for (final rule in requiredRules) {
    final hasRule = content.contains(rule);
    print('${hasRule ? '✅' : '❌'} Regra para $rule');
  }
  
  print('\n📋 Comandos para aplicar regras:');
  print('firebase deploy --only firestore:rules');
}
