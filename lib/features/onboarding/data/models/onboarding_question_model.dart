enum QuestionType {
  singleChoice,
  multipleChoice,
  slider,
  currency,
  text,
}

enum OnboardingFinancialGoal {
  save('economizar', 'Quero economizar dinheiro', '💰'),
  invest('investir', 'Quero investir meu dinheiro', '📈'),
  organize('organizar', 'Quero organizar minha vida financeira', '📊'),
  track('rastrear', 'Quero saber onde mais gasto', '🔍'),
  budget('orcamento', 'Quero criar um orçamento', '📝'),
  debt('divida', 'Quero quitar minhas dívidas', '💳');

  const OnboardingFinancialGoal(this.id, this.title, this.emoji);
  final String id;
  final String title;
  final String emoji;
}

enum IncomeRange {
  low('ate_2k', 'Até R\$ 2.000', 0, 2000),
  medium('2k_5k', 'R\$ 2.001 - R\$ 5.000', 2001, 5000),
  high('5k_10k', 'R\$ 5.001 - R\$ 10.000', 5001, 10000),
  veryHigh('acima_10k', 'Acima de R\$ 10.000', 10001, 50000);

  const IncomeRange(this.id, this.title, this.min, this.max);
  final String id;
  final String title;
  final double min;
  final double max;
}

enum FinancialKnowledge {
  beginner('iniciante', 'Iniciante - Estou começando agora', '🌱'),
  basic('basico', 'Básico - Sei o essencial', '📚'),
  intermediate('intermediario', 'Intermediário - Tenho experiência', '🎯'),
  advanced('avancado', 'Avançado - Sou experiente', '🚀');

  const FinancialKnowledge(this.id, this.title, this.emoji);
  final String id;
  final String title;
  final String emoji;
}

class OnboardingQuestionModel {
  final String id;
  final String title;
  final String subtitle;
  final QuestionType type;
  final List<String> options;
  final String? placeholder;
  final double? minValue;
  final double? maxValue;
  final bool isRequired;
  final String? validationMessage;

  const OnboardingQuestionModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.options = const [],
    this.placeholder,
    this.minValue,
    this.maxValue,
    this.isRequired = true,
    this.validationMessage,
  });

  static List<OnboardingQuestionModel> get questions => [
    // Pergunta 1: Objetivo principal
    OnboardingQuestionModel(
      id: 'financial_goal',
      title: 'Qual é seu principal objetivo financeiro? 🎯',
      subtitle: 'Escolha o que mais te motiva a usar este app',
      type: QuestionType.singleChoice,
      options: OnboardingFinancialGoal.values.map((goal) => '${goal.emoji} ${goal.title}').toList(),
    ),

    // Pergunta 2: Renda mensal
    OnboardingQuestionModel(
      id: 'monthly_income',
      title: 'Qual sua renda mensal aproximada? 💵',
      subtitle: 'Isso nos ajuda a dar dicas mais personalizadas',
      type: QuestionType.singleChoice,
      options: IncomeRange.values.map((range) => range.title).toList(),
    ),

    // Pergunta 3: Gastos fixos
    OnboardingQuestionModel(
      id: 'fixed_expenses',
      title: 'Quanto você gasta com contas fixas? 🏠',
      subtitle: 'Aluguel, financiamentos, planos, etc.',
      type: QuestionType.currency,
      placeholder: 'R\$ 0,00',
      validationMessage: 'Digite um valor válido',
    ),

    // Pergunta 4: Categorias de maior gasto
    OnboardingQuestionModel(
      id: 'spending_categories',
      title: 'Onde você mais gasta dinheiro? 🛒',
      subtitle: 'Escolha até 3 categorias (pode escolher várias)',
      type: QuestionType.multipleChoice,
      options: [
        '🍔 Alimentação',
        '🚗 Transporte',
        '🏠 Moradia',
        '👕 Roupas e Acessórios',
        '🎮 Entretenimento',
        '💊 Saúde',
        '📚 Educação',
        '✈️ Viagens',
        '🛍️ Compras Online',
        '☕ Cafés e Restaurantes',
      ],
    ),

    // Pergunta 5: Frequência de gastos
    OnboardingQuestionModel(
      id: 'spending_frequency',
      title: 'Com que frequência você gasta dinheiro? ⏰',
      subtitle: 'Seja honesto, isso nos ajuda a te alertar melhor',
      type: QuestionType.singleChoice,
      options: [
        '📱 Várias vezes por dia',
        '☀️ Uma vez por dia',
        '📅 Algumas vezes por semana',
        '🗓️ Uma vez por semana',
        '📆 Algumas vezes por mês',
      ],
    ),

    // Pergunta 6: Conhecimento financeiro
    OnboardingQuestionModel(
      id: 'financial_knowledge',
      title: 'Como você avalia seu conhecimento financeiro? 🧠',
      subtitle: 'Vamos ajustar as dicas para seu nível',
      type: QuestionType.singleChoice,
      options: FinancialKnowledge.values.map((level) => '${level.emoji} ${level.title}').toList(),
    ),

    // Pergunta 7: Valor que gostaria de economizar
    OnboardingQuestionModel(
      id: 'savings_goal',
      title: 'Quanto você gostaria de economizar por mês? 💎',
      subtitle: 'Defina uma meta realista para começar',
      type: QuestionType.currency,
      placeholder: 'R\$ 0,00',
      validationMessage: 'Digite um valor válido',
    ),

    // Pergunta 8: Maior desafio financeiro
    OnboardingQuestionModel(
      id: 'biggest_challenge',
      title: 'Qual seu maior desafio financeiro? 🤔',
      subtitle: 'Vamos focar em te ajudar com isso',
      type: QuestionType.singleChoice,
      options: [
        '😅 Controlar gastos impulsivos',
        '📊 Organizar as finanças',
        '💰 Conseguir economizar',
        '📈 Começar a investir',
        '💳 Quitar dívidas',
        '🎯 Definir metas financeiras',
        '📱 Acompanhar os gastos',
      ],
    ),

    // Pergunta 9: Motivação principal
    OnboardingQuestionModel(
      id: 'main_motivation',
      title: 'O que mais te motiva a cuidar do dinheiro? ✨',
      subtitle: 'Vamos usar isso para te manter engajado',
      type: QuestionType.singleChoice,
      options: [
        '🏠 Comprar a casa própria',
        '✈️ Viajar mais',
        '🎓 Investir em educação',
        '👨‍👩‍👧‍👦 Cuidar da família',
        '🚗 Comprar um carro',
        '💼 Ter independência financeira',
        '🎯 Realizar sonhos pessoais',
        '😌 Ter tranquilidade financeira',
      ],
    ),
  ];
}

class OnboardingResponseModel {
  final String questionId;
  final dynamic answer;
  final DateTime answeredAt;

  OnboardingResponseModel({
    required this.questionId,
    required this.answer,
    required this.answeredAt,
  });

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'answer': answer,
    'answeredAt': answeredAt.toIso8601String(),
  };

  factory OnboardingResponseModel.fromJson(Map<String, dynamic> json) => OnboardingResponseModel(
    questionId: json['questionId'],
    answer: json['answer'],
    answeredAt: DateTime.parse(json['answeredAt']),
  );
}

class OnboardingProfileModel {
  final String userId;
  final List<OnboardingResponseModel> responses;
  final DateTime completedAt;
  final bool isCompleted;

  OnboardingProfileModel({
    required this.userId,
    required this.responses,
    required this.completedAt,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'responses': responses.map((r) => r.toJson()).toList(),
    'completedAt': completedAt.toIso8601String(),
    'isCompleted': isCompleted,
  };

  factory OnboardingProfileModel.fromJson(Map<String, dynamic> json) => OnboardingProfileModel(
    userId: json['userId'],
    responses: (json['responses'] as List)
        .map((r) => OnboardingResponseModel.fromJson(r))
        .toList(),
    completedAt: DateTime.parse(json['completedAt']),
    isCompleted: json['isCompleted'] ?? false,
  );

  // Métodos de conveniência para acessar respostas específicas
  String? getGoal() {
    final response = responses.firstWhere((r) => r.questionId == 'financial_goal', orElse: () => OnboardingResponseModel(questionId: '', answer: null, answeredAt: DateTime.now()));
    return response.answer?.toString();
  }

  String? getIncome() {
    final response = responses.firstWhere((r) => r.questionId == 'monthly_income', orElse: () => OnboardingResponseModel(questionId: '', answer: null, answeredAt: DateTime.now()));
    return response.answer?.toString();
  }

  String? getMotivation() {
    final response = responses.firstWhere((r) => r.questionId == 'main_motivation', orElse: () => OnboardingResponseModel(questionId: '', answer: null, answeredAt: DateTime.now()));
    return response.answer?.toString();
  }

  double? getFixedExpenses() {
    final response = responses.firstWhere((r) => r.questionId == 'fixed_expenses', orElse: () => OnboardingResponseModel(questionId: '', answer: null, answeredAt: DateTime.now()));
    if (response.answer is double) return response.answer as double;
    if (response.answer is String) return double.tryParse(response.answer as String);
    if (response.answer is num) return (response.answer as num).toDouble();
    return null;
  }

  List<String>? getMainCategories() {
    final response = responses.firstWhere((r) => r.questionId == 'main_categories', orElse: () => OnboardingResponseModel(questionId: '', answer: null, answeredAt: DateTime.now()));
    if (response.answer is List) return (response.answer as List).cast<String>();
    return null;
  }

  List<String> getSpendingCategories() {
    final response = responses.firstWhere((r) => r.questionId == 'spending_categories', orElse: () => OnboardingResponseModel(questionId: '', answer: null, answeredAt: DateTime.now()));
    if (response.answer is List) {
      return (response.answer as List).cast<String>();
    }
    return [];
  }

  String? getSpendingFrequency() {
    final response = responses.firstWhere((r) => r.questionId == 'spending_frequency', orElse: () => OnboardingResponseModel(questionId: '', answer: null, answeredAt: DateTime.now()));
    return response.answer?.toString();
  }

  String? getFinancialKnowledge() {
    final response = responses.firstWhere((r) => r.questionId == 'financial_knowledge', orElse: () => OnboardingResponseModel(questionId: '', answer: null, answeredAt: DateTime.now()));
    return response.answer?.toString();
  }

  double? getSavingsGoal() {
    final response = responses.firstWhere((r) => r.questionId == 'savings_goal', orElse: () => OnboardingResponseModel(questionId: '', answer: null, answeredAt: DateTime.now()));
    return response.answer is num ? (response.answer as num).toDouble() : null;
  }

  String? getBiggestChallenge() {
    final response = responses.firstWhere((r) => r.questionId == 'biggest_challenge', orElse: () => OnboardingResponseModel(questionId: '', answer: null, answeredAt: DateTime.now()));
    return response.answer?.toString();
  }

  String? getMainMotivation() {
    final response = responses.firstWhere((r) => r.questionId == 'main_motivation', orElse: () => OnboardingResponseModel(questionId: '', answer: null, answeredAt: DateTime.now()));
    return response.answer?.toString();
  }
}
