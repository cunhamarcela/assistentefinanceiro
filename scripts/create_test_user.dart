#!/usr/bin/env dart

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

/// Script para criar usuário de teste no Firebase
/// 
/// Execute com: dart run scripts/create_test_user.dart
void main() async {
  print('🔥 Criando usuário de teste...\n');
  
  try {
    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    final auth = FirebaseAuth.instance;
    
    // Dados do usuário de teste
    const testEmail = 'teste@assistentefinanceiro.com';
    const testPassword = 'TesteApp2024!';
    const testName = 'Usuário Teste';
    
    print('📧 Email: $testEmail');
    print('🔐 Senha: $testPassword');
    print('👤 Nome: $testName\n');
    
    // Verificar se usuário já existe
    try {
      final existingUser = await auth.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
      
      if (existingUser.user != null) {
        print('✅ Usuário de teste já existe e está funcional!');
        print('📱 Você pode fazer login com as credenciais acima.\n');
        await auth.signOut();
        return;
      }
    } catch (e) {
      // Usuário não existe, vamos criar
      print('👤 Usuário não existe, criando...\n');
    }
    
    // Criar novo usuário
    final userCredential = await auth.createUserWithEmailAndPassword(
      email: testEmail,
      password: testPassword,
    );
    
    if (userCredential.user != null) {
      // Atualizar nome do usuário
      await userCredential.user!.updateDisplayName(testName);
      await userCredential.user!.reload();
      
      print('✅ Usuário de teste criado com sucesso!');
      print('🎉 Dados salvos no Firebase Authentication');
      print('📱 Você pode fazer login no app com as credenciais acima.\n');
      
      // Fazer logout para não interferir com o app
      await auth.signOut();
      
      print('📋 RESUMO:');
      print('Email: $testEmail');
      print('Senha: $testPassword');
      print('Nome: $testName');
      print('\n🚀 Agora você pode abrir o app e fazer login!');
      
    } else {
      print('❌ Erro: Não foi possível criar o usuário');
    }
    
  } catch (e) {
    print('❌ Erro ao criar usuário de teste: $e');
    print('\n💡 Dicas:');
    print('1. Verifique se o Firebase está configurado corretamente');
    print('2. Certifique-se de que o app está conectado à internet');
    print('3. Verifique se as regras do Firestore permitem criação de usuários');
  }
}
