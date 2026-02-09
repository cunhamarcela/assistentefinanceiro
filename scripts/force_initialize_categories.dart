#!/usr/bin/env dart

/// Script para forçar a inicialização das categorias padrão
/// Útil quando o usuário tem poucas categorias no banco de dados

import 'dart:io';
import '../lib/features/expenses/data/repositories/expense_hybrid_repository.dart';
import '../lib/features/expenses/data/datasources/expense_local_datasource.dart';
import '../lib/features/expenses/data/datasources/expense_firestore_datasource.dart';
import '../lib/features/auth/data/services/auth_service.dart';

void main() async {
  print('🔧 Forçando inicialização das categorias padrão...');
  
  try {
    // Simular inicialização básica
    print('📱 Inicializando serviços...');
    
    // Criar instâncias dos datasources
    final localDataSource = ExpenseLocalDataSource();
    final firestoreDataSource = ExpenseFirestoreDataSource();
    
    // Criar repositório
    final repository = ExpenseHybridRepository(
      localDataSource: localDataSource,
      firestoreDataSource: firestoreDataSource,
    );
    
    print('🏷️ Forçando recriação das categorias padrão...');
    await repository.forceRecreateDefaultCategories();
    
    print('✅ Categorias padrão inicializadas com sucesso!');
    print('📱 Reinicie o aplicativo para ver as mudanças.');
    
  } catch (e) {
    print('❌ Erro ao inicializar categorias: $e');
    exit(1);
  }
}


