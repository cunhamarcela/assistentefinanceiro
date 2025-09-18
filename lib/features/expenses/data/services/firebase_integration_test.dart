import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/financial_profile_model.dart';
import '../models/financial_goal_model.dart';
import '../../domain/entities/financial_profile.dart';
import '../../domain/entities/financial_goal.dart';
import '../../../auth/data/services/auth_service.dart';

/// Classe para testar a integração Firebase do sistema de metas
class FirebaseIntegrationTest extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final AuthService _authService;

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
  }

  /// Testar conexão com Firebase
  Future<bool> testFirebaseConnection() async {
    try {
      print('🔥 Testando conexão com Firebase...');
      
      // Teste simples de escrita/leitura
      final testDoc = _firestore.collection('test').doc('connection_test');
      
      await testDoc.set({
        'timestamp': FieldValue.serverTimestamp(),
        'test': true,
      });
      
      final snapshot = await testDoc.get();
      await testDoc.delete();
      
      if (snapshot.exists) {
        print('✅ Conexão Firebase funcionando');
        return true;
      } else {
        print('❌ Erro na conexão Firebase');
        return false;
      }
    } catch (e) {
      print('❌ Erro ao testar Firebase: $e');
      return false;
    }
  }

  /// Testar salvamento de perfil financeiro
  Future<bool> testFinancialProfileSave() async {
    try {
      print('💰 Testando salvamento de perfil financeiro...');
      
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        print('❌ Usuário não autenticado');
        return false;
      }

      // Criar perfil de teste
      final testProfile = FinancialProfile(
        id: 'test_profile_$userId',
        userId: userId,
        monthlyIncome: 5000.0,
        totalBudget: 4000.0,
        categoryBudgets: {
          'alimentacao': 1500.0,
          'transporte': 800.0,
          'entretenimento': 500.0,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final model = FinancialProfileModel.fromEntity(testProfile);
      
      // Salvar no Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('financial_profiles')
          .doc(model.id)
          .set(model.toFirestore());

      // Verificar se foi salvo
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('financial_profiles')
          .doc(model.id)
          .get();

      if (doc.exists) {
        // Limpar teste
        await doc.reference.delete();
        print('✅ Perfil financeiro salvo e recuperado com sucesso');
        return true;
      } else {
        print('❌ Erro ao salvar perfil financeiro');
        return false;
      }
    } catch (e) {
      print('❌ Erro ao testar perfil financeiro: $e');
      return false;
    }
  }

  /// Testar salvamento de metas financeiras
  Future<bool> testFinancialGoalsSave() async {
    try {
      print('🎯 Testando salvamento de metas financeiras...');
      
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        print('❌ Usuário não autenticado');
        return false;
      }

      // Criar meta de teste
      final testGoal = FinancialGoal(
        id: 'test_goal_$userId',
        categoryId: 'alimentacao',
        categoryName: 'Alimentação',
        monthlyLimit: 1500.0,
        currentSpent: 750.0,
        month: DateTime.now(),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final model = FinancialGoalModel.fromEntity(testGoal, userId);
      
      // Salvar no Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('financial_goals')
          .doc(model.id)
          .set(model.toFirestore());

      // Verificar se foi salvo
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('financial_goals')
          .doc(model.id)
          .get();

      if (doc.exists) {
        // Limpar teste
        await doc.reference.delete();
        print('✅ Meta financeira salva e recuperada com sucesso');
        return true;
      } else {
        print('❌ Erro ao salvar meta financeira');
        return false;
      }
    } catch (e) {
      print('❌ Erro ao testar meta financeira: $e');
      return false;
    }
  }

  /// Testar regras de segurança do Firestore
  Future<bool> testFirestoreSecurityRules() async {
    try {
      print('🔒 Testando regras de segurança do Firestore...');
      
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        print('❌ Usuário não autenticado');
        return false;
      }

      // Tentar acessar dados de outro usuário (deve falhar)
      try {
        await _firestore
            .collection('users')
            .doc('fake_user_id')
            .collection('financial_profiles')
            .get();
        
        print('⚠️ Regras de segurança podem estar permissivas demais');
        return false;
      } catch (e) {
        // Esperado - deve dar erro de permissão
        print('✅ Regras de segurança funcionando (acesso negado a outros usuários)');
      }

      // Tentar acessar próprios dados (deve funcionar)
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('financial_profiles')
          .get();
      
      print('✅ Acesso aos próprios dados funcionando');
      return true;
    } catch (e) {
      print('❌ Erro ao testar regras de segurança: $e');
      return false;
    }
  }

  /// Executar todos os testes
  Future<Map<String, bool>> runAllTests() async {
    print('🧪 Iniciando testes de integração Firebase...');
    
    final results = <String, bool>{};
    
    results['firebase_connection'] = await testFirebaseConnection();
    results['financial_profile'] = await testFinancialProfileSave();
    results['financial_goals'] = await testFinancialGoalsSave();
    results['security_rules'] = await testFirestoreSecurityRules();
    
    print('\n📊 Resultados dos testes:');
    results.forEach((test, result) {
      print('${result ? '✅' : '❌'} $test: ${result ? 'PASSOU' : 'FALHOU'}');
    });
    
    final allPassed = results.values.every((result) => result);
    print('\n${allPassed ? '🎉' : '⚠️'} Integração Firebase: ${allPassed ? 'ROBUSTA' : 'PRECISA AJUSTES'}');
    
    return results;
  }

  /// Verificar estrutura de coleções
  Future<void> checkCollectionStructure() async {
    try {
      print('📁 Verificando estrutura de coleções...');
      
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        print('❌ Usuário não autenticado');
        return;
      }

      final userDoc = _firestore.collection('users').doc(userId);
      
      // Verificar subcoleções existentes
      final collections = [
        'expenses',
        'categories', 
        'financial_profiles',
        'financial_goals',
        'reports'
      ];
      
      for (final collection in collections) {
        try {
          final snapshot = await userDoc.collection(collection).limit(1).get();
          print('✅ Coleção $collection: ${snapshot.docs.length} documentos encontrados');
        } catch (e) {
          print('⚠️ Erro ao acessar coleção $collection: $e');
        }
      }
    } catch (e) {
      print('❌ Erro ao verificar estrutura: $e');
    }
  }
}
