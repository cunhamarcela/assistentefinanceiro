import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../lib/features/expenses/domain/entities/financial_goal.dart';
import '../lib/features/expenses/domain/entities/financial_profile.dart';
import '../lib/features/expenses/domain/repositories/financial_goals_repository.dart';
import '../lib/features/expenses/data/repositories/financial_goals_repository_impl.dart';
import '../lib/features/expenses/presentation/controllers/financial_goals_controller.dart';
import '../lib/features/auth/data/services/auth_service.dart';

/// Script para testar a persistência das metas financeiras
class FinancialGoalsTest {
  static Future<void> runTests() async {
    print('🧪 ==================== TESTE DE METAS FINANCEIRAS ====================');
    
    try {
      // Verificar se o usuário está autenticado
      final authService = Get.find<AuthService>();
      final currentUser = authService.currentUser;
      
      if (currentUser == null) {
        print('❌ Usuário não autenticado. Faça login primeiro.');
        return;
      }
      
      print('✅ Usuário autenticado: ${currentUser.email}');
      print('📱 ID do usuário: ${currentUser.id}');
      
      // Teste 1: Verificar se o repositório está registrado
      await _testRepositoryRegistration();
      
      // Teste 2: Criar metas de exemplo
      await _testCreateGoals();
      
      // Teste 3: Buscar metas salvas
      await _testLoadGoals();
      
      // Teste 4: Testar controller
      await _testController();
      
      // Teste 5: Testar persistência híbrida
      await _testHybridPersistence();
      
      print('🎉 ==================== TODOS OS TESTES CONCLUÍDOS ====================');
      
    } catch (e, stackTrace) {
      print('❌ Erro durante os testes: $e');
      if (kDebugMode) {
        print('Stack trace: $stackTrace');
      }
    }
  }
  
  static Future<void> _testRepositoryRegistration() async {
    print('\n📋 Teste 1: Verificação do Repositório');
    
    try {
      final repository = Get.find<FinancialGoalsRepository>();
      print('✅ Repositório registrado: ${repository.runtimeType}');
    } catch (e) {
      print('❌ Repositório não encontrado: $e');
      throw Exception('Repositório não registrado');
    }
  }
  
  static Future<void> _testCreateGoals() async {
    print('\n💾 Teste 2: Criação de Metas');
    
    try {
      final repository = Get.find<FinancialGoalsRepository>();
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);
      
      // Criar metas de exemplo
      final testGoals = [
        FinancialGoal(
          id: 'test_goal_1_${now.millisecondsSinceEpoch}',
          categoryId: 'alimentacao',
          categoryName: 'Alimentação',
          monthlyLimit: 800.0,
          currentSpent: 0.0,
          month: currentMonth,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
        FinancialGoal(
          id: 'test_goal_2_${now.millisecondsSinceEpoch}',
          categoryId: 'transporte',
          categoryName: 'Transporte',
          monthlyLimit: 400.0,
          currentSpent: 0.0,
          month: currentMonth,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];
      
      await repository.saveGoals(testGoals);
      print('✅ ${testGoals.length} metas criadas com sucesso');
      
      // Verificar se foram salvas
      final savedGoals = await repository.getGoalsByMonth(currentMonth);
      print('✅ ${savedGoals.length} metas encontradas após salvamento');
      
    } catch (e) {
      print('❌ Erro ao criar metas: $e');
      throw e;
    }
  }
  
  static Future<void> _testLoadGoals() async {
    print('\n📖 Teste 3: Carregamento de Metas');
    
    try {
      final repository = Get.find<FinancialGoalsRepository>();
      final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
      
      final goals = await repository.getGoalsByMonth(currentMonth);
      
      print('✅ ${goals.length} metas carregadas para ${currentMonth.month}/${currentMonth.year}');
      
      for (final goal in goals) {
        print('  📊 ${goal.categoryName}: R\$ ${goal.monthlyLimit.toStringAsFixed(2)} (${goal.progressPercentage * 100}% gasto)');
      }
      
      // Testar busca por categoria específica
      if (goals.isNotEmpty) {
        final firstGoal = goals.first;
        final goalByCategory = await repository.getGoalByCategoryAndMonth(
          firstGoal.categoryId, 
          currentMonth
        );
        
        if (goalByCategory != null) {
          print('✅ Meta encontrada por categoria: ${goalByCategory.categoryName}');
        } else {
          print('⚠️ Meta não encontrada por categoria');
        }
      }
      
    } catch (e) {
      print('❌ Erro ao carregar metas: $e');
      throw e;
    }
  }
  
  static Future<void> _testController() async {
    print('\n🎮 Teste 4: Controller de Metas');
    
    try {
      final controller = Get.find<FinancialGoalsController>();
      
      // Testar carregamento de metas
      final goals = await controller.loadCurrentMonthGoals();
      print('✅ Controller carregou ${goals.length} metas');
      
      // Testar resumo das metas
      final summary = controller.getGoalsSummary(goals);
      print('✅ Resumo das metas:');
      print('  💰 Orçamento total: R\$ ${summary['totalBudget'].toStringAsFixed(2)}');
      print('  💸 Total gasto: R\$ ${summary['totalSpent'].toStringAsFixed(2)}');
      print('  💵 Restante: R\$ ${summary['totalRemaining'].toStringAsFixed(2)}');
      print('  📈 Progresso: ${(summary['progressPercentage'] * 100).toStringAsFixed(1)}%');
      print('  🚨 Metas excedidas: ${summary['exceededGoals']}');
      
      // Testar verificação de metas existentes
      final hasGoals = await controller.hasCurrentMonthGoals();
      print('✅ Tem metas no mês atual: $hasGoals');
      
    } catch (e) {
      print('❌ Erro ao testar controller: $e');
      throw e;
    }
  }
  
  static Future<void> _testHybridPersistence() async {
    print('\n🔄 Teste 5: Persistência Híbrida');
    
    try {
      final repository = Get.find<FinancialGoalsRepository>();
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);
      
      // Criar uma meta e atualizar valor gasto
      final testGoal = FinancialGoal(
        id: 'test_hybrid_${now.millisecondsSinceEpoch}',
        categoryId: 'lazer',
        categoryName: 'Lazer',
        monthlyLimit: 300.0,
        currentSpent: 0.0,
        month: currentMonth,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      
      await repository.saveGoal(testGoal);
      print('✅ Meta de teste criada');
      
      // Atualizar valor gasto
      await repository.updateGoalSpentAmount('lazer', currentMonth, 150.0);
      print('✅ Valor gasto atualizado');
      
      // Verificar se a atualização foi persistida
      final updatedGoal = await repository.getGoalByCategoryAndMonth('lazer', currentMonth);
      if (updatedGoal != null) {
        print('✅ Meta atualizada encontrada:');
        print('  💰 Limite: R\$ ${updatedGoal.monthlyLimit.toStringAsFixed(2)}');
        print('  💸 Gasto: R\$ ${updatedGoal.currentSpent.toStringAsFixed(2)}');
        print('  📊 Progresso: ${(updatedGoal.progressPercentage * 100).toStringAsFixed(1)}%');
        print('  🎯 Status: ${updatedGoal.status.displayName}');
      } else {
        print('❌ Meta atualizada não encontrada');
      }
      
      // Testar criação de metas a partir do perfil
      final categoryBudgets = {
        'alimentacao': 1000.0,
        'transporte': 500.0,
        'lazer': 300.0,
        'contas': 800.0,
      };
      
      final goalsFromProfile = await repository.createGoalsFromProfile(categoryBudgets, currentMonth);
      print('✅ ${goalsFromProfile.length} metas criadas a partir do perfil');
      
    } catch (e) {
      print('❌ Erro no teste de persistência híbrida: $e');
      throw e;
    }
  }
}

/// Função principal para executar os testes
void main() async {
  print('🚀 Iniciando testes de metas financeiras...');
  
  // Aguardar um pouco para garantir que o app esteja inicializado
  await Future.delayed(const Duration(seconds: 2));
  
  await FinancialGoalsTest.runTests();
}

