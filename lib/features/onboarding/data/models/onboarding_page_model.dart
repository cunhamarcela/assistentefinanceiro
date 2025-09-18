class OnboardingPageModel {
  final String title;
  final String subtitle;
  final String description;
  final String imagePath;
  final String? buttonText;
  final bool isLastPage;

  const OnboardingPageModel({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imagePath,
    this.buttonText,
    this.isLastPage = false,
  });

  static List<OnboardingPageModel> get pages => [
    const OnboardingPageModel(
      title: 'Assistente Financeiro',
      subtitle: 'Sua jornada financeira começa aqui',
      description: 'Gerencie seus gastos de forma inteligente com o poder da IA. Tenha controle total sobre suas finanças pessoais.',
      imagePath: 'assets/images/onboarding_1.png',
    ),
    const OnboardingPageModel(
      title: 'Controle Inteligente',
      subtitle: 'Categorização automática',
      description: 'Registre seus gastos rapidamente e nossa IA categoriza automaticamente, facilitando o controle das suas despesas.',
      imagePath: 'assets/images/onboarding_2.png',
    ),
    const OnboardingPageModel(
      title: 'Gerenciamento Completo',
      subtitle: 'Organize suas categorias',
      description: 'Gerencie suas categorias de gastos, visualize todas suas despesas em uma lista organizada e use filtros para encontrar rapidamente o que procura.',
      imagePath: 'assets/images/onboarding_3.png',
    ),
    const OnboardingPageModel(
      title: 'Relatórios Detalhados',
      subtitle: 'Visualize seus gastos',
      description: 'Acompanhe seus gastos com gráficos interativos, relatórios mensais e análises detalhadas dos seus padrões de consumo.',
      imagePath: 'assets/images/onboarding_4.png',
      buttonText: 'Começar',
      isLastPage: true,
    ),
  ];
}
