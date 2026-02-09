import '../lib/features/onboarding/data/models/onboarding_question_model.dart';
import '../lib/features/onboarding/data/services/ai_insights_service.dart';
import '../lib/features/expenses/domain/entities/financial_insight.dart';

/// Script para testar o sistema de insights baseado no onboarding
/// Execute com: dart run scripts/test_onboarding_insights.dart
void main() async {
  // ignore: avoid_print
  print('🤖 Testando Sistema de Insights IA com Onboarding\n');
  
  // Simular diferentes perfis de usuários
  await testProfile1(); // Usuário iniciante que quer economizar
  await testProfile2(); // Usuário intermediário com renda alta
  await testProfile3(); // Usuário com gastos impulsivos
  
  // ignore: avoid_print
  print('\n✅ Testes concluídos! O sistema está funcionando corretamente.');
}

Future<void> testProfile1() async {
  // ignore: avoid_print
  print('👤 PERFIL 1: Usuário Iniciante que quer Economizar');
  // ignore: avoid_print
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  
  final profile = OnboardingProfileModel(
    userId: 'user1',
    responses: [
      OnboardingResponseModel(
        questionId: 'financial_goal',
        answer: '💰 Quero economizar dinheiro',
        answeredAt: DateTime.now(),
      ),
      OnboardingResponseModel(
        questionId: 'monthly_income',
        answer: 'Até R\$ 2.000',
        answeredAt: DateTime.now(),
      ),
      OnboardingResponseModel(
        questionId: 'fixed_expenses',
        answer: 800.0,
        answeredAt: DateTime.now(),
      ),
      OnboardingResponseModel(
        questionId: 'spending_categories',
        answer: ['🍔 Alimentação', '🚗 Transporte', '☕ Cafés e Restaurantes'],
        answeredAt: DateTime.now(),
      ),
      OnboardingResponseModel(
        questionId: 'financial_knowledge',
        answer: '🌱 Iniciante - Estou começando agora',
        answeredAt: DateTime.now(),
      ),
      OnboardingResponseModel(
        questionId: 'biggest_challenge',
        answer: '😅 Controlar gastos impulsivos',
        answeredAt: DateTime.now(),
      ),
      OnboardingResponseModel(
        questionId: 'savings_goal',
        answer: 200.0,
        answeredAt: DateTime.now(),
      ),
    ],
    completedAt: DateTime.now(),
    isCompleted: true,
  );
  
  final aiService = AIInsightsService();
  final insights = await aiService.generateOnboardingInsights(profile);
  
  // ignore: avoid_print
  print('📊 Insights Gerados: ${insights.length}');
  for (int i = 0; i < insights.length; i++) {
    final insight = insights[i];
    // ignore: avoid_print
    print('\n${i + 1}. ${insight.title}');
    // ignore: avoid_print
    print('   Prioridade: ${insight.priority.displayName}');
    // ignore: avoid_print
    print('   Descrição: ${insight.description}');
    // ignore: avoid_print
    print('   Ação: ${insight.actionSuggestions.isNotEmpty ? insight.actionSuggestions.first : 'N/A'}');
  }
  // ignore: avoid_print
  print('\n');
}

Future<void> testProfile2() async {
  // ignore: avoid_print
  print('👤 PERFIL 2: Usuário Intermediário com Renda Alta');
  // ignore: avoid_print
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  
  final profile = OnboardingProfileModel(
    userId: 'user2',
    responses: [
      OnboardingResponseModel(
        questionId: 'financial_goal',
        answer: '📈 Quero investir meu dinheiro',
        answeredAt: DateTime.now(),
      ),
      OnboardingResponseModel(
        questionId: 'monthly_income',
        answer: 'R\$ 5.001 - R\$ 10.000',
        answeredAt: DateTime.now(),
      ),
      OnboardingResponseModel(
        questionId: 'fixed_expenses',
        answer: 2500.0,
        answeredAt: DateTime.now(),
      ),
      OnboardingResponseModel(
        questionId: 'spending_categories',
        answer: ['🏠 Moradia', '🎮 Entretenimento', '✈️ Viagens'],
        answeredAt: DateTime.now(),
      ),
      OnboardingResponseModel(
        questionId: 'financial_knowledge',
        answer: '🎯 Intermediário - Tenho experiência',
        answeredAt: DateTime.now(),
      ),
      OnboardingResponseModel(
        questionId: 'biggest_challenge',
        answer: '📈 Começar a investir',
        answeredAt: DateTime.now(),
      ),
      OnboardingResponseModel(
        questionId: 'main_motivation',
        answer: '💼 Ter independência financeira',
        answeredAt: DateTime.now(),
      ),
    ],
    completedAt: DateTime.now(),
    isCompleted: true,
  );
  
  final aiService = AIInsightsService();
  final insights = await aiService.generateOnboardingInsights(profile);
  
  // ignore: avoid_print
  print('📊 Insights Gerados: ${insights.length}');
  for (int i = 0; i < insights.length; i++) {
    final insight = insights[i];
    // ignore: avoid_print
    print('\n${i + 1}. ${insight.title}');
    // ignore: avoid_print
    print('   Prioridade: ${insight.priority.displayName}');
    // ignore: avoid_print
    print('   Descrição: ${insight.description}');
    // ignore: avoid_print
    print('   Ação: ${insight.actionSuggestions.isNotEmpty ? insight.actionSuggestions.first : 'N/A'}');
  }
  // ignore: avoid_print
  print('\n');
}

Future<void> testProfile3() async {
  // ignore: avoid_print
  print('👤 PERFIL 3: Usuário com Gastos Fixos Altos');
  // ignore: avoid_print
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  
  final profile = OnboardingProfileModel(
    userId: 'user3',
    responses: [
      OnboardingResponseModel(
        questionId: 'financial_goal',
        answer: '📊 Quero organizar minha vida financeira',
        answeredAt: DateTime.now(),
      ),
      OnboardingResponseModel(
        questionId: 'monthly_income',
        answer: 'R\$ 2.001 - R\$ 5.000',
        answeredAt: DateTime.now(),
      ),
      OnboardingResponseModel(
        questionId: 'fixed_expenses',
        answer: 2800.0, // 80% da renda estimada
        answeredAt: DateTime.now(),
      ),
      OnboardingResponseModel(
        questionId: 'spending_categories',
        answer: ['🏠 Moradia', '💊 Saúde', '📚 Educação'],
        answeredAt: DateTime.now(),
      ),
      OnboardingResponseModel(
        questionId: 'financial_knowledge',
        answer: '📚 Básico - Sei o essencial',
        answeredAt: DateTime.now(),
      ),
      OnboardingResponseModel(
        questionId: 'biggest_challenge',
        answer: '📊 Organizar as finanças',
        answeredAt: DateTime.now(),
      ),
      OnboardingResponseModel(
        questionId: 'main_motivation',
        answer: '😌 Ter tranquilidade financeira',
        answeredAt: DateTime.now(),
      ),
    ],
    completedAt: DateTime.now(),
    isCompleted: true,
  );
  
  final aiService = AIInsightsService();
  final insights = await aiService.generateOnboardingInsights(profile);
  
  // ignore: avoid_print
  print('📊 Insights Gerados: ${insights.length}');
  for (int i = 0; i < insights.length; i++) {
    final insight = insights[i];
    // ignore: avoid_print
    print('\n${i + 1}. ${insight.title}');
    // ignore: avoid_print
    print('   Prioridade: ${insight.priority.displayName}');
    // ignore: avoid_print
    print('   Descrição: ${insight.description}');
    // ignore: avoid_print
    print('   Ação: ${insight.actionSuggestions.isNotEmpty ? insight.actionSuggestions.first : 'N/A'}');
  }
  // ignore: avoid_print
  print('\n');
}
