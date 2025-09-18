# 💰 Assistente Financeiro IA

Um aplicativo Flutter moderno e inteligente para gerenciamento financeiro pessoal, com integração de IA para categorização automática de gastos e análises preditivas.

## 🚀 Características Principais

- **🤖 IA Integrada**: Categorização automática de gastos e análises inteligentes
- **📱 Design Moderno**: Interface intuitiva com Material Design e design system customizado
- **🔄 Sincronização**: Armazenamento híbrido (Firebase + SQLite) para funcionamento offline-first
- **🔐 Autenticação Segura**: Login com email, Google e Apple Sign-In
- **📊 Relatórios Avançados**: Visualizações interativas e análises detalhadas
- **🎯 Categorização Inteligente**: Sistema automático de categorização de gastos
- **👤 Perfil Completo**: Gerenciamento completo de perfil e configurações

## 🛠️ Tecnologias

### Frontend
- **Flutter 3.16+** / **Dart 3.2+**
- **GetX** - Gerenciamento de estado e navegação
- **Material Design** + Design System customizado
- **FL Chart** - Gráficos e visualizações
- **ScreenUtil** - Responsividade

### Backend & Armazenamento
- **Firebase Auth** - Autenticação
- **Cloud Firestore** - Banco de dados em nuvem
- **SQLite** - Armazenamento local
- **SharedPreferences** - Configurações
- **FlutterSecureStorage** - Dados sensíveis

### Integrações
- **Google Sign-In**
- **Apple Sign-In**
- **Firebase Analytics**
- **Image Picker** - Seleção de fotos

## 🏗️ Arquitetura

O projeto segue **Clean Architecture** com **GetX Pattern**:

```
lib/
├── core/                    # Configurações centrais
│   ├── constants/          # Constantes da aplicação
│   ├── routes/             # Roteamento (GetX)
│   ├── storage/            # Serviços de armazenamento
│   ├── theme/              # Design System
│   └── utils/              # Utilitários
├── features/               # Funcionalidades por domínio
│   ├── auth/               # Autenticação
│   ├── expenses/           # Gestão de gastos
│   ├── profile/            # Perfil do usuário
│   ├── onboarding/         # Introdução ao app
│   └── chat/               # Chat IA (roadmap)
├── shared/                 # Componentes compartilhados
│   └── widgets/            # Widgets reutilizáveis
└── firebase_options.dart   # Configuração Firebase
```

### Padrões Implementados
- **Repository Pattern** - Abstração de fontes de dados
- **Clean Architecture** - Separação em camadas (data, domain, presentation)
- **Hybrid Storage** - Firebase + SQLite para offline-first
- **Design System** - Componentes padronizados e reutilizáveis

## 🎨 Design System

### Paleta de Cores
- **Primary**: Roxo (#6A4DFF)
- **Secondary**: Amarelo (#FFD700)
- **Gradientes**: Transições suaves entre cores principais

### Componentes
- **AppButton** - Botões com variações (primary, secondary, outline)
- **AppTextField** - Campos especializados (email, senha, moeda)
- **AppCard** - Cards padronizados (HomeCard, ExpenseCard, SummaryCard)
- **CategoryCard** - Exibição de categorias
- **ExpenseCard** - Exibição de gastos

## 📱 Funcionalidades

### ✅ Implementadas
- [x] Sistema de autenticação completo (email, Google, Apple)
- [x] Gerenciamento de gastos com categorização
- [x] Perfil completo com configurações
- [x] Onboarding interativo (4 telas)
- [x] Design system completo
- [x] Armazenamento híbrido (online/offline)
- [x] Categorias padrão pré-configuradas
- [x] Dashboard com resumo financeiro
- [x] Filtros e busca de gastos

### 🚧 Em Desenvolvimento
- [ ] Chat com IA financeira
- [ ] Relatórios avançados
- [ ] Sincronização bancária
- [ ] Notificações push

### 📋 Roadmap
- [ ] Metas financeiras
- [ ] Análise preditiva
- [ ] Compartilhamento de relatórios
- [ ] Modo família

## 🚀 Como Executar

### Pré-requisitos
- Flutter 3.16+ instalado
- Dart 3.2+
- Android Studio / VS Code
- Conta Firebase configurada

### Instalação

1. **Clone o repositório**
```bash
git clone https://github.com/seu-usuario/assistente-financeiro.git
cd assistente-financeiro
```

2. **Instale as dependências**
```bash
flutter pub get
```

3. **Configure o Firebase**
- Adicione `google-services.json` em `android/app/`
- Adicione `GoogleService-Info.plist` em `ios/Runner/`

4. **Execute o app**
```bash
flutter run
```

### Configuração do Firebase

1. Crie um projeto no [Firebase Console](https://console.firebase.google.com/)
2. Ative Authentication (Email, Google, Apple)
3. Configure Cloud Firestore
4. Baixe os arquivos de configuração
5. Siga as instruções de setup para Android e iOS

## 🧪 Testes

### Usuário de Teste
- **Email**: teste@assistentefinanceiro.com
- **Senha**: TesteApp2024!

### Executar Testes
```bash
# Testes unitários
flutter test

# Análise de código
flutter analyze

# Verificar dependências
flutter pub deps
```

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 👥 Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📞 Contato

Para dúvidas ou sugestões, entre em contato através dos issues do GitHub.

---

**Desenvolvido com ❤️ usando Flutter**