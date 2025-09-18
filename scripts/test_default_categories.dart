#!/usr/bin/env dart

/// Script para testar a inicialização das categorias padrão
/// 
/// Este script verifica se as categorias padrão estão sendo criadas corretamente
/// quando um usuário se registra no sistema.

import 'dart:io';
import '../lib/features/expenses/domain/entities/category.dart';

void main() {
  print('🧪 Testando sistema de categorias padrão...\n');
  
  // Testar se as categorias padrão estão definidas
  testDefaultCategoriesDefinition();
  
  // Testar estrutura das categorias
  testCategoryStructure();
  
  // Testar palavras-chave
  testCategoryKeywords();
  
  print('\n✅ Todos os testes passaram!');
  print('📋 Sistema de categorias padrão está funcionando corretamente.');
  print('\n💡 Para testar no app:');
  print('   1. Crie um novo usuário');
  print('   2. Faça login');
  print('   3. Vá para "Nova Despesa"');
  print('   4. Verifique se as categorias aparecem automaticamente');
}

void testDefaultCategoriesDefinition() {
  print('🔍 Testando definição das categorias padrão...');
  
  final categories = ExpenseCategory.defaultCategories;
  
  if (categories.isEmpty) {
    print('❌ ERRO: Nenhuma categoria padrão definida!');
    exit(1);
  }
  
  print('✅ ${categories.length} categorias padrão definidas');
  
  // Verificar se todas as categorias essenciais estão presentes
  final essentialCategories = [
    'alimentacao',
    'transporte', 
    'saude',
    'contas',
    'lazer',
    'casa',
    'educacao',
    'outros'
  ];
  
  for (final essential in essentialCategories) {
    final found = categories.any((cat) => cat.id == essential);
    if (!found) {
      print('❌ ERRO: Categoria essencial "$essential" não encontrada!');
      exit(1);
    }
  }
  
  print('✅ Todas as categorias essenciais estão presentes');
}

void testCategoryStructure() {
  print('\n🔍 Testando estrutura das categorias...');
  
  final categories = ExpenseCategory.defaultCategories;
  
  for (final category in categories) {
    // Verificar ID
    if (category.id.isEmpty) {
      print('❌ ERRO: Categoria sem ID: ${category.name}');
      exit(1);
    }
    
    // Verificar nome
    if (category.name.isEmpty) {
      print('❌ ERRO: Categoria sem nome: ${category.id}');
      exit(1);
    }
    
    // Verificar ícone
    if (category.icon.isEmpty) {
      print('❌ ERRO: Categoria sem ícone: ${category.name}');
      exit(1);
    }
    
    // Verificar se é padrão
    if (!category.isDefault) {
      print('❌ ERRO: Categoria não marcada como padrão: ${category.name}');
      exit(1);
    }
    
    print('✅ ${category.name} - estrutura válida');
  }
}

void testCategoryKeywords() {
  print('\n🔍 Testando palavras-chave das categorias...');
  
  final categories = ExpenseCategory.defaultCategories;
  
  for (final category in categories) {
    if (category.id != 'outros' && category.keywords.isEmpty) {
      print('⚠️  AVISO: Categoria "${category.name}" sem palavras-chave');
    } else if (category.keywords.isNotEmpty) {
      print('✅ ${category.name} - ${category.keywords.length} palavras-chave');
    }
  }
}
